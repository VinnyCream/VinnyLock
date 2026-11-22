package com.vinnycream.vinnylock.service

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import com.vinnycream.vinnylock.security.ConfigStore
import com.vinnycream.vinnylock.ui.LockActivity

/**
 * Phát hiện ứng dụng nào vừa lên trước màn hình bằng sự kiện (không đếm giờ liên tục),
 * nên gần như không tốn pin. Dịch vụ không đọc nội dung màn hình
 * (canRetrieveWindowContent=false trong accessibility_service_config.xml) và chỉ nhận
 * một loại sự kiện: đổi cửa sổ.
 */
class LockAccessibilityService : AccessibilityService() {

    private var imePackages: Set<String> = emptySet()
    private var imeRefreshedAt = 0L

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    UnlockSessions.onScreenOff(SystemClock.elapsedRealtime())
                    ForegroundTracker.forceRecheck = true
                }
                // Người dùng vừa mở khóa máy: kiểm tra lại ứng dụng đang ở trước.
                Intent.ACTION_USER_PRESENT -> ForegroundTracker.current?.let { check(it) }
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        runCatching { unregisterReceiver(screenReceiver) }
        return super.onUnbind(intent)
    }

    override fun onInterrupt() = Unit

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (isIgnored(pkg)) return

        val previous = ForegroundTracker.current
        if (pkg == previous && !ForegroundTracker.forceRecheck) return
        ForegroundTracker.forceRecheck = false

        val now = SystemClock.elapsedRealtime()
        if (previous != null && previous != pkg) UnlockSessions.onLeft(previous, now)
        ForegroundTracker.current = pkg
        check(pkg)
    }

    private fun check(pkg: String) {
        if (!ConfigStore.get(this).isLocked(pkg)) return
        if (UnlockSessions.isUnlocked(pkg, SystemClock.elapsedRealtime())) return
        startActivity(LockActivity.unlockIntent(this, pkg))
    }

    /** Các gói không tính là "rời khỏi ứng dụng": chính app này, giao diện hệ thống, bàn phím, hộp thoại quyền. */
    private fun isIgnored(pkg: String): Boolean {
        if (pkg == packageName) return true
        if (pkg == "com.android.systemui" || pkg == "android") return true
        if (pkg == "com.google.android.permissioncontroller" || pkg == "com.android.permissioncontroller") return true
        return pkg in inputMethodPackages()
    }

    private fun inputMethodPackages(): Set<String> {
        val now = SystemClock.elapsedRealtime()
        if (now - imeRefreshedAt > IME_CACHE_MS || imePackages.isEmpty()) {
            val manager = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imePackages = manager.enabledInputMethodList.map { it.packageName }.toSet()
            imeRefreshedAt = now
        }
        return imePackages
    }

    private companion object {
        const val IME_CACHE_MS = 60_000L
    }
}
