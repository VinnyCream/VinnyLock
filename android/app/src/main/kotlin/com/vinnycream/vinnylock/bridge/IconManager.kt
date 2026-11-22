package com.vinnycream.vinnylock.bridge

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import com.vinnycream.vinnylock.model.DisguiseIcon
import com.vinnycream.vinnylock.model.IconMode

/**
 * Đổi hoặc ẩn icon bằng cách bật tắt các activity-alias trong manifest.
 * Không dùng quyền đặc biệt nào. Launcher có thể mất vài giây để làm mới.
 * Tên hiện trong Cài đặt › Ứng dụng của Android là tĩnh (android:label của <application>),
 * không đổi được bằng cách này.
 */
object IconManager {
    private const val NORMAL = "com.vinnycream.vinnylock.AliasNormal"
    private const val CALCULATOR = "com.vinnycream.vinnylock.AliasCalculator"
    private const val NOTES = "com.vinnycream.vinnylock.AliasNotes"
    private const val WEATHER = "com.vinnycream.vinnylock.AliasWeather"
    private val all = listOf(NORMAL, CALCULATOR, NOTES, WEATHER)

    fun apply(context: Context, mode: IconMode, disguise: DisguiseIcon) {
        val active: String? = when (mode) {
            IconMode.NORMAL -> NORMAL
            IconMode.HIDDEN -> null
            IconMode.DISGUISE -> when (disguise) {
                DisguiseIcon.CALCULATOR -> CALCULATOR
                DisguiseIcon.NOTES -> NOTES
                DisguiseIcon.WEATHER -> WEATHER
            }
        }
        // Bật cái mới trước rồi mới tắt các cái cũ, để không có lúc nào icon biến mất ngoài ý muốn.
        if (active != null) set(context, active, true)
        all.filter { it != active }.forEach { set(context, it, false) }
    }

    private fun set(context: Context, className: String, enabled: Boolean) {
        val state = if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        context.packageManager.setComponentEnabledSetting(
            ComponentName(context.packageName, className),
            state,
            PackageManager.DONT_KILL_APP,
        )
    }
}
