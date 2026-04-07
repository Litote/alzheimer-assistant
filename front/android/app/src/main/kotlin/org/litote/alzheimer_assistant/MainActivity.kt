package org.litote.alzheimer_assistant

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val audioChannel = "alzheimer_assistant/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAudioModeCommunication" -> {
                        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                        result.success(null)
                    }
                    "resetAudioMode" -> {
                        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                        audioManager.mode = AudioManager.MODE_NORMAL
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
