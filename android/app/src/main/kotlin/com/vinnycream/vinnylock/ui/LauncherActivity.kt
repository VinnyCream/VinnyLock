package com.vinnycream.vinnylock.ui

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.vinnycream.vinnylock.MainActivity
import com.vinnycream.vinnylock.service.OwnGate

/**
 * Cửa vào duy nhất của app (các activity-alias icon đều trỏ về đây) và cũng là trang
 * "cài đặt" gắn với dịch vụ Trợ năng (nút bánh răng trong Cài đặt › Trợ năng).
 * Không dựng Flutter: chỉ quyết định đi thẳng vào giao diện hay phải qua màn hình khóa trước,
 * nên người chưa nhập mã không bao giờ làm bật Flutter engine.
 */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val next = if (OwnGate.isOpen(this)) {
            Intent(this, MainActivity::class.java)
        } else {
            LockActivity.unlockIntent(this, packageName)
        }
        startActivity(next)
        finish()
        overridePendingTransition(0, 0)
    }
}
