package com.cosmyra.neetjee

import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.cosmyra.neetjee/back_button"
    private var backMethodChannel: MethodChannel? = null
    private var lastBackPressTime: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Modern Android 13+ (API 33-36) Back Callback
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                handleBackButton()
            }
        })
    }

    override fun onBackPressed() {
        // Fallback for older Android versions
        handleBackButton()
    }

    private fun handleBackButton() {
        val channel = backMethodChannel
        if (channel == null) {
            handleDoubleBackToExit()
            return
        }

        channel.invokeMethod("onBackPressed", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                val handled = result as? Boolean ?: false
                android.util.Log.d("CosmyraBack", "Flutter handled back press: $handled")
                if (!handled) {
                    handleDoubleBackToExit()
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                android.util.Log.e("CosmyraBack", "Back error: $errorCode, $errorMessage")
                handleDoubleBackToExit()
            }

            override fun notImplemented() {
                android.util.Log.w("CosmyraBack", "Back not implemented in Flutter")
                handleDoubleBackToExit()
            }
        })
    }

    private fun handleDoubleBackToExit() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastBackPressTime > 2000L) {
            lastBackPressTime = currentTime
            Toast.makeText(this, "Press back again to exit", Toast.LENGTH_SHORT).show()
        } else {
            // Second press within 2 seconds: close activity gracefully
            finish()
        }
    }
}
