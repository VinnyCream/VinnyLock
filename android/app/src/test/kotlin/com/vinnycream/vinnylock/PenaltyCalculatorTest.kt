package com.vinnycream.vinnylock

import com.vinnycream.vinnylock.attempts.PenaltyCalculator
import com.vinnycream.vinnylock.model.PenaltyKind
import com.vinnycream.vinnylock.model.PenaltyPreset
import org.junit.Assert.assertEquals
import org.junit.Test

class PenaltyCalculatorTest {
    private fun wait(failures: Int, kind: PenaltyKind, fixed: Int = 30, preset: PenaltyPreset = PenaltyPreset.STANDARD) =
        PenaltyCalculator.waitSeconds(failures, 5, kind, fixed, preset)

    @Test
    fun noWaitBeforeThreshold() {
        for (n in 0..4) assertEquals(0, wait(n, PenaltyKind.ESCALATING))
    }

    @Test
    fun fixedWaitStartsAtThreshold() {
        assertEquals(45, wait(5, PenaltyKind.FIXED, fixed = 45))
        assertEquals(45, wait(9, PenaltyKind.FIXED, fixed = 45))
    }

    @Test
    fun escalatingWalksThePresetThenRepeatsTheLastStep() {
        val expected = intArrayOf(30, 60, 300, 900, 3600, 3600, 3600)
        for ((i, seconds) in expected.withIndex()) {
            assertEquals(seconds, wait(5 + i, PenaltyKind.ESCALATING))
        }
    }

    @Test
    fun triesLeftNeverGoesNegative() {
        assertEquals(3, PenaltyCalculator.triesLeft(2, 5))
        assertEquals(0, PenaltyCalculator.triesLeft(7, 5))
    }
}
