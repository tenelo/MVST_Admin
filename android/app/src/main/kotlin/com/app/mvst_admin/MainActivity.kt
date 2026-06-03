package com.app.mvst_admin

import android.graphics.Rect
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.app.mvst_admin/keyboard"
    private val KEYBOARD_CHANNEL = "com.app.mvst_admin/keyboard_height"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "adjustResize" -> {
                        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
                        result.success(null)
                    }
                    "adjustNothing" -> {
                        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var listener: View.OnLayoutChangeListener? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val rootView = window.decorView.rootView
                    listener = View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                        val rect = Rect()
                        v.getWindowVisibleDisplayFrame(rect)
                        val keyboardHeight = v.height - rect.bottom
                        events?.success(if (keyboardHeight > 100) keyboardHeight.toDouble() else 0.0)
                    }
                    rootView.addOnLayoutChangeListener(listener)
                }

                override fun onCancel(arguments: Any?) {
                    window.decorView.rootView.removeOnLayoutChangeListener(listener)
                    listener = null
                }
            })
    }
}