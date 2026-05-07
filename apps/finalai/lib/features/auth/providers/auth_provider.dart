import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    this.errorMessage,
    this.session,
  });

  final bool isLoading;
  final String? errorMessage;
  final Session? session;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    Object? session = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      session: identical(session, _unset) ? this.session : session as Session?,
    );
  }

  static const idle = AuthState(isLoading: false);
}

const _unset = Object();

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.idle) {
    _syncSession();
  }

  final _client = Supabase.instance.client;

  void _syncSession() {
    state = state.copyWith(session: _client.auth.currentSession);
    SupabaseService.authStateChanges.listen((data) {
      state = state.copyWith(session: data.session);
    });
  }

  Future<void> completeOAuthRedirect(Uri redirectUri) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _client.auth.getSessionFromUrl(redirectUri);
      state = state.copyWith(isLoading: false, session: _client.auth.currentSession);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, session: res.session);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _localizeAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.session != null) {
        state = state.copyWith(isLoading: false, session: res.session);
      } else {
        // Email confirmation required
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Hesap oluşturuldu! E-posta adresine gelen onay linkine tıkla.',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _localizeAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _client.auth.resetPasswordForEmail(email);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Şifre sıfırlama linki e-posta adresine gönderildi.',
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _localizeAuthError(e));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  String _localizeAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-posta adresi henüz onaylanmadı. Gelen kutunu kontrol et.';
    }
    if (msg.contains('user already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı dene.';
    }
    if (msg.contains('password') && msg.contains('short')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Çok fazla deneme yaptın. Biraz bekle ve tekrar dene.';
    }
    return e.message;
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final redirectTo = kIsWeb
          ? null
          : (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS
              ? 'com.example.finalai://login-callback'
              : null);

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: const {
          'prompt': 'select_account',
        },
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _client.auth.signOut();
      state = state.copyWith(isLoading: false, session: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Hesabi ve tum kullanici verilerini kalici olarak sil
  Future<void> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Kullanici bulunamadi');
        return;
      }

      // Tum kullanici verilerini sil (tablodan)
      await _client.from('learning_lessons').delete().eq('user_id', userId);
      await _client.from('learning_units').delete().eq('user_id', userId);
      await _client.from('notes').delete().eq('user_id', userId);
      await _client.from('user_stats').delete().eq('user_id', userId);
      await _client.from('user_profiles').delete().eq('id', userId);

      // Supabase auth hesabini sil (RPC fonksiyonu ile)
      try {
        await _client.rpc('delete_user');
      } catch (_) {
        // RPC yoksa sadece sign out yap
      }

      await _client.auth.signOut();
      state = state.copyWith(isLoading: false, session: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
