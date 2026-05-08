import 'app_secrets.dart';

class AppConstants {
  AppConstants._();

  static String get supabaseUrl => AppSecrets.supabaseUrl.isNotEmpty
      ? AppSecrets.supabaseUrl
      : const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String get supabaseAnonKey => AppSecrets.supabaseAnonKey.isNotEmpty
      ? AppSecrets.supabaseAnonKey
      : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get geminiApiKey => AppSecrets.geminiApiKey.isNotEmpty
      ? AppSecrets.geminiApiKey
      : const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.0-flash-lite');

  static const appName = 'FinalAI';
  static const freeUploadLimit = 3;
  static const premiumPrice = '₺69';
}
