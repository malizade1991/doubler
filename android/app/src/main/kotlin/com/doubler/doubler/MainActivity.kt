package com.doubler.doubler

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * DOUBLER keeps everything on device (see PRIVACY.md), including the user's own
 * Gemini key. The Dart side (`PlatformKeyStore`) talks to the store channel and
 * falls back to memory when it is missing, so a broken handler can never lock
 * a user out of the app.
 *
 * Live dubbing uses a second channel (`DoublerAudioBridge`) so the session can
 * capture YouTube and keep playing after this activity is paused.
 */
class MainActivity : FlutterActivity() {
    private val audio = DoublerAudioBridge(this)

    fun launchProjection(intent: Intent) {
        @Suppress("DEPRECATION")
        startActivityForResult(intent, DoublerAudioBridge.REQ_PROJECTION)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORE_CHANNEL)
            .setMethodCallHandler { call, result -> handleStore(call, result) }
        audio.attach(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        audio.detach()
        super.onDestroy()
    }

    @Deprecated("Required so the media-projection consent reaches the bridge.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DoublerAudioBridge.REQ_PROJECTION) {
            audio.onProjectionResult(resultCode, data)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        when (requestCode) {
            DoublerAudioBridge.REQ_NOTIF -> audio.onNotificationPermission()
            DoublerAudioBridge.REQ_MIC -> audio.onMicPermission(granted)
        }
    }

    private fun handleStore(call: MethodCall, result: MethodChannel.Result) {
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
