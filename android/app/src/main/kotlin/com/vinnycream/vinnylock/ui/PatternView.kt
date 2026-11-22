package com.vinnycream.vinnylock.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.MotionEvent
import android.view.View
import com.vinnycream.vinnylock.R
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.min

/**
 * Lưới 3x3 để vẽ hình mở khóa. Kết quả là chuỗi chỉ số nút theo thứ tự đi qua, ví dụ "01245".
 * Đi qua nút giữa chưa chọn thì nút đó được tự thêm vào, giống bàn phím hình của Android.
 */
class PatternView(
    context: Context,
    private val hideTrail: Boolean,
    private val minNodes: Int,
    private val onTooShort: () -> Unit,
    private val onComplete: (String) -> Unit,
) : View(context) {

    private val selected = mutableListOf<Int>()
    private var fingerX = 0f
    private var fingerY = 0f
    private var drawing = false
    private var inputEnabled = true

    private val idlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = context.getColor(R.color.lock_muted) }
    private val activePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = context.getColor(R.color.lock_brand) }
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = context.getColor(R.color.lock_brand)
        strokeWidth = UiKit.dp(context, 4).toFloat()
        strokeCap = Paint.Cap.ROUND
    }

    init {
        // Người dùng TalkBack có thể mở khóa bằng mã PIN thay thế, nên vùng vẽ không cần mô tả.
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    fun setInputEnabled(enabled: Boolean) {
        inputEnabled = enabled
        alpha = if (enabled) 1f else 0.4f
        if (!enabled) reset()
    }

    fun reset() {
        selected.clear()
        drawing = false
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val side = min(MeasureSpec.getSize(widthMeasureSpec), UiKit.dp(context, 300))
        setMeasuredDimension(side, side)
    }

    private fun cell(): Float = width / 3f

    private fun centerX(index: Int): Float = (index % 3 + 0.5f) * cell()
    private fun centerY(index: Int): Float = (index / 3 + 0.5f) * cell()

    private fun hit(x: Float, y: Float): Int {
        val radius = cell() * 0.35f
        for (i in 0 until 9) {
            if (hypot(x - centerX(i), y - centerY(i)) <= radius) return i
        }
        return -1
    }

    private fun add(index: Int) {
        if (index in selected) return
        val last = selected.lastOrNull()
        if (last != null) {
            val dx = index % 3 - last % 3
            val dy = index / 3 - last / 3
            // Đi thẳng qua một nút ở giữa chưa chọn thì thêm nút đó trước.
            if (abs(dx) % 2 == 0 && abs(dy) % 2 == 0 && (abs(dx) == 2 || abs(dy) == 2)) {
                val middle = (last % 3 + dx / 2) + (last / 3 + dy / 2) * 3
                if (middle !in selected) selected += middle
            }
        }
        selected += index
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!inputEnabled) return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                selected.clear()
                drawing = true
                parent?.requestDisallowInterceptTouchEvent(true)
                track(event)
            }
            MotionEvent.ACTION_MOVE -> track(event)
            MotionEvent.ACTION_UP -> {
                drawing = false
                val result = selected.joinToString("")
                val count = selected.size
                invalidate()
                if (count > 0) {
                    postDelayed({ reset() }, 300)
                    // Vẽ quá ngắn thì không gửi đi, tránh tính là một lần nhập sai.
                    if (count >= minNodes) onComplete(result) else onTooShort()
                }
            }
            MotionEvent.ACTION_CANCEL -> reset()
        }
        return true
    }

    private fun track(event: MotionEvent) {
        fingerX = event.x
        fingerY = event.y
        val node = hit(fingerX, fingerY)
        if (node >= 0) add(node)
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val dot = UiKit.dp(context, 6).toFloat()
        val big = UiKit.dp(context, 12).toFloat()
        if (!hideTrail && selected.size > 1) {
            for (i in 1 until selected.size) {
                canvas.drawLine(
                    centerX(selected[i - 1]), centerY(selected[i - 1]),
                    centerX(selected[i]), centerY(selected[i]), linePaint,
                )
            }
        }
        if (!hideTrail && drawing && selected.isNotEmpty()) {
            val last = selected.last()
            canvas.drawLine(centerX(last), centerY(last), fingerX, fingerY, linePaint)
        }
        for (i in 0 until 9) {
            val isSelected = !hideTrail && i in selected
            canvas.drawCircle(centerX(i), centerY(i), if (isSelected) big else dot, if (isSelected) activePaint else idlePaint)
        }
    }
}
