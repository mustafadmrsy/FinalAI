import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_secrets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppSecrets.supabaseUrl.isEmpty || AppSecrets.supabaseAnonKey.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide via --dart-define.');
  }

  await Supabase.initialize(
    url: AppSecrets.supabaseUrl,
    anonKey: AppSecrets.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: FinalAIApp()));
}
