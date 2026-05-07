import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avatar_model.dart';

// ═══════════════════════════════════════════════════════════════
//  AVATAR PROVIDER — Loads/saves avatar (local + remote)
//  Kullanici bazli local cache — hesap degisince avatar da degisir
// ═══════════════════════════════════════════════════════════════

const _localKeyPrefix = 'avatar_data_';

String _localKeyForUser(String? uid) => uid != null ? '$_localKeyPrefix$uid' : '${_localKeyPrefix}anon';

final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarModel>((ref) {
  return AvatarNotifier();
});

class AvatarNotifier extends StateNotifier<AvatarModel> {
  AvatarNotifier() : super(const AvatarModel()) {
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;

    // Kullanici bazli local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(_localKeyForUser(uid));
      if (local != null) {
        state = AvatarModel.fromJson(jsonDecode(local) as Map<String, dynamic>);
      } else {
        state = const AvatarModel();
      }
    } catch (_) {
      state = const AvatarModel();
    }

    // Remote'dan guncelle
    try {
      if (uid == null) return;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('avatar_data')
          .eq('id', uid)
          .maybeSingle();
      if (row != null && row['avatar_data'] != null) {
        final json = row['avatar_data'];
        final map = json is String ? jsonDecode(json) as Map<String, dynamic> : json as Map<String, dynamic>;
        state = AvatarModel.fromJson(map);
        _saveLocal(state, uid);
      }
    } catch (_) {}
  }

  /// Hesap degistiginde cagir — avatar'i yeni hesaba gore yenile
  Future<void> reload() async {
    state = const AvatarModel();
    await _load();
  }

  Future<void> save(AvatarModel avatar) async {
    state = avatar;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    await _saveLocal(avatar, uid);
    // Remote'a kaydet
    try {
      if (uid == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_data': avatar.toJson()})
          .eq('id', uid);
    } catch (_) {}
  }

  Future<void> _saveLocal(AvatarModel avatar, String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKeyForUser(uid), jsonEncode(avatar.toJson()));
    } catch (_) {}
  }
}
