import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static const _kDailyUploadCount = 'daily_upload_count';
  static const _kDailyUploadDate = 'daily_upload_date';

  static Future<int> getTodayUploadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    final stored = prefs.getString(_kDailyUploadDate);
    final storedDate = stored == null ? null : DateTime.tryParse(stored);

    if (storedDate == null || !_isSameDay(storedDate, today)) {
      await prefs.setString(_kDailyUploadDate, today.toIso8601String());
      await prefs.setInt(_kDailyUploadCount, 0);
      return 0;
    }

    return prefs.getInt(_kDailyUploadCount) ?? 0;
  }

  static Future<void> incrementTodayUploadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTodayUploadCount();
    await prefs.setInt(_kDailyUploadCount, current + 1);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
