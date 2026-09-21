package com.doubler.doubler

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Captures YouTube (playback capture) or the microphone, plays 24 kHz dub
 * audio, and ducks the other app while the translation speaks.
 *
 * Playback capture is Android 10+. The consent dialog is an activity result;
 * [MainActivity] forwards it here. A 16×16 virtual display keeps the
 * projection alive after the user leaves for YouTube — without it, several
 * OEMs stop delivering audio the moment our activity pauses.
 */
class DoublerAudioBridge(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())
    private var method: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var pending: MethodChannel.Result? = null
    private var captureGeneration = 0
    private var pendingSource: String = SOURCE_PLAYBACK
    private var title: String = "DOUBLER"
    private var body: String = ""
    private var stopLabel: String = "Stop"

    private val running = AtomicBoolean(false)
    private var paused = AtomicBoolean(false)
    private var recorder: AudioRecord? = null
    private var captureThread: Thread? = null
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var track: AudioTrack? = null
    private var playbackThread: Thread? = null
    private val playbackRunning = AtomicBoolean(false)
    private val playbackQueue = ArrayBlockingQueue<ByteArray>(48)
    private var focusRequest: AudioFocusRequest? = null
    private var gain = 1f

    fun attach(messenger: BinaryMessenger) {
        instance = this
        method = MethodChannel(messenger, METHOD).also { it.setMethodCallHandler(this) }
        events = EventChannel(messenger, EVENTS).also { it.setStreamHandler(this) }
    }

    fun detach() {
        method?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        if (instance === this) {
            instance = null
        }
        stopAll(notify = false)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startCapture" -> startCapture(call, result)
            "pauseCapture" -> {
                paused.set(true)
                result.success(mapOf("ok" to true))
            }
            "resumeCapture" -> {
                paused.set(false)
                result.success(mapOf("ok" to true))
            }
            "stopSession" -> {
                stopAll(notify = false)
                result.success(mapOf("ok" to true))
            }
            "startOutput" -> {
                startPlayback()
                // AudioTrack is playing now, so mediaPlayback is legal. Without
                // that type Android pauses the dub the moment YouTube opens.
                // mediaProjection is included only when that consent is live —
                // adding it on a microphone fallback throws on Android 14.
                val outputType = if (projection != null) {
                    DubbingForegroundService.TYPE_OUTPUT_PLAYBACK
                } else {
                    DubbingForegroundService.TYPE_OUTPUT
                }
                refreshForeground(outputType)
                result.success(mapOf("ok" to true))
            }
            "writeOutput" -> {
                val pcm = call.argument<ByteArray>("pcm")
                if (pcm != null && pcm.isNotEmpty()) {
                    enqueuePlayback(pcm)
                }
                result.success(null)
            }
            "pauseOutput" -> {
                track?.pause()
                result.success(mapOf("ok" to true))
            }
            "stopOutput" -> {
                stopPlayback()
                result.success(mapOf("ok" to true))
            }
            "setGain" -> {
                gain = (call.argument<Double>("gain") ?: 1.0).toFloat().coerceIn(0f, 1f)
                setTrackVolume()
                result.success(mapOf("ok" to true))
            }
            "setDuck" -> {
                val duck = call.argument<Boolean>("duck") == true
                setDuck(duck)
                result.success(mapOf("ok" to true))
            }
            "openYouTube" -> result.success(openYouTube())
            "micPermission" -> result.success(
                mapOf("granted" to hasMicPermission()),
            )
            else -> result.notImplemented()
        }
    }

    private fun startCapture(call: MethodCall, result: MethodChannel.Result) {
        // A timed-out Dart call leaves the previous result outstanding. Completing
        // it (Flutter ignores a late reply) lets the next tap start cleanly.
        if (pending != null) {
            finishPending("captureFailed")
        }
        captureGeneration += 1
        pending = result
        pendingSource = call.argument<String>("source") ?: SOURCE_PLAYBACK
        title = call.argument<String>("title") ?: "DOUBLER"
        body = call.argument<String>("body") ?: ""
        stopLabel = call.argument<String>("stop") ?: "Stop"
        if (needsNotificationPermission()) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQ_NOTIF,
            )
            return
        }
        continueAfterNotification()
    }

    fun onNotificationPermission() {
        continueAfterNotification()
    }

    private fun continueAfterNotification() {
        if (pending == null) {
            return
        }
        val source = pendingSource
        if (source == SOURCE_MICROPHONE) {
            if (!hasMicPermission()) {
                requestMic()
                return
            }
            val generation = captureGeneration
            ensureForeground(DubbingForegroundService.TYPE_MIC) { started ->
                if (generation != captureGeneration) {
                    return@ensureForeground
                }
                finishPending(if (started) startMicrophone() else "captureFailed")
            }
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            finishPending("playbackUnsupported")
            return
        }
        // Playback capture still needs RECORD_AUDIO. Ask before the projection
        // dialog so a denial does not look like a Gemini hang.
        if (!hasMicPermission()) {
            requestMic()
            return
        }
        // Android 14+: consent FIRST, then the mediaProjection service, then
        // getMediaProjection. Starting that service type before consent throws
        // and the system kills the process — the button never leaves connecting.
        launchProjectionConsent()
    }

    private fun requestMic() {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQ_MIC,
        )
    }

    fun onMicPermission(granted: Boolean) {
        if (pending == null) {
            return
        }
        if (!granted) {
            finishPending(
                if (pendingSource == SOURCE_MICROPHONE) "micDenied" else "playbackDenied",
            )
            return
        }
        continueAfterNotification()
    }

    fun onProjectionResult(resultCode: Int, data: Intent?) {
        if (pending == null) {
            return
        }
        if (resultCode != android.app.Activity.RESULT_OK || data == null) {
            finishPending("playbackDenied")
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            finishPending("playbackUnsupported")
            return
        }
        val generation = captureGeneration
        val code = resultCode
        val consent = data
        // Post so this runs after the activity is resumed. Starting the
        // projection service from inside onActivityResult is rejected on some OEMs.
        main.post {
            if (generation != captureGeneration || pending == null) {
                return@post
            }
            ensureForeground(DubbingForegroundService.TYPE_PLAYBACK) { started ->
                if (generation != captureGeneration) {
                    return@ensureForeground
                }
                if (!started) {
                    finishPending("captureFailed")
                    return@ensureForeground
                }
                val error = startPlaybackCapture(code, consent)
                if (error != null) {
                    stopCaptureLoop()
                    releaseProjection()
                }
                finishPending(error)
            }
        }
    }

    private fun launchProjectionConsent() {
        val manager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        activity.launchProjection(manager.createScreenCaptureIntent())
    }

    private fun startPlaybackCapture(resultCode: Int, data: Intent): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return "playbackUnsupported"
        }
        return try {
            val manager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val projection = manager.getMediaProjection(resultCode, data)
            projection.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    main.post { stopCaptureLoop() }
                }
            }, main)
            this.projection = projection
            // A tiny virtual display keeps the projection alive after our activity
            // pauses. It is not required for audio; a failure here must not abort
            // the capture the user just consented to.
            try {
                virtualDisplay = projection.createVirtualDisplay(
                    "doubler-audio",
                    16,
                    16,
                    activity.resources.displayMetrics.densityDpi.coerceAtLeast(1),
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    null,
                    null,
                    main,
                )
            } catch (error: RuntimeException) {
                Log.w(TAG, "virtual display skipped", error)
                virtualDisplay = null
            }
            val built = buildPlaybackRecorder(projection) ?: return "captureFailed"
            startRecorder(built.first, built.second)
            null
        } catch (error: SecurityException) {
            Log.w(TAG, "playback capture denied by the OS", error)
            "playbackDenied"
        } catch (error: RuntimeException) {
            Log.w(TAG, "playback capture failed", error)
            "captureFailed"
        }
    }

    private fun buildPlaybackRecorder(projection: MediaProjection): Pair<AudioRecord, Int>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }
        for (rate in intArrayOf(16000, 48000, 44100)) {
            val min = AudioRecord.getMinBufferSize(
                rate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            if (min <= 0) {
                continue
            }
            val format = AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(rate)
                .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                .build()
            val config = AudioPlaybackCaptureConfiguration.Builder(projection)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .excludeUid(Process.myUid())
                .build()
            val record = AudioRecord.Builder()
                .setAudioFormat(format)
                .setBufferSizeInBytes(min * 2)
                .setAudioPlaybackCaptureConfig(config)
                .build()
            if (record.state == AudioRecord.STATE_INITIALIZED) {
                return record to rate
            }
            record.release()
        }
        return null
    }

    private fun startMicrophone(): String? {
        if (!hasMicPermission()) {
            return "micDenied"
        }
        val rate = 16000
        val min = AudioRecord.getMinBufferSize(
            rate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (min <= 0) {
            return "captureFailed"
        }
        val record = AudioRecord(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            rate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            min * 2,
        )
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            return "captureFailed"
        }
        startRecorder(record, rate)
        return null
    }

    private fun startRecorder(record: AudioRecord, rate: Int) {
        stopCaptureLoop()
        recorder = record
        running.set(true)
        paused.set(false)
        record.startRecording()
        captureThread = Thread({
            val buf = ShortArray(maxOf(record.bufferSizeInFrames, 1600))
            val resampler = PcmTo16k(rate)
            while (running.get()) {
                val n = record.read(buf, 0, buf.size)
                if (n <= 0 || paused.get()) {
                    continue
                }
                val frame = resampler.push(buf, n) ?: continue
                emitPcm(frame)
            }
        }, "doubler-capture")
        captureThread?.start()
    }

    private fun startPlayback() {
        if (track != null) {
            track?.play()
            return
        }
        val rate = 24000
        val min = AudioTrack.getMinBufferSize(
            rate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val size = maxOf(min, rate * 2 / 5)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(rate)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
        val created = AudioTrack.Builder()
            .setAudioAttributes(attributes)
            .setAudioFormat(format)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(size)
            .build()
        created.play()
        track = created
        setTrackVolume()
        playbackRunning.set(true)
        playbackThread = Thread({
            while (playbackRunning.get()) {
                val chunk = try {
                    playbackQueue.poll(200, java.util.concurrent.TimeUnit.MILLISECONDS)
                } catch (_: InterruptedException) {
                    null
                } ?: continue
                val current = track ?: continue
                if (current.playState != AudioTrack.PLAYSTATE_PLAYING) {
                    try {
                        current.play()
                    } catch (_: IllegalStateException) {
                        continue
                    }
                }
                var offset = 0
                while (offset < chunk.size && playbackRunning.get()) {
                    val wrote = current.write(chunk, offset, chunk.size - offset)
                    if (wrote <= 0) {
                        break
                    }
                    offset += wrote
                }
            }
        }, "doubler-playback")
        playbackThread?.start()
    }

    private fun enqueuePlayback(pcm: ByteArray) {
        if (!playbackQueue.offer(pcm)) {
            playbackQueue.poll()
            playbackQueue.offer(pcm)
        }
    }

    private fun setTrackVolume() {
        track?.setVolume(gain)
    }

    private fun setDuck(duck: Boolean) {
        val manager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        if (duck) {
            val request = focusRequest ?: AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .build()
                .also { focusRequest = it }
            manager.requestAudioFocus(request)
        } else {
            focusRequest?.let { manager.abandonAudioFocusRequest(it) }
        }
    }

    private fun stopPlayback() {
        playbackRunning.set(false)
        playbackThread?.interrupt()
        playbackThread = null
        playbackQueue.clear()
        track?.let {
            try {
                it.pause()
                it.flush()
                it.release()
            } catch (_: IllegalStateException) {
            }
        }
        track = null
        setDuck(false)
    }

    private fun releaseProjection() {
        virtualDisplay?.release()
        virtualDisplay = null
        projection?.stop()
        projection = null
    }

    private fun stopCaptureLoop() {
        running.set(false)
        captureThread?.interrupt()
        captureThread = null
        recorder?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        recorder = null
    }

    private fun stopAll(notify: Boolean) {
        stopCaptureLoop()
        stopPlayback()
        releaseProjection()
        val intent = Intent(activity, DubbingForegroundService::class.java)
        activity.stopService(intent)
        if (notify) {
            emitControl("control:stop")
        }
        finishPending("captureFailed")
    }

    private fun ensureForeground(type: Int, then: (Boolean) -> Unit) {
        // Re-post even if a service is already up so a type upgrade lands
        // before getMediaProjection. EXTRA_NOTIFY is what lets onStartCommand
        // invoke [then] — a playback-type refresh must not consume it.
        DubbingForegroundService.whenForeground = then
        val intent = foregroundIntent(type).apply {
            putExtra(DubbingForegroundService.EXTRA_NOTIFY, true)
        }
        try {
            ContextCompat.startForegroundService(activity, intent)
        } catch (error: RuntimeException) {
            Log.w(TAG, "foreground service was not allowed to start", error)
            DubbingForegroundService.whenForeground = null
            then(false)
        }
    }

    private fun refreshForeground(type: Int) {
        try {
            ContextCompat.startForegroundService(activity, foregroundIntent(type))
        } catch (error: RuntimeException) {
            Log.w(TAG, "could not refresh foreground service type", error)
        }
    }

    private fun foregroundIntent(type: Int): Intent {
        return Intent(activity, DubbingForegroundService::class.java).apply {
            putExtra(DubbingForegroundService.EXTRA_TITLE, title)
            putExtra(DubbingForegroundService.EXTRA_BODY, body)
            putExtra(DubbingForegroundService.EXTRA_STOP, stopLabel)
            putExtra(DubbingForegroundService.EXTRA_TYPE, type)
        }
    }

    private fun finishPending(error: String?) {
        val result = pending ?: return
        pending = null
        if (error == null) {
            result.success(mapOf("ok" to true, "source" to pendingSource))
        } else {
            result.success(mapOf("error" to error))
        }
    }

    private fun emitPcm(bytes: ByteArray) {
        main.post { sink?.success(bytes) }
    }

    private fun emitControl(name: String) {
        main.post { sink?.success(name) }
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun needsNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
    }

    private fun openYouTube(): Boolean {
        val launch = activity.packageManager.getLaunchIntentForPackage("com.google.android.youtube")
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(launch)
            return true
        }
        val view = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://www.youtube.com/"))
        view.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            activity.startActivity(view)
            true
        } catch (_: android.content.ActivityNotFoundException) {
            false
        }
    }

    companion object {
        private const val TAG = "DoublerAudio"
        const val METHOD = "com.doubler.doubler/audio"
        const val EVENTS = "com.doubler.doubler/audio_pcm"
        const val SOURCE_PLAYBACK = "playback"
        const val SOURCE_MICROPHONE = "microphone"
        const val REQ_NOTIF = 4402
        const val REQ_MIC = 4403
        const val REQ_PROJECTION = 4404

        @Volatile
        var instance: DoublerAudioBridge? = null

        fun onNotificationStop() {
            instance?.let {
                it.stopAll(notify = true)
            }
        }
    }
}

