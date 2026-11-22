package com.vinnycream.vinnylock.security

import java.io.File

/** Ghi file an toàn khi mất điện giữa chừng: ghi ra file tạm rồi đổi tên. */
object FileIo {
    fun writeAtomic(target: File, bytes: ByteArray) {
        val tmp = File(target.parentFile, target.name + ".tmp")
        tmp.writeBytes(bytes)
        if (!tmp.renameTo(target)) {
            target.delete()
            tmp.renameTo(target)
        }
    }

    fun readOrNull(file: File): ByteArray? = if (file.exists()) file.readBytes() else null
}
