package com.finalai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.finalai/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val title = call.argument<String>("title") ?: "Plan hazırlanıyor..."
                    val body = call.argument<String>("body") ?: "AI ders planınız oluşturuluyor"
                    PlanForegroundService.start(this, title, body)
                    result.success(null)
                }
                "stop" -> {
                    PlanForegroundService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