/** Linear resample to 16 kHz mono PCM16, emitted in 100 ms frames. */
internal class PcmTo16k(inputRate: Int) {
    private val step = inputRate.toDouble() / 16000.0
    private var cursor = 0.0
    private var previous = 0
    private val pending = ArrayDeque<Short>()

    fun push(samples: ShortArray, length: Int): ByteArray? {
        val n = length.coerceIn(0, samples.size)
        if (n == 0) {
            return null
        }
        if (step == 1.0) {
            for (i in 0 until n) {
                pending.add(samples[i])
            }
        } else {
            while (cursor < n) {
                val index = cursor.toInt()
                val frac = (cursor - index).toFloat()
                val left = if (index == 0) previous else samples[index - 1].toInt()
                val right = samples[index.coerceAtMost(n - 1)].toInt()
                val mixed = left + ((right - left) * frac)
                pending.add(
                    mixed.toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort(),
                )
                cursor += step
            }
            cursor -= n
            previous = samples[n - 1].toInt()
        }
        if (pending.size < FRAME_SAMPLES) {
            return null
        }
        val out = ByteArray(FRAME_SAMPLES * 2)
        for (i in 0 until FRAME_SAMPLES) {
            val sample = pending.removeFirst().toInt()
            out[i * 2] = (sample and 0xFF).toByte()
            out[i * 2 + 1] = ((sample shr 8) and 0xFF).toByte()
        }
        return out
    }

    companion object {
        private const val FRAME_SAMPLES = 1600
    }
}
