package com.vinnycream.vinnylock.ui

/**
 * Cùng giao diện với LockActivity nhưng khai báo manifest khác (task mặc định, không singleTask),
 * vì startActivityForResult không trả kết quả về được khi activity chạy trong task riêng.
 */
class SetCodeActivity : LockActivity()
