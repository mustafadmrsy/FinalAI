import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Wraps the native Android foreground service to keep the app alive
/// during long-running background operations (AI plan generation).
class ForegroundService {
  ForegroundService._();

  static const _channel = MethodChannel('com.finalai/foreground_service');

  /// Start the foreground service with a persistent notification.
  /// This prevents Android from killing the process or throttling network.
  static Future<void> start({
    String title = 'Plan hazırlanıyor...',
    String body = 'AI ders planınız oluşturuluyor',
  }) async {
    try {
      await _channel.invokeMethod('start', {'title': title, 'body': body});
      debugPrint('[ForegroundService] Started');
    } catch (e) {
      debugPrint('[ForegroundService] Start failed: $e');
    }
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
      debugPrint('[ForegroundService] Stopped');
    } catch (e) {
      debugPrint('[ForegroundService] Stop failed: $e');
    }
  }
}
