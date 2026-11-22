package com.vinnycream.vinnylock.bridge

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.biometric.BiometricManager
import com.vinnycream.vinnylock.core.AppServices
import com.vinnycream.vinnylock.model.CodeKind
import com.vinnycream.vinnylock.model.DisguiseIcon
import com.vinnycream.vinnylock.model.IconMode
import com.vinnycream.vinnylock.security.ConfigStore
import com.vinnycream.vinnylock.service.LockAccessibilityService
import com.vinnycream.vinnylock.service.OwnGate
import com.vinnycream.vinnylock.ui.LockActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Cầu nối duy nhất giữa Flutter và Android. Tên lệnh khớp lib/data/native/native_call.dart.
 * Việc nặng (đọc danh sách ứng dụng, vẽ icon) chạy trên luồng nền, kết quả trả về luồng chính.
 */
class ChannelHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingCode: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadConfig" -> result.success(ConfigStore.readRaw(activity))
            "saveConfig" -> {
                val json = call.argument<String>("json")
                if (json == null) {
                    result.error("bad_args", "json is required", null)
                } else {
                    ConfigStore.save(activity, json)
                    result.success(null)
                }
            }
            "loadState" -> result.success(state())
            "listApps" -> background(result) { listApps() }
            "loadIcon" -> {
                val pkg = call.argument<String>("package")
                val size = call.argument<Int>("size") ?: 96
                if (pkg == null) result.success(null) else background(result) { iconPng(pkg, size) }
            }
            "setMainCode" -> startSetCode(result, null, CodeKind.parse(call.argument<String>("kind")))
            "setAppCode" -> startSetCode(result, call.argument<String>("package"), CodeKind.parse(call.argument<String>("kind")))
            "clearAppCode" -> {
                call.argument<String>("package")?.let { AppServices.secrets(activity).clearApp(it) }
                result.success(null)
            }
            "setRecovery" -> {
                val question = call.argument<String>("question") ?: ""
                val answer = call.argument<String>("answer") ?: ""
                result.success(AppServices.secrets(activity).setRecovery(question, answer))
            }
            "applyIconMode" -> {
                val mode = IconMode.entries.firstOrNull { it.wire == call.argument<String>("mode") } ?: IconMode.NORMAL
                val disguise = DisguiseIcon.entries.firstOrNull { it.wire == call.argument<String>("disguise") } ?: DisguiseIcon.CALCULATOR
                IconManager.apply(activity, mode, disguise)
                result.success(null)
            }
            "openAccessibilitySettings" -> {
                // Rời sang màn hình hệ thống có thể mất lâu hơn thời gian khóa lại thông thường.
                OwnGate.allowLongAbsence(activity)
                activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(null)
            }
            "openAppInfo" -> {
                OwnGate.allowLongAbsence(activity)
                activity.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + activity.packageName)),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Kết quả của LockActivity ở chế độ đặt mã. */
    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode != REQUEST_SET_CODE) return
        pendingCode?.success(resultCode == Activity.RESULT_OK)
        pendingCode = null
    }

    private fun startSetCode(result: MethodChannel.Result, pkg: String?, kind: CodeKind) {
        if (pendingCode != null) {
            result.success(false)
            return
        }
        pendingCode = result
        // Đặt mã gồm hai lần nhập nên có thể lâu hơn thời gian khóa lại thông thường.
        OwnGate.allowLongAbsence(activity)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(LockActivity.setCodeIntent(activity, pkg, kind), REQUEST_SET_CODE)
    }

    private fun state(): Map<String, Any?> {
        val secrets = AppServices.secrets(activity)
        val config = ConfigStore.get(activity)
        val authenticators = if (config.allowWeakBiometric) {
            BiometricManager.Authenticators.BIOMETRIC_WEAK
        } else {
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        }
        return mapOf(
            "hasMainCode" to secrets.hasMain(),
            "mainCodeKind" to secrets.mainKind()?.wire,
            "hasRecovery" to secrets.hasRecovery(),
            "recoveryQuestion" to secrets.recoveryQuestion(),
            "accessibilityEnabled" to isAccessibilityEnabled(),
            "biometricAvailable" to (BiometricManager.from(activity).canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS),
            "ownCodePackages" to secrets.ownCodePackages().toList(),
        )
    }

    private fun isAccessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getString(activity.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        val mine = ComponentName(activity, LockAccessibilityService::class.java)
        return enabled.split(':').any { ComponentName.unflattenFromString(it) == mine }
    }

    private fun listApps(): List<Map<String, String>> {
        val pm = activity.packageManager
        val query = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(query, 0)
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { it.first != activity.packageName }
            .distinctBy { it.first }
            .map { mapOf("package" to it.first, "label" to it.second) }
    }

    private fun iconPng(pkg: String, size: Int): ByteArray? {
        return try {
            val drawable = activity.packageManager.getApplicationIcon(pkg)
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            out.toByteArray()
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun <T> background(result: MethodChannel.Result, work: () -> T) {
        io.execute {
            val value = try {
                Result.success(work())
            } catch (e: Exception) {
                Result.failure(e)
            }
            main.post {
                value.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("native_error", it.message, null) },
                )
            }
        }
    }

    companion object {
        const val CHANNEL = "com.vinnycream.vinnylock/native"
        private const val REQUEST_SET_CODE = 4711
    }
}
