import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    Session? session,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      session: session ?? this.session,
    );
  }

  static const idle = AuthState(isLoading: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.idle) {
    _syncSession();
  }

  final _client = Supabase.instance.client;

  void _syncSession() {
    state = state.copyWith(session: _client.auth.currentSession);
    _client.auth.onAuthStateChange.listen((data) {
      state = state.copyWith(session: data.session);
    });
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
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
