package com.vinnycream.vinnylock.core

import java.util.Locale

/**
 * Chuẩn hóa câu trả lời khôi phục. PHẢI giống hệt normalizeAnswer trong lib/core/text_fold.dart:
 * chữ thường, bỏ dấu tiếng Việt (đ thành d), chỉ giữ a-z, 0-9 và dấu cách, gộp khoảng trắng, cắt hai đầu.
 */
object TextFold {
    private val groups = mapOf(
        'a' to "àáạảãâầấậẩẫăằắặẳẵ",
        'e' to "èéẹẻẽêềếệểễ",
        'i' to "ìíịỉĩ",
        'o' to "òóọỏõôồốộổỗơờớợởỡ",
        'u' to "ùúụủũưừứựửữ",
        'y' to "ỳýỵỷỹ",
        'd' to "đ",
    )

    private val table: Map<Char, Char> = buildMap {
        for ((base, chars) in groups) for (ch in chars) put(ch, base)
    }

    fun normalizeAnswer(input: String): String {
        val sb = StringBuilder(input.length)
        for (raw in input.lowercase(Locale.ROOT)) {
            if (raw in '̀'..'ͯ') continue // dấu tổ hợp
            val ch = table[raw] ?: raw
            if (ch in 'a'..'z' || ch in '0'..'9' || ch == ' ') sb.append(ch)
        }
        return sb.toString().replace(Regex(" +"), " ").trim()
    }
}
