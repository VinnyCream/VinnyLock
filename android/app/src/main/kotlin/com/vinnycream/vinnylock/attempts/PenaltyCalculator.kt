package com.vinnycream.vinnylock.attempts

import com.vinnycream.vinnylock.model.PenaltyKind
import com.vinnycream.vinnylock.model.PenaltyPreset

/**
 * Tính thời gian phải chờ. Hàm thuần, không phụ thuộc Android nên kiểm thử trực tiếp.
 *
 * `threshold` là số lần được sai miễn phạt. Lần sai thứ `threshold` là lần đầu bị phạt.
 * Kiểu tăng dần dùng các bước của mức đã chọn, bước cuối lặp lại.
 */
object PenaltyCalculator {
    fun waitSeconds(
        failures: Int,
        threshold: Int,
        kind: PenaltyKind,
        fixedSeconds: Int,
        preset: PenaltyPreset,
    ): Int {
        if (failures < threshold) return 0
        return when (kind) {
            PenaltyKind.FIXED -> fixedSeconds
            PenaltyKind.ESCALATING -> {
                val index = (failures - threshold).coerceAtMost(preset.steps.size - 1)
                preset.steps[index]
            }
        }
    }

    /** Số lần còn được sai trước khi bị phạt (không âm). */
    fun triesLeft(failures: Int, threshold: Int): Int = (threshold - failures).coerceAtLeast(0)
}
