package com.vinnycream.vinnylock.ui

import android.content.Context
import android.content.res.Configuration
import android.content.res.ColorStateList
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.view.Gravity
import android.view.View
import android.widget.TextView
import com.vinnycream.vinnylock.R
import com.vinnycream.vinnylock.security.ConfigStore
import java.util.Locale

/** Tiện ích dựng giao diện bằng code. Không dùng XML layout để màn hình khóa nhẹ và hiện tức thì. */
object UiKit {
    fun dp(context: Context, value: Int): Int = (value * context.resources.displayMetrics.density).toInt()

    /** Áp dụng ngôn ngữ người dùng chọn trong Cài đặt cho màn hình khóa. "system" thì theo hệ thống. */
    fun wrapLocale(base: Context): Context {
        val language = ConfigStore.get(base).language
        if (language != "vi" && language != "en") return base
        val config = Configuration(base.resources.configuration)
        config.setLocale(Locale(language))
        return base.createConfigurationContext(config)
    }

    fun roundButton(context: Context, label: String, sizeDp: Int, textSp: Float, onClick: () -> Unit): TextView {
        val size = dp(context, sizeDp)
        val shape = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(context.getColor(R.color.lock_tone))
        }
        val ripple = RippleDrawable(ColorStateList.valueOf(context.getColor(R.color.lock_brand)), shape, null)
        return TextView(context).apply {
            text = label
            textSize = textSp
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(context.getColor(R.color.lock_on))
            background = ripple
            minimumWidth = size
            minimumHeight = size
            layoutParams = android.widget.GridLayout.LayoutParams().apply {
                width = size
                height = size
                val m = dp(context, 10)
                setMargins(m, m, m, m)
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { onClick() }
        }
    }

    fun pillButton(context: Context, label: String, filled: Boolean, onClick: () -> Unit): TextView {
        val radius = dp(context, 12).toFloat()
        val shape = GradientDrawable().apply {
            cornerRadius = radius
            if (filled) setColor(context.getColor(R.color.lock_brand)) else {
                setColor(0)
                setStroke(dp(context, 1), context.getColor(R.color.lock_muted))
            }
        }
        val ripple = RippleDrawable(ColorStateList.valueOf(context.getColor(R.color.lock_tone)), shape, null)
        return TextView(context).apply {
            text = label
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(context.getColor(if (filled) R.color.lock_on_brand else R.color.lock_on))
            background = ripple
            minHeight = dp(context, 48)
            minimumWidth = dp(context, 48)
            val h = dp(context, 20)
            setPadding(h, 0, h, 0)
            isClickable = true
            isFocusable = true
            setOnClickListener { onClick() }
        }
    }

    fun textButton(context: Context, label: String, onClick: () -> Unit): TextView =
        TextView(context).apply {
            text = label
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setTextColor(context.getColor(R.color.lock_brand))
            minHeight = dp(context, 48)
            minimumWidth = dp(context, 48)
            val h = dp(context, 16)
            setPadding(h, 0, h, 0)
            isClickable = true
            isFocusable = true
            setOnClickListener { onClick() }
        }

    fun formatSeconds(total: Int): String {
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) String.format(Locale.ROOT, "%d:%02d:%02d", h, m, s)
        else String.format(Locale.ROOT, "%02d:%02d", m, s)
    }

    fun setVisible(view: View, visible: Boolean) {
        view.visibility = if (visible) View.VISIBLE else View.GONE
    }
}
