package com.vinnycream.vinnylock.core

import android.content.Context
import com.vinnycream.vinnylock.attempts.AttemptTracker
import com.vinnycream.vinnylock.security.SecretStore
import java.io.File

/**
 * Điểm truy cập chung tới các kho dữ liệu. Giao diện và dịch vụ Trợ năng chạy cùng tiến trình
 * nên dùng chung một thể hiện, bộ nhớ đệm luôn khớp nhau.
 */
object AppServices {
    @Volatile private var secretStore: SecretStore? = null
    @Volatile private var attemptTracker: AttemptTracker? = null

    fun secrets(context: Context): SecretStore =
        secretStore ?: synchronized(this) {
            secretStore ?: SecretStore(context.applicationContext).also { secretStore = it }
        }

    fun attempts(context: Context): AttemptTracker =
        attemptTracker ?: synchronized(this) {
            val app = context.applicationContext
            attemptTracker ?: AttemptTracker(File(app.noBackupFilesDir, "attempts.json"), AndroidClock(app))
                .also { attemptTracker = it }
        }
}
