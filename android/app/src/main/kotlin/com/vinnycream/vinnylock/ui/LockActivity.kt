package com.vinnycream.vinnylock.ui

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.vinnycream.vinnylock.MainActivity
import com.vinnycream.vinnylock.R
import com.vinnycream.vinnylock.attempts.PenaltyCalculator
import com.vinnycream.vinnylock.core.AppServices
import com.vinnycream.vinnylock.model.AttemptScope
import com.vinnycream.vinnylock.model.AuthMode
import com.vinnycream.vinnylock.model.AuthOrder
import com.vinnycream.vinnylock.model.CodeKind
import com.vinnycream.vinnylock.model.EffectivePolicy
import com.vinnycream.vinnylock.model.LockConfig
import com.vinnycream.vinnylock.model.PenaltyKind
import com.vinnycream.vinnylock.security.ConfigStore
import com.vinnycream.vinnylock.service.ForegroundTracker
import com.vinnycream.vinnylock.service.OwnGate
import com.vinnycream.vinnylock.service.UnlockSessions

/**
 * Màn hình khóa. Dựng bằng code, không có Flutter engine nên hiện gần như tức thì.
 * Một Activity cho ba việc: mở khóa một ứng dụng, đặt mã chung, đặt mã riêng cho một ứng dụng.
 */
open class LockActivity : FragmentActivity() {

    private enum class Factor { CODE, BIO, EITHER }
    private enum class Purpose { UNLOCK, VERIFY_CURRENT, SET_NEW, SET_CONFIRM }

    private lateinit var config: LockConfig
    private val secrets by lazy { AppServices.secrets(this) }
    private val attempts by lazy { AppServices.attempts(this) }
    private val handler = Handler(Looper.getMainLooper())

    private var mode = MODE_UNLOCK
    private var target = ""
    private var gateOwn = false
    private var policy: EffectivePolicy? = null
    private val pending = ArrayDeque<Factor>()
    private var finishedNormally = false
    private var autoPrompted = false

    // Đặt mã
    private var setPackage: String? = null
    private var setKind = CodeKind.PIN
    private var firstEntry: String? = null

