package com.vinnycream.vinnylock.security

import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * Băm bí mật bằng PBKDF2-HMAC-SHA256 với muối ngẫu nhiên riêng cho từng mã.
 * Số vòng lặp vừa đủ chậm để cản dò mã hàng loạt nhưng vẫn mượt trên máy yếu.
 */
object Hasher {
    private const val ITERATIONS = 60_000
    private const val KEY_BITS = 256
    private const val SALT_BYTES = 16

    fun newSalt(): ByteArray = ByteArray(SALT_BYTES).also { SecureRandom().nextBytes(it) }

    fun hash(secret: String, salt: ByteArray): ByteArray {
        val chars = secret.toCharArray()
        val spec = PBEKeySpec(chars, salt, ITERATIONS, KEY_BITS)
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
            chars.fill('\u0000')
        }
    }

    /** So sánh thời gian không đổi để không lộ thông tin qua độ trễ. */
    fun matches(secret: String, salt: ByteArray, expected: ByteArray): Boolean =
        MessageDigest.isEqual(hash(secret, salt), expected)
}
