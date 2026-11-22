package com.vinnycream.vinnylock.service

import com.vinnycream.vinnylock.model.RelockKind
import com.vinnycream.vinnylock.model.RelockRule

/**
 * Ghi nhớ ứng dụng nào đang được mở khóa và khi nào phải khóa lại.
 * Chỉ nằm trong bộ nhớ: tiến trình bị hệ thống dọn thì mọi thứ tự khóa lại, đó là hướng an toàn.
 * Mọi mốc thời gian là SystemClock.elapsedRealtime() (đơn điệu, không bị chỉnh giờ làm lệch).
 */
object UnlockSessions {
    private class Entry(var rule: RelockRule, var leftAt: Long?)

    private val map = HashMap<String, Entry>()

    @Synchronized
    fun markUnlocked(pkg: String, rule: RelockRule) {
        map[pkg] = Entry(rule, null)
    }

    /** Đổi luật của một phiên đang mở (dùng khi cần cho phép vắng mặt lâu hơn). */
    @Synchronized
    fun replaceRule(pkg: String, rule: RelockRule) {
        map[pkg]?.rule = rule
    }

    @Synchronized
    fun isUnlocked(pkg: String, now: Long): Boolean {
        val entry = map[pkg] ?: return false
        val left = entry.leftAt ?: return true // vẫn đang ở trong ứng dụng
        val valid = when (entry.rule.kind) {
            RelockKind.IMMEDIATE -> false
            RelockKind.SCREEN_OFF -> true
            RelockKind.AFTER_SECONDS -> now - left <= entry.rule.seconds * 1000L
        }
        if (!valid) map.remove(pkg)
        return valid
    }

    @Synchronized
    fun onLeft(pkg: String, now: Long) {
        val entry = map[pkg] ?: return
        if (entry.rule.kind == RelockKind.IMMEDIATE) map.remove(pkg) else entry.leftAt = now
    }

    /** Tắt màn hình: khóa lại ngay các luật "ngay" và "khi tắt màn hình", bắt đầu đếm giờ cho luật theo giây. */
    @Synchronized
    fun onScreenOff(now: Long) {
        val iterator = map.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next().value
            when (entry.rule.kind) {
                RelockKind.IMMEDIATE, RelockKind.SCREEN_OFF -> iterator.remove()
                RelockKind.AFTER_SECONDS -> if (entry.leftAt == null) entry.leftAt = now
            }
        }
    }

    @Synchronized
    fun clearAll() = map.clear()
}

/** Trạng thái chia sẻ giữa dịch vụ Trợ năng và màn hình khóa. */
object ForegroundTracker {
    /** Gói ứng dụng đang ở trước mà dịch vụ biết (đã bỏ qua các gói hệ thống). */
    @Volatile var current: String? = null

    /** Đặt true để lần sự kiện tới kiểm tra lại cả khi vẫn là cùng một gói. */
    @Volatile var forceRecheck: Boolean = false
}
