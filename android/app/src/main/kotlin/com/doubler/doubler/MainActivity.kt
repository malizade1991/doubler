package com.doubler.doubler

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * DOUBLER keeps everything on device (see PRIVACY.md), including the user's own
 * Gemini key. The Dart side (`PlatformKeyStore`) talks to this channel and
 * falls back to memory when it is missing, so a broken handler can never lock
 * a user out of the app.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORE_CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val prefs = getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
        val key = call.argument<String>("key")
        if (key == null) {
            result.error("badArgs", "missing 'key' argument", null)
            return
        }
        when (call.method) {
            "read" -> result.success(prefs.getString(key, null))
            "write" -> {
                val value = call.argument<String>("value")
                if (value == null) {
                    result.error("badArgs", "missing 'value' argument", null)
                } else {
                    prefs.edit().putString(key, value).apply()
                    result.success(true)
                }
            }
            "remove" -> {
                prefs.edit().remove(key).apply()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private const val STORE_CHANNEL = "com.doubler.doubler/store"
        private const val STORE_NAME = "doubler_store"
    }
}
