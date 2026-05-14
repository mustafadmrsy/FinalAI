import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/app_notification.dart';

// ═══════════════════════════════════════════════════════════════
//  NOTIFICATION SERVICE — 2D Pixel Game bildirim yonetimi
//  - Zamanlanmis seri hatirlatmalari (2h, 4h, 8h, 12h)
//  - Seri donmus / kirilmis bildirimleri
//  - XP, gunluk gorev, PDF yukle/ozet bildirimleri
//  - Enerji bildirimi SADECE gercekten dolunca
// ═══════════════════════════════════════════════════════════════

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _tzInitialized = false;
  static const _storageKey = 'app_notifications';

  // Scheduled notification ID bases
  static const _streakReminderIdBase = 5000;
  static const _energyFullId = 6000;
  static const _dailyQuestId = 7000;

  // ── Init ────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  // ── Izin iste ───────────────────────────────────
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (_) { return false; }
  }

  // ── Yerel push bildirim goster ──────────────────
  static Future<void> show({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    try {
      await init();
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const androidDetails = AndroidNotificationDetails(
        'finalai_channel', 'FinalAI Bildirimler',
        channelDescription: 'Ogrenme hatirlatmalari ve bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Notification show error: $e');
    }

    // Uygulama ici listeye de ekle
    await _addToHistory(AppNotification(
      id: _generateId(),
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      data: data,
    ));
  }

  // ═══════════════════════════════════════════════════
  //  STREAK NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  // ── Seri hatirlatmasi ───────────────────────────
  static Future<void> notifyStreakReminder({required int hoursLeft}) async {
    final urgency = hoursLeft <= 2 ? 'Acele et!' : 'Bugunku dersini yapmayi unutma!';
    await show(
      title: 'Serin kaybolmak uzere! 🔥',
      body: '$hoursLeft saat kaldi. $urgency',
      type: NotificationType.streakReminder,
      data: {'hoursLeft': hoursLeft},
    );
  }

  // ── Seri dondu bildirimi ────────────────────────
  static Future<void> notifyStreakFrozen({required int streakCount}) async {
    await show(
      title: 'Serin Donduruldu! ❄️',
      body: 'Freeze hakkin kullanildi. $streakCount gunluk serin korundu!',
      type: NotificationType.streakFrozen,
      data: {'streakCount': streakCount},
    );
  }

  // ── Seri kirildi bildirimi ──────────────────────
  static Future<void> notifyStreakBroken() async {
    await show(
      title: 'Serin Kirildi! 💔',
      body: 'Ogrenme seriniz sifirlandi. Yeni bir seri baslatmak icin hemen ders yap!',
      type: NotificationType.streakBroken,
    );
  }

  // ── Zamanlanmis seri hatirlatmalari ─────────────
  /// Kullanici arka plana gectiginde, seri bitimine
  /// 2h, 4h, 8h, 12h kala bildirim planla
  static Future<void> scheduleStreakReminders({
    required bool didStudyToday,
    required int streak,
  }) async {
    if (didStudyToday || streak <= 0) {
      // Seri bitme riski yok — mevcut zamanlilari iptal et
      await cancelStreakReminders();
      return;
    }

    try {
      await init();
      await cancelStreakReminders();

      final now = tz.TZDateTime.now(tz.local);
      // Gun sonu = 23:59
      final endOfDay = tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 59);
      final hoursLeft = endOfDay.difference(now).inHours;

      // Sadece gerekli araliklari planla
      final reminders = <int>[2, 4, 8, 12];
      for (int i = 0; i < reminders.length; i++) {
        final h = reminders[i];
        if (hoursLeft >= h) {
          final scheduleTime = endOfDay.subtract(Duration(hours: h));
          if (scheduleTime.isAfter(now)) {
            final urgency = h <= 2 ? 'Acele et, serin kaybolmak uzere!' : 'Bugunku dersini yapmayi unutma!';
            await _plugin.zonedSchedule(
              _streakReminderIdBase + i,
              'Seri Hatirlatmasi 🔥',
              '$h saat kaldi! $urgency',
              scheduleTime,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'finalai_streak', 'Seri Hatirlatmalari',
                  channelDescription: 'Ogrenme serisi hatirlatmalari',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: null,
            );
            debugPrint('[NotifService] Streak reminder scheduled: $h hours before');
          }
        }
      }
    } catch (e) {
      debugPrint('Schedule streak reminders error: $e');
    }
  }

  /// Zamanlanmis seri hatirlatmalarini iptal et
  static Future<void> cancelStreakReminders() async {
    try {
      for (int i = 0; i < 4; i++) {
        await _plugin.cancel(_streakReminderIdBase + i);
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════
  //  ENERGY NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  // ── Enerji yenilendi bildirimi ──────────────────
  static Future<void> notifyEnergyFull() async {
    await show(
      title: 'Enerji Doldu! ⚡',
      body: 'Enerjin tamamen yenilendi. Ogrenmeye devam et!',
      type: NotificationType.energyFull,
    );
  }

  /// Enerji dolunca zamanlanmis bildirim gonder
  /// minutesUntilFull > 0 oldugunda planla
  static Future<void> scheduleEnergyFullReminder({required int minutesUntilFull}) async {
    if (minutesUntilFull <= 0) return;
    try {
      await init();
      await _plugin.cancel(_energyFullId);
      final scheduleTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutesUntilFull));
      await _plugin.zonedSchedule(
        _energyFullId,
        'Enerji Doldu! ⚡',
        'Enerjin tamamen yenilendi. Ogrenmeye devam et!',
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'finalai_energy', 'Enerji Bildirimleri',
            channelDescription: 'Enerji yenilenmesi bildirimi',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('[NotifService] Energy full reminder in $minutesUntilFull minutes');
    } catch (e) {
      debugPrint('Schedule energy error: $e');
    }
  }

  /// Enerji zamanlanmis bildirimini iptal et
  static Future<void> cancelEnergyReminder() async {
    try { await _plugin.cancel(_energyFullId); } catch (_) {}
  }

  // ═══════════════════════════════════════════════════
  //  XP & DAILY QUEST NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  // ── XP kazanildi bildirimi ──────────────────────
  static Future<void> notifyXpEarned({required int xp, String? source}) async {
    final src = source ?? 'ders';
    await show(
      title: '+$xp XP Kazandin! ✨',
      body: '$src tamamlayarak $xp XP kazandin. Harika gidiyorsun!',
      type: NotificationType.xpEarned,
      data: {'xp': xp, 'source': src},
    );
  }

  // ── Gunluk gorev bildirimi ──────────────────────
  static Future<void> notifyDailyQuest({required String questName, bool completed = false}) async {
    if (completed) {
      await show(
        title: 'Gorev Tamamlandi! 🎯',
        body: '"$questName" gorevini tamamladin. Odulunu almaya gel!',
        type: NotificationType.dailyQuest,
        data: {'quest': questName, 'completed': true},
      );
    } else {
      await show(
        title: 'Gunluk Gorev Bekliyor! 📋',
        body: '"$questName" gorevi henuz tamamlanmadi. Hemen basla!',
        type: NotificationType.dailyQuest,
        data: {'quest': questName, 'completed': false},
      );
    }
  }

  /// Gunluk gorev hatirlatmasi planla (aksamustu 17:00)
  static Future<void> scheduleDailyQuestReminder() async {
    try {
      await init();
      await _plugin.cancel(_dailyQuestId);
      final now = tz.TZDateTime.now(tz.local);
      var scheduleTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 17, 0);
      if (scheduleTime.isBefore(now)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _dailyQuestId,
        'Gunluk Gorevlerin Bekliyor! 📋',
        'Bugunki gorevlerini tamamla ve odul kazan!',
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'finalai_quest', 'Gunluk Gorev Bildirimleri',
            channelDescription: 'Gunluk gorev hatirlatmalari',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotifService] Daily quest reminder scheduled for 17:00');
    } catch (e) {
      debugPrint('Schedule daily quest error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  //  PDF NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  // ── PDF yuklendi bildirimi ──────────────────────
  static Future<void> notifyPdfUploaded({required String fileName}) async {
    await show(
      title: 'Belge Yuklendi! 📄',
      body: '"$fileName" basariyla yuklendi. AI analiz basliyor...',
      type: NotificationType.pdfUpload,
      data: {'fileName': fileName},
    );
  }

  // ── PDF ozeti hazir bildirimi ───────────────────
  static Future<void> notifyPdfSummaryReady({required String fileName}) async {
    await show(
      title: 'Ozet Hazir! 📝',
      body: '"$fileName" icin ozet, quiz ve flashcard olusturuldu!',
      type: NotificationType.pdfSummary,
      data: {'fileName': fileName},
    );
  }

  // ── Plan hazir bildirimi ─────────────────────────
  static Future<void> notifyPlanReady({required String subject}) async {
    // Progress bildirimini iptal et
    try { await _plugin.cancel(_planProgressId); } catch (_) {}
    await show(
      title: 'Plan Hazir! 🎯',
      body: '"$subject" icin ogrenme planin olusturuldu. Hemen basla!',
      type: NotificationType.general,
      data: {'subject': subject},
    );
  }

  // ── Plan ilerleme bildirimi (ongoing) ────────────
  static const _planProgressId = 8000;
  static Future<void> showPlanProgress({required int percent, required String subject}) async {
    try {
      await init();
      final androidDetails = AndroidNotificationDetails(
        'finalai_progress', 'FinalAI Ilerleme',
        channelDescription: 'AI plan olusturma ilerlemesi',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
        onlyAlertOnce: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());
      await _plugin.show(_planProgressId, '$subject plani hazirlaniyor...', '%$percent tamamlandi', details);
    } catch (e) {
      debugPrint('[NotifService] Progress show error: $e');
    }
  }

  static Future<void> cancelPlanProgress() async {
    try {
      await init();
      await _plugin.cancel(_planProgressId);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════
  //  MISC NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  // ── Ogretici bilgi bildirimi ────────────────────
  static Future<void> notifyDailyTip({required String subject, required String tip}) async {
    await show(
      title: '$subject 💡',
      body: tip,
      type: NotificationType.dailyTip,
      data: {'subject': subject},
    );
  }

  // ── Basarim bildirimi ───────────────────────────
  static Future<void> notifyAchievement({required String title, required String desc}) async {
    await show(
      title: 'Yeni Basarim! 🏆 $title',
      body: desc,
      type: NotificationType.achievement,
    );
  }

  // ═══════════════════════════════════════════════════
  //  HISTORY MANAGEMENT
  // ═══════════════════════════════════════════════════

  // ── Bildirim gecmisi ────────────────────────────
  static Future<List<AppNotification>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final items = list.map((j) => AppNotification.fromJson(j)).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) { return []; }
  }

  static Future<void> _addToHistory(AppNotification n) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      final list = raw != null ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      list.insert(0, n.toJson());
      // Max 50 bildirim sakla
      if (list.length > 50) list.removeRange(50, list.length);
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in list) {
        if (item['id'] == id) item['read'] = true;
      }
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in list) { item['read'] = true; }
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  static Future<int> unreadCount() async {
    final list = await getHistory();
    return list.where((n) => !n.read).length;
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// Tum zamanlanmis bildirimleri iptal et ve gecmisi temizle (hesap silme icin)
  static Future<void> cancelAllAndClear() async {
    try {
      await init();
      await _plugin.cancelAll();
    } catch (_) {}
    await clearHistory();
  }

  // ═══════════════════════════════════════════════════
  //  LIFECYCLE CHECK — arka plana geciste cagirilir
  // ═══════════════════════════════════════════════════

  /// Arka plana gecerken seri hatirlatma bildirimleri planla.
  /// NOT: Enerji bildirimi burada gonderilMEZ — sadece
  /// enerji gercekten dolunca zamanlanmis bildirim kullanilir.
  static Future<void> onPauseCheck({
    required int energy,
    required int energyMax,
    required DateTime? lastActiveDate,
    required int streak,
    required bool didStudyToday,
    required bool streakFreezeAvailable,
    String? subject,
  }) async {
    // Seri hatirlatmalarini planla (bugun ders yapilmadiysa)
    await scheduleStreakReminders(
      didStudyToday: didStudyToday,
      streak: streak,
    );

    // Enerji dolu degilse, dolma zamanini hesapla ve planla
    if (energy < energyMax) {
      // Her 10 dakikada 1 enerji yenilenir (ornek hesaplama)
      final missing = energyMax - energy;
      final minutesUntilFull = missing * 10;
      await scheduleEnergyFullReminder(minutesUntilFull: minutesUntilFull);
    } else {
      // Enerji zaten dolu — zamanlanmis bildirimi iptal et
      await cancelEnergyReminder();
    }

    // Gunluk gorev hatirlatmasini her zaman planla
    await scheduleDailyQuestReminder();
  }

  static String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
