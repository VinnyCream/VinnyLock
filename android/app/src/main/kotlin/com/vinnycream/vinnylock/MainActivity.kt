package com.vinnycream.vinnylock

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.vinnycream.vinnylock.bridge.ChannelHandler
import com.vinnycream.vinnylock.service.OwnGate
import com.vinnycream.vinnylock.ui.LockActivity

/**
 * Chứa giao diện Flutter. Chỉ chạy khi người dùng đã qua màn hình khóa của chính app.
 * Mọi bí mật nằm ở phía Kotlin, Flutter chỉ nhận kết quả đúng hoặc sai qua MethodChannel.
 */
class MainActivity : FlutterActivity() {
    private var handler: ChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channelHandler = ChannelHandler(this)
        handler = channelHandler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ChannelHandler.CHANNEL)
            .setMethodCallHandler(channelHandler)
    }

    override fun onStart() {
        super.onStart()
        // Quay lại sau khi hết thời gian khóa lại: đòi mã trước khi cho xem giao diện.
        if (!OwnGate.isOpen(this)) {
            startActivity(LockActivity.unlockIntent(this, packageName))
            finishAndRemoveTask()
        }
    }

    override fun onStop() {
        super.onStop()
        if (!isChangingConfigurations) OwnGate.onLeft(this)
    }

    @Deprecated("Dùng cho kết quả của màn hình đặt mã")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        handler?.onActivityResult(requestCode, resultCode)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        handler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
