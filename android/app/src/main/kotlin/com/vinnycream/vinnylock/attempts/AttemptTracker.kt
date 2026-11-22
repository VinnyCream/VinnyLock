package com.vinnycream.vinnylock.attempts

import com.vinnycream.vinnylock.core.Clock
import com.vinnycream.vinnylock.security.FileIo
import org.json.JSONObject
import java.io.File

/**
 * Đếm lần sai và thời gian phạt, lưu xuống file nên không thoát app hay khởi động lại máy
 * mà xóa được. Mỗi "khóa" (ví dụ code:<package>, code:*, recovery) có bộ đếm riêng,
 * nhờ đó câu hỏi khôi phục có giới hạn độc lập với nhập mã.
 *
 * Thời gian còn lại tính theo đồng hồ đơn điệu khi cùng lần khởi động. Sau khi máy khởi động lại
 * thì dùng giờ treo tường, vì đồng hồ đơn điệu đã về 0.
 */
class AttemptTracker(private val file: File, private val clock: Clock) {

    data class Status(val failures: Int, val remainingSeconds: Int) {
        val blocked: Boolean get() = remainingSeconds > 0
    }

    private val lock = Any()
    private var state: JSONObject? = null

    private fun root(): JSONObject = synchronized(lock) {
        state ?: load().also { state = it }
    }

    private fun load(): JSONObject {
        val bytes = FileIo.readOrNull(file) ?: return JSONObject()
        return try {
            JSONObject(String(bytes, Charsets.UTF_8))
        } catch (_: Exception) {
            JSONObject()
        }
    }

    private fun persist() {
        FileIo.writeAtomic(file, root().toString().toByteArray(Charsets.UTF_8))
    }

    fun status(key: String): Status = synchronized(lock) {
        val e = root().optJSONObject(key) ?: return Status(0, 0)
        Status(e.optInt("failures", 0), remainingSeconds(e))
    }

    /**
     * Ghi một lần sai. `waitFor(failures)` trả số giây phải chờ sau lần sai này.
     * Nếu đã quá `resetAfterMs` kể từ lần sai trước thì bộ đếm được tính lại từ 0.
     */
    fun recordFailure(key: String, resetAfterMs: Long, waitFor: (Int) -> Int): Status = synchronized(lock) {
        val r = root()
        val e = r.optJSONObject(key) ?: JSONObject()
        val now = clock.wall()
        var failures = e.optInt("failures", 0)
        val last = e.optLong("lastFailWall", 0L)
        if (failures > 0 && last > 0 && now - last > resetAfterMs && remainingSeconds(e) == 0) failures = 0
        failures += 1

        val wait = waitFor(failures)
        e.put("failures", failures)
        e.put("lastFailWall", now)
        if (wait > 0) {
            e.put("boot", clock.bootId())
            e.put("untilElapsed", clock.elapsed() + wait * 1000L)
            e.put("untilWall", now + wait * 1000L)
        }
        r.put(key, e)
        persist()
        Status(failures, remainingSeconds(e))
    }

    fun clear(key: String) = synchronized(lock) {
        val r = root()
        if (r.has(key)) {
            r.remove(key)
            persist()
        }
    }

    /** Xóa mọi bộ đếm nhập mã (khóa bắt đầu bằng "code:"). Bộ đếm khôi phục được giữ riêng. */
    fun clearAllCode() = synchronized(lock) {
        val r = root()
        val keys = r.keys().asSequence().filter { it.startsWith("code:") }.toList()
        keys.forEach { r.remove(it) }
        if (keys.isNotEmpty()) persist()
    }

    private fun remainingSeconds(e: JSONObject): Int {
        if (!e.has("untilElapsed")) return 0
        val remainingMs = if (e.optInt("boot", -1) == clock.bootId() && clock.bootId() != -1) {
            e.optLong("untilElapsed", 0L) - clock.elapsed()
        } else {
            e.optLong("untilWall", 0L) - clock.wall()
        }
        if (remainingMs <= 0) return 0
        return ((remainingMs + 999) / 1000).toInt()
    }
}
