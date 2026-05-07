import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════
//  NOTIFICATIONS SCREEN — 2D pixel game art bildirim ekrani
// ═══════════════════════════════════════════════════════════════

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final notifs = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () { Haptic.light(); Navigator.of(context).pop(); },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: px.text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
              // Tumunu okundu isaretle
              GestureDetector(
                onTap: () { Haptic.light(); ref.read(notificationsProvider.notifier).markAllRead(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: px.accentBg(PxDecor.teal), borderRadius: BorderRadius.circular(10), border: Border.all(color: PxDecor.teal, width: 1.5)),
                  child: const Text('Hepsini Oku', style: TextStyle(color: PxDecor.teal, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: notifs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e', style: TextStyle(color: px.text))),
              data: (list) {
                if (list.isEmpty) return _emptyState(px);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifCard(notif: list[i], px: px, onTap: () {
                    Haptic.selection();
                    ref.read(notificationsProvider.notifier).markRead(list[i].id);
                  }),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState(Px px) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: px.accentBg(PxDecor.teal), borderRadius: BorderRadius.circular(20), border: Border.all(color: PxDecor.teal, width: 2)),
        child: const Icon(Icons.notifications_none_rounded, color: PxDecor.teal, size: 36),
      ),
      const SizedBox(height: 14),
      Text('Henuz bildirim yok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: px.textSub)),
      const SizedBox(height: 4),
      Text('Ogrenme hatirlatmalari burada gorunecek', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textMuted)),
    ]));
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif, required this.px, required this.onTap});
  final AppNotification notif;
  final Px px;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(notif.type);
    final isUnread = !notif.read;
    final timeAgo = _timeAgo(notif.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? px.accentBg(meta.color) : px.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUnread ? meta.color : px.border, width: isUnread ? 2 : 1.5),
          boxShadow: [BoxShadow(
            color: isUnread ? meta.color.withAlpha(40) : px.shadow,
            offset: const Offset(0, 3), blurRadius: 0,
          )],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ikon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: meta.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: meta.dark.withAlpha(60), offset: const Offset(0, 2), blurRadius: 0)],
            ),
            child: Icon(meta.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(notif.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: px.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isUnread) Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
              ),
            ]),
            const SizedBox(height: 3),
            Text(notif.body, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textSub), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(timeAgo, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: px.textMuted)),
          ])),
        ]),
      ),
    );
  }

  static ({Color color, Color dark, IconData icon}) _typeMeta(NotificationType type) {
    switch (type) {
      case NotificationType.energyFull: return (color: PxDecor.green, dark: PxDecor.greenDark, icon: Icons.battery_full_rounded);
      case NotificationType.streakReminder: return (color: PxDecor.orange, dark: PxDecor.orangeDark, icon: Icons.local_fire_department_rounded);
      case NotificationType.streakFrozen: return (color: PxDecor.blue, dark: PxDecor.blueDark, icon: Icons.ac_unit_rounded);
      case NotificationType.streakBroken: return (color: PxDecor.red, dark: PxDecor.redDark, icon: Icons.heart_broken_rounded);
      case NotificationType.xpEarned: return (color: PxDecor.teal, dark: PxDecor.tealDark, icon: Icons.star_rounded);
      case NotificationType.dailyQuest: return (color: PxDecor.gold, dark: PxDecor.goldDark, icon: Icons.flag_rounded);
      case NotificationType.pdfUpload: return (color: PxDecor.blue, dark: PxDecor.blueDark, icon: Icons.upload_file_rounded);
      case NotificationType.pdfSummary: return (color: PxDecor.green, dark: PxDecor.greenDark, icon: Icons.auto_stories_rounded);
      case NotificationType.dailyTip: return (color: PxDecor.blue, dark: PxDecor.blueDark, icon: Icons.lightbulb_rounded);
      case NotificationType.achievement: return (color: PxDecor.gold, dark: PxDecor.goldDark, icon: Icons.emoji_events_rounded);
      case NotificationType.general: return (color: PxDecor.teal, dark: PxDecor.tealDark, icon: Icons.notifications_rounded);
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az once';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk once';
    if (diff.inHours < 24) return '${diff.inHours}sa once';
    if (diff.inDays < 7) return '${diff.inDays}g once';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
