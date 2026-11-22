package com.vinnycream.vinnylock.security

import android.content.Context
import com.vinnycream.vinnylock.model.ConfigJson
import com.vinnycream.vinnylock.model.LockConfig
import java.io.File

/**
 * Cấu hình không bí mật, lưu JSON thường để Flutter và dịch vụ Trợ năng cùng đọc.
 * Dịch vụ chạy cùng tiến trình với giao diện nên bộ nhớ đệm luôn khớp sau mỗi lần lưu,
 * không cần đọc lại file mỗi lần mở một ứng dụng khác.
 */
object ConfigStore {
    @Volatile private var cached: LockConfig? = null
    @Volatile private var cachedRaw: String? = null
    @Volatile private var loaded = false

    private fun file(context: Context) = File(context.filesDir, "config.json")

    fun readRaw(context: Context): String? {
        ensureLoaded(context)
        return cachedRaw
    }

    fun get(context: Context): LockConfig {
        ensureLoaded(context)
        return cached ?: LockConfig.INITIAL
    }

    @Synchronized
    fun save(context: Context, json: String) {
        FileIo.writeAtomic(file(context), json.toByteArray(Charsets.UTF_8))
        cachedRaw = json
        cached = ConfigJson.parse(json)
        loaded = true
    }

    @Synchronized
    private fun ensureLoaded(context: Context) {
        if (loaded) return
        val bytes = FileIo.readOrNull(file(context))
        cachedRaw = bytes?.toString(Charsets.UTF_8)
        cached = ConfigJson.parse(cachedRaw)
        loaded = true
    }
}
