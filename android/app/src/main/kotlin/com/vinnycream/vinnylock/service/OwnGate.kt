package com.vinnycream.vinnylock.service

import android.content.Context
import android.os.SystemClock
import com.vinnycream.vinnylock.core.AppServices
import com.vinnycream.vinnylock.model.AuthMode
import com.vinnycream.vinnylock.model.RelockKind
import com.vinnycream.vinnylock.model.RelockRule
import com.vinnycream.vinnylock.security.ConfigStore

/**
 * Cổng vào chính giao diện Vinny Lock. Dùng chung cơ chế phiên mở khóa với các ứng dụng khác,
 * nhưng sự kiện rời đi do MainActivity tự báo (dịch vụ Trợ năng bỏ qua gói của chính nó).
 */
object OwnGate {
    /** Khoảng vắng mặt tối thiểu, để người dùng ghé cài đặt hệ thống rồi quay lại mà không phải nhập mã lại. */
    private const val MIN_GRACE_SECONDS = 30
    private const val LONG_ABSENCE_SECONDS = 300

    private fun rule(context: Context): RelockRule {
        val configured = ConfigStore.get(context).defaults.relock
        return when (configured.kind) {
            RelockKind.IMMEDIATE -> RelockRule(RelockKind.AFTER_SECONDS, MIN_GRACE_SECONDS)
            else -> configured
        }
    }

    /**
     * Chưa đặt mã chung (lần đầu mở app) thì cổng để mở, người dùng cần vào để thiết lập.
     * Nhưng nếu đã có ứng dụng được bật khóa mà mã chung bị mất thì cổng đóng lại và
     * màn hình khóa sẽ báo không có cách mở, tránh để ai cũng vào tắt khóa được.
     */
    fun isOpen(context: Context): Boolean {
        if (!AppServices.secrets(context).hasMain()) {
            return ConfigStore.get(context).apps.values.none { it.enabled }
        }
        return UnlockSessions.isUnlocked(context.packageName, SystemClock.elapsedRealtime())
    }

    fun markUnlocked(context: Context) {
        UnlockSessions.markUnlocked(context.packageName, rule(context))
    }

    /** Gọi trước khi rời sang màn hình hệ thống hoặc màn hình đặt mã, để quay lại không bị khóa oan. */
    fun allowLongAbsence(context: Context) {
        UnlockSessions.replaceRule(
            context.packageName,
            RelockRule(RelockKind.AFTER_SECONDS, LONG_ABSENCE_SECONDS),
        )
    }

    fun onLeft(context: Context) {
        UnlockSessions.onLeft(context.packageName, SystemClock.elapsedRealtime())
    }

    /**
     * Chính sách khi mở Vinny Lock. Luôn cho nhập mã chung dù cách mặc định là sinh trắc,
     * phòng khi vân tay hỏng hay cảm ứng khó dùng thì vẫn vào được để chỉnh lại.
     */
    fun gateMode(context: Context): AuthMode =
        when (ConfigStore.get(context).defaults.mode) {
            AuthMode.CODE_ONLY -> AuthMode.CODE_ONLY
            AuthMode.BOTH -> AuthMode.BOTH
            else -> AuthMode.EITHER
        }
}
