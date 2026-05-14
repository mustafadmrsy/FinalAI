import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_secrets.dart';
import 'core/services/haptic_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'core/services/ad_reward_service.dart';
import 'core/services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch unhandled async errors (e.g. stale OAuth deeplink replays)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // Supabase flow_state_not_found — stale deeplink, ignore silently
    if (error.toString().contains('flow_state_not_found')) {
      debugPrint('[Auth] Stale deeplink ignored: $error');
      return true;
    }
    return false;
  };

  if (AppSecrets.supabaseUrl.isEmpty || AppSecrets.supabaseAnonKey.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide via --dart-define.');
  }

  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  // Haptic ayarini yukle
  try {
    final prefs = await SharedPreferences.getInstance();
    Haptic.init(prefs.getBool('haptic_enabled') ?? true);
  } catch (_) {}

  // Bildirim servisini baslat
  await NotificationService.init();

  // Reklam SDK'sini baslat
  await AdRewardService.initialize();

  // In-App Purchase baslat
  await PurchaseService.instance.initialize();

  runApp(const ProviderScope(child: FinalAIApp()));
}
