package com.vinnycream.vinnylock

import com.vinnycream.vinnylock.core.TextFold
import org.junit.Assert.assertEquals
import org.junit.Test

/** Phải cho cùng kết quả với test/core/text_fold_test.dart bên Dart. */
class TextFoldTest {
    @Test
    fun foldsVietnameseAndCollapsesSpaces() {
        assertEquals("con meo cua toi", TextFold.normalizeAnswer("  Con   Mèo  Của Tôi "))
    }

    @Test
    fun dStrokeBecomesD() {
        assertEquals("dong ho", TextFold.normalizeAnswer("Đồng hồ"))
    }

    @Test
    fun dropsEverythingExceptLettersDigitsAndSpace() {
        assertEquals("ha noi", TextFold.normalizeAnswer("Hà Nội!"))
        assertEquals("abc123x", TextFold.normalizeAnswer("abc-123_x"))
    }

    @Test
    fun combiningMarksAreIgnored() {
        assertEquals("a", TextFold.normalizeAnswer("á"))
    }

    @Test
    fun blankStaysBlank() {
        assertEquals("", TextFold.normalizeAnswer("   "))
    }
}
