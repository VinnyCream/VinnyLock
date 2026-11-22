package com.vinnycream.vinnylock.core

import android.content.Context
import android.os.SystemClock
import android.provider.Settings

/**
 * Nguồn thời gian. Tách thành interface để kiểm thử logic phạt mà không cần Android.
 * elapsed() là đồng hồ đơn điệu, không đổi khi người dùng chỉnh giờ hệ thống.
 */
interface Clock {
    fun elapsed(): Long
    fun wall(): Long
    fun bootId(): Int
}

class AndroidClock(private val context: Context) : Clock {
    override fun elapsed(): Long = SystemClock.elapsedRealtime()
    override fun wall(): Long = System.currentTimeMillis()

    // Số lần khởi động của máy. Khác giá trị đã lưu nghĩa là máy đã khởi động lại,
    // khi đó elapsed() đã về 0 nên phải dùng giờ treo tường để tính phần phạt còn lại.
    override fun bootId(): Int =
        Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, -1)
}