    // Giao diện
    private lateinit var titleView: TextView
    private lateinit var messageView: TextView
    private lateinit var body: FrameLayout
    private lateinit var footer: LinearLayout
    private var entryToggle: ((Boolean) -> Unit)? = null
    private var countdown: Runnable? = null
    private val tapTimes = ArrayDeque<Long>()

    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(UiKit.wrapLocale(newBase))
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Chặn chụp màn hình và xem trước ở danh sách ứng dụng gần đây: tránh lộ hình vẽ mở khóa.
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        config = ConfigStore.get(this)
        buildSkeleton()
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() = onBack()
        })
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        config = ConfigStore.get(this)
        handleIntent(intent)
    }

    override fun onStop() {
        super.onStop()
        if (isChangingConfigurations || finishedNormally || isFinishing) return
        // Rời màn hình khóa mà chưa mở được (bấm Home, mở danh sách gần đây, tắt màn hình):
        // đóng lại và đòi kiểm tra lần nữa khi ứng dụng bị khóa xuất hiện trở lại.
        if (mode == MODE_UNLOCK) ForegroundTracker.forceRecheck = true else setResult(RESULT_CANCELED)
        finish()
    }

    override fun onDestroy() {
        stopCountdown()
        super.onDestroy()
    }

    // ------------------------------------------------------------------ Bố cục

    private fun buildSkeleton() {
        val pad = UiKit.dp(this, 24)
        val icon = ImageView(this).apply {
            setImageResource(R.drawable.ic_lock_glyph)
            layoutParams = LinearLayout.LayoutParams(UiKit.dp(this@LockActivity, 48), UiKit.dp(this@LockActivity, 48))
            contentDescription = getString(R.string.lock_icon_desc)
            setOnClickListener { onLockIconTapped() }
        }
        titleView = TextView(this).apply {
            textSize = 22f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(getColor(R.color.lock_on))
            setPadding(0, UiKit.dp(this@LockActivity, 12), 0, 0)
        }
        messageView = TextView(this).apply {
            textSize = 14f
            gravity = Gravity.CENTER
            setTextColor(getColor(R.color.lock_muted))
            minLines = 2
            setPadding(0, UiKit.dp(this@LockActivity, 8), 0, UiKit.dp(this@LockActivity, 8))
            accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        }
        body = FrameLayout(this)
        footer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(pad, pad, pad, pad)
            addView(icon)
            addView(titleView)
            addView(messageView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(body, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(footer, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        setContentView(
            ScrollView(this).apply {
                isFillViewport = true
                setBackgroundColor(getColor(R.color.lock_bg))
                addView(
                    column,
                    FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER),
                )
            },
        )
    }

    private fun clearStage() {
        stopCountdown()
        body.removeAllViews()
        footer.removeAllViews()
        entryToggle = null
    }

    // ------------------------------------------------------------------ Vào luồng

    private fun handleIntent(intent: Intent) {
        mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_UNLOCK
        when (mode) {
            MODE_UNLOCK -> beginUnlock(intent.getStringExtra(EXTRA_PACKAGE) ?: packageName)
            MODE_SET_MAIN -> beginSet(null, CodeKind.parse(intent.getStringExtra(EXTRA_KIND)))
            MODE_SET_APP -> beginSet(intent.getStringExtra(EXTRA_PACKAGE), CodeKind.parse(intent.getStringExtra(EXTRA_KIND)))
            else -> finish()
        }
    }

    private fun onBack() {
        when {
            mode != MODE_UNLOCK -> {
                setResult(RESULT_CANCELED)
                finish()
            }
            gateOwn -> finish()
            else -> goHome()
        }
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        finish()
    }

    // ------------------------------------------------------------------ Mở khóa

    private fun beginUnlock(pkg: String) {
        target = pkg
        gateOwn = pkg == packageName
        autoPrompted = false
        val effective = if (gateOwn) {
            EffectivePolicy(OwnGate.gateMode(this), config.defaults.order, config.defaults.relock, true)
        } else {
            config.effectiveFor(pkg)
        }
        policy = effective

        titleView.text = when {
            gateOwn -> getString(R.string.app_name)
            config.lockScreen.showAppName -> labelOf(pkg)
            else -> getString(R.string.lock_title_default)
        }

        pending.clear()
        pending.addAll(plan(effective, hasCode(), biometricAvailable()))
        advance()
    }

    private fun labelOf(pkg: String): String =
        try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (_: Exception) {
            pkg
        }

    private fun hasCode(): Boolean = (!gateOwn && secrets.hasApp(target)) || secrets.hasMain()

    private fun codeKind(): CodeKind =
        if (!gateOwn && secrets.hasApp(target)) secrets.appKind(target) ?: CodeKind.PIN else secrets.mainKind() ?: CodeKind.PIN

    /** Các bước phải qua. Rỗng nghĩa là không còn yếu tố nào để kiểm tra (ví dụ chưa đặt mã) nên cho vào. */
    private fun plan(p: EffectivePolicy, hasCode: Boolean, bio: Boolean): List<Factor> = when (p.mode) {
        AuthMode.BIOMETRIC_ONLY -> when {
            bio -> listOf(Factor.BIO)
            hasCode -> listOf(Factor.CODE) // vân tay hỏng hoặc chưa cài: dùng mã thay vì khóa chết
            else -> emptyList()
        }
        AuthMode.CODE_ONLY -> if (hasCode) listOf(Factor.CODE) else emptyList()
        AuthMode.BOTH -> {
            val ordered = if (p.order == AuthOrder.CODE_FIRST) listOf(Factor.CODE, Factor.BIO) else listOf(Factor.BIO, Factor.CODE)
            ordered.filter { (it == Factor.CODE && hasCode) || (it == Factor.BIO && bio) }
        }
        AuthMode.EITHER -> when {
            hasCode && bio -> listOf(Factor.EITHER)
            hasCode -> listOf(Factor.CODE)
            bio -> listOf(Factor.BIO)
            else -> emptyList()
        }
    }

    private fun advance() {
        val next = pending.firstOrNull()
        if (next == null) {
            grant()
            return
        }
        when (next) {
            Factor.CODE -> showEntry(withBiometricButton = false)
            Factor.EITHER -> showEntry(withBiometricButton = true)
            Factor.BIO -> showBiometricStage()
        }
    }

    private fun factorDone() {
        pending.removeFirstOrNull()
        advance()
    }

    private fun grant() {
        finishedNormally = true
        val p = policy
        if (gateOwn) {
            OwnGate.markUnlocked(this)
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } else if (p != null) {
            UnlockSessions.markUnlocked(target, p.relock)
        }
        setResult(RESULT_OK)
        finish()
        overridePendingTransition(0, 0)
    }

    // ------------------------------------------------------------------ Nhập mã

    private fun showEntry(withBiometricButton: Boolean) {
        clearStage()
        val kind = codeKind()
        showEntryView(kind, Purpose.UNLOCK)
        messageView.text = hint(kind)

        if (withBiometricButton) footer.addView(UiKit.textButton(this, getString(R.string.lock_use_bio)) { promptBiometric() })
        if (policy?.allowRecovery == true) {
            footer.addView(UiKit.textButton(this, getString(R.string.lock_forgot)) { showRecovery() })
        }
        refreshPenalty(codeKey())
        if (withBiometricButton && !autoPrompted) {
            autoPrompted = true
            handler.post { promptBiometric() }
        }
    }

    private fun showEntryView(kind: CodeKind, purpose: Purpose) {
        body.removeAllViews()
        val options = config.lockScreen
        val view: View = if (kind == CodeKind.PIN) {
            PinPadView(this, options.shuffleKeypad, MIN_PIN, MAX_PIN) { onCodeSubmitted(it, purpose) }
                .also { pad -> entryToggle = pad::setInputEnabled }
        } else {
            PatternView(
                this, options.hidePattern, MIN_PATTERN,
                onTooShort = { messageView.text = getString(R.string.set_too_short_pattern) },
                onComplete = { onCodeSubmitted(it, purpose) },
            ).also { pattern -> entryToggle = pattern::setInputEnabled }
        }
        body.addView(view, FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER))
    }

    private fun hint(kind: CodeKind): String =
        getString(if (kind == CodeKind.PIN) R.string.lock_hint_pin else R.string.lock_hint_pattern)

    private fun codeKey(): String =
        if (config.attempts.scope == AttemptScope.ALL) "code:*" else "code:$target"

    private fun verifyCode(secret: String): Boolean =
        if (!gateOwn && secrets.hasApp(target)) secrets.verifyApp(target, secret) else secrets.verifyMain(secret)

    private fun onCodeSubmitted(secret: String, purpose: Purpose) {
        when (purpose) {
            Purpose.UNLOCK -> {
                if (attempts.status(codeKey()).blocked) return
                if (verifyCode(secret)) {
                    attempts.clear(codeKey())
                    factorDone()
                } else {
                    onWrongCode()
                }
            }
            Purpose.VERIFY_CURRENT -> {
                if (attempts.status("code:*").blocked) return
                if (secrets.verifyMain(secret)) {
                    attempts.clear("code:*")
                    showSetEntry(confirm = false)
                } else {
                    onWrongCode("code:*")
                }
            }
            Purpose.SET_NEW -> {
                firstEntry = secret
                showSetEntry(confirm = true)
            }
            Purpose.SET_CONFIRM -> {
                if (secret == firstEntry) storeNewCode(secret) else {
                    firstEntry = null
                    showSetEntry(confirm = false)
                    messageView.text = getString(R.string.set_mismatch)
                }
            }
        }
    }

    private fun onWrongCode(key: String = codeKey()) {
        buzz()
        val a = config.attempts
        val status = attempts.recordFailure(key, a.resetAfterHours * 3_600_000L) { failures ->
            PenaltyCalculator.waitSeconds(failures, a.threshold, a.penaltyKind, a.fixedSeconds, a.preset)
        }
        if (status.blocked) {
            startCountdown(key)
        } else {
            val left = PenaltyCalculator.triesLeft(status.failures, a.threshold)
            messageView.text = getString(R.string.lock_wrong_code) + "\n" + getString(R.string.lock_tries_left, left)
        }
    }

    private fun refreshPenalty(key: String) {
        if (attempts.status(key).blocked) startCountdown(key)
    }

    // ------------------------------------------------------------------ Đếm ngược phạt

    private fun startCountdown(key: String) {
        stopCountdown()
        entryToggle?.invoke(false)
        val tick = object : Runnable {
            override fun run() {
                val status = attempts.status(key)
                if (status.blocked) {
                    messageView.text = getString(R.string.lock_wait, UiKit.formatSeconds(status.remainingSeconds))
                    handler.postDelayed(this, 1000)
                } else {
                    countdown = null
                    entryToggle?.invoke(true)
                    messageView.text = ""
                }
            }
        }
        countdown = tick
        tick.run()
    }

    private fun stopCountdown() {
        countdown?.let { handler.removeCallbacks(it) }
        countdown = null
    }

    // ------------------------------------------------------------------ Khôi phục bằng câu hỏi

    private fun showRecovery() {
        clearStage()
        val question = secrets.recoveryQuestion()
        messageView.text = ""

        if (question == null) {
            messageView.text = getString(R.string.recovery_none)
        } else {
            val q = TextView(this).apply {
                text = question
                textSize = 16f
                gravity = Gravity.CENTER
                setTextColor(getColor(R.color.lock_on))
            }
            val answer = EditText(this).apply {
                hint = getString(R.string.recovery_answer_hint)
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS
                imeOptions = EditorInfo.IME_ACTION_DONE
                setSingleLine(true)
                setTextColor(getColor(R.color.lock_on))
                setHintTextColor(getColor(R.color.lock_muted))
                minimumHeight = UiKit.dp(this@LockActivity, 48)
            }
            val submit = UiKit.pillButton(this, getString(R.string.recovery_submit), filled = true) {
                onRecoverySubmitted(answer.text.toString())
                answer.setText("")
            }
            answer.setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    submit.performClick()
                    true
                } else false
            }
            val box = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                addView(q)
                addView(answer, LinearLayout.LayoutParams(UiKit.dp(this@LockActivity, 280), LinearLayout.LayoutParams.WRAP_CONTENT))
                addView(submit, LinearLayout.LayoutParams(UiKit.dp(this@LockActivity, 280), LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                    topMargin = UiKit.dp(this@LockActivity, 12)
                })
            }
            body.addView(box)
            entryToggle = { enabled ->
                answer.isEnabled = enabled
                submit.isEnabled = enabled
                box.alpha = if (enabled) 1f else 0.4f
            }
            refreshPenalty(RECOVERY_KEY)
        }

        footer.addView(UiKit.textButton(this, getString(R.string.lock_back)) { advance() })
    }

    private fun onRecoverySubmitted(answer: String) {
        if (attempts.status(RECOVERY_KEY).blocked) return
        if (secrets.verifyRecovery(answer)) {
            attempts.clear(RECOVERY_KEY)
            attempts.clearAllCode()
            grant()
            return
        }
        buzz()
        val r = config.recovery
        val status = attempts.recordFailure(RECOVERY_KEY, config.attempts.resetAfterHours * 3_600_000L) { failures ->
            PenaltyCalculator.waitSeconds(failures, r.threshold, PenaltyKind.ESCALATING, 0, r.preset)
        }
        if (status.blocked) {
            startCountdown(RECOVERY_KEY)
        } else {
            val left = PenaltyCalculator.triesLeft(status.failures, r.threshold)
            messageView.text = getString(R.string.recovery_wrong) + "\n" + getString(R.string.lock_tries_left, left)
        }
    }

    // ------------------------------------------------------------------ Sinh trắc

    private fun authenticators(): Int =
        if (config.allowWeakBiometric) BiometricManager.Authenticators.BIOMETRIC_WEAK
        else BiometricManager.Authenticators.BIOMETRIC_STRONG

    private fun biometricAvailable(): Boolean =
        BiometricManager.from(this).canAuthenticate(authenticators()) == BiometricManager.BIOMETRIC_SUCCESS

    private fun showBiometricStage() {
        clearStage()
        messageView.text = getString(R.string.bio_hint)
        footer.addView(UiKit.textButton(this, getString(R.string.lock_retry_bio)) { promptBiometric() })
        if (policy?.allowRecovery == true) {
            footer.addView(UiKit.textButton(this, getString(R.string.lock_forgot)) { showRecovery() })
        }
        if (!autoPrompted) {
            autoPrompted = true
            handler.post { promptBiometric() }
        }
    }

    private fun promptBiometric() {
        if (isFinishing || isDestroyed) return
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                val current = pending.firstOrNull()
                if (current == Factor.BIO || current == Factor.EITHER) {
                    attempts.clear(codeKey())
                    factorDone()
                }
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                if (errorCode == BiometricPrompt.ERROR_USER_CANCELED || errorCode == BiometricPrompt.ERROR_NEGATIVE_BUTTON) return
                messageView.text = errString
            }
        }
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(titleView.text.toString())
            .setNegativeButtonText(getString(R.string.bio_negative))
            .setAllowedAuthenticators(authenticators())
            .setConfirmationRequired(false)
            .build()
        BiometricPrompt(this, ContextCompat.getMainExecutor(this), callback).authenticate(info)
    }

    // ------------------------------------------------------------------ Đặt mã

    private fun beginSet(pkg: String?, kind: CodeKind) {
        setPackage = pkg
        setKind = kind
        firstEntry = null
        titleView.text = getString(R.string.app_name)
        if (pkg == null && secrets.hasMain()) showVerifyCurrent() else showSetEntry(confirm = false)
    }

    private fun showVerifyCurrent() {
        clearStage()
        showEntryView(secrets.mainKind() ?: CodeKind.PIN, Purpose.VERIFY_CURRENT)
        messageView.text = getString(R.string.set_verify_current)
        footer.addView(UiKit.textButton(this, getString(R.string.lock_cancel)) { onBack() })
        refreshPenalty("code:*")
    }

    private fun showSetEntry(confirm: Boolean) {
        clearStage()
        showEntryView(setKind, if (confirm) Purpose.SET_CONFIRM else Purpose.SET_NEW)
        val resource = when {
            setKind == CodeKind.PIN && !confirm -> R.string.set_new_pin
            setKind == CodeKind.PIN -> R.string.set_confirm_pin
            !confirm -> R.string.set_new_pattern
            else -> R.string.set_confirm_pattern
        }
        messageView.text = getString(resource)
        footer.addView(UiKit.textButton(this, getString(R.string.lock_cancel)) { onBack() })
    }

    private fun storeNewCode(secret: String) {
        val pkg = setPackage
        if (pkg == null) secrets.setMain(setKind, secret) else secrets.setApp(pkg, setKind, secret)
        // Người dùng vừa chứng minh là chủ máy, nên không bắt nhập lại khi quay về giao diện chính.
        OwnGate.markUnlocked(this)
        finishedNormally = true
        setResult(RESULT_OK)
        finish()
    }

    // ------------------------------------------------------------------ Cửa phụ và phản hồi

    /** Chạm 7 lần vào ổ khóa trong 5 giây để mở chính Vinny Lock (khi icon đã bị ẩn). Vẫn phải nhập mã. */
    private fun onLockIconTapped() {
        if (mode != MODE_UNLOCK || gateOwn) return
        val now = SystemClock.elapsedRealtime()
        tapTimes.addLast(now)
        while (tapTimes.isNotEmpty() && now - tapTimes.first() > SECRET_TAP_WINDOW_MS) tapTimes.removeFirst()
        if (tapTimes.size >= SECRET_TAP_COUNT) {
            tapTimes.clear()
            beginUnlock(packageName)
        }
    }

    private fun buzz() {
        if (!config.lockScreen.vibrate) return
        val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        vibrator.vibrate(VibrationEffect.createOneShot(60, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    companion object {
        const val EXTRA_MODE = "mode"
        const val EXTRA_PACKAGE = "package"
        const val EXTRA_KIND = "kind"
        const val MODE_UNLOCK = "unlock"
        const val MODE_SET_MAIN = "setMain"
        const val MODE_SET_APP = "setApp"

        private const val RECOVERY_KEY = "recovery"
        private const val MIN_PIN = 4
        private const val MAX_PIN = 12
        private const val MIN_PATTERN = 4
        private const val SECRET_TAP_COUNT = 7
        private const val SECRET_TAP_WINDOW_MS = 5_000L

        fun unlockIntent(context: Context, pkg: String): Intent =
            Intent(context, LockActivity::class.java)
                .putExtra(EXTRA_MODE, MODE_UNLOCK)
                .putExtra(EXTRA_PACKAGE, pkg)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)

        fun setCodeIntent(context: Context, pkg: String?, kind: CodeKind): Intent =
            Intent(context, SetCodeActivity::class.java)
                .putExtra(EXTRA_MODE, if (pkg == null) MODE_SET_MAIN else MODE_SET_APP)
                .putExtra(EXTRA_PACKAGE, pkg)
                .putExtra(EXTRA_KIND, kind.wire)
    }
}
