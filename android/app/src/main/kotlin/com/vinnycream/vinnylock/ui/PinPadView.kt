package com.vinnycream.vinnylock.ui

import android.content.Context
import android.view.Gravity
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.vinnycream.vinnylock.R

/**
 * Bàn phím PIN. Số được xáo trộn mỗi lần dựng nếu người dùng bật tùy chọn.
 * Nhấn OK mới gửi đi, nên mã dài bao nhiêu cũng được trong khoảng cho phép.
 */
class PinPadView(
    context: Context,
    shuffle: Boolean,
    private val minLength: Int,
    private val maxLength: Int,
    private val onSubmit: (String) -> Unit,
) : LinearLayout(context) {

    private val dots = TextView(context)
    private val buffer = StringBuilder()
    private val keys = mutableListOf<TextView>()
    private var inputEnabled = true

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL

        dots.apply {
            textSize = 24f
            gravity = Gravity.CENTER
            setTextColor(context.getColor(R.color.lock_on))
            minHeight = UiKit.dp(context, 48)
            letterSpacing = 0.3f
            // Người dùng đọc màn hình bằng TalkBack không cần nghe từng chấm.
            importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        addView(dots)

        val digits = (0..9).map { it.toString() }.let { if (shuffle) it.shuffled() else it }
        val grid = GridLayout(context).apply {
            columnCount = 3
            rowCount = 4
        }
        for (i in 0 until 9) grid.addView(key(digits[i]) { append(digits[i]) })
        grid.addView(key(context.getString(R.string.lock_delete_short), 18f) { backspace() }.also {
            it.contentDescription = context.getString(R.string.lock_delete)
        })
        grid.addView(key(digits[9]) { append(digits[9]) })
        grid.addView(key(context.getString(R.string.lock_ok), 18f) { submit() })
        addView(grid)
        renderDots()
    }

    private fun key(label: String, textSp: Float = 24f, onClick: () -> Unit): TextView {
        val view = UiKit.roundButton(context, label, 72, textSp, onClick)
        keys += view
        return view
    }

    private fun append(digit: String) {
        if (!inputEnabled || buffer.length >= maxLength) return
        buffer.append(digit)
        renderDots()
    }

    private fun backspace() {
        if (!inputEnabled || buffer.isEmpty()) return
        buffer.deleteCharAt(buffer.length - 1)
        renderDots()
    }

    private fun submit() {
        if (!inputEnabled || buffer.length < minLength) return
        val value = buffer.toString()
        clear()
        onSubmit(value)
    }

    fun clear() {
        buffer.setLength(0)
        renderDots()
    }

    fun setInputEnabled(enabled: Boolean) {
        inputEnabled = enabled
        keys.forEach {
            it.isEnabled = enabled
            it.alpha = if (enabled) 1f else 0.4f
        }
        if (!enabled) clear()
    }

    private fun renderDots() {
        dots.text = if (buffer.isEmpty()) " " else "●".repeat(buffer.length)
    }
}
