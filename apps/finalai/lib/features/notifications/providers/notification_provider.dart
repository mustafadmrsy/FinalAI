import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

// ═══════════════════════════════════════════════════════════════
//  NOTIFICATION PROVIDER — Bildirim listesi ve okunmamis sayaci
// ═══════════════════════════════════════════════════════════════

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsNotifier();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notificationsProvider);
  return NotificationService.unreadCount();
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier() : super(const AsyncValue.loading()) { refresh(); }

  Future<void> refresh() async {
    try {
      final list = await NotificationService.getHistory();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    await NotificationService.markAsRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await NotificationService.markAllRead();
    await refresh();
  }

  Future<void> clear() async {
    await NotificationService.clearHistory();
    state = const AsyncValue.data([]);
  }
}
