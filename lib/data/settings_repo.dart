import 'package:sqflite/sqflite.dart';

import '../core/db.dart';

class SettingsRepo {
  Future<String?> get(String key) async {
    final db = await AppDb.instance;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await AppDb.instance;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> userName() async => await get('user_name') ?? '';

  Future<int> waterGoal() async =>
      int.tryParse(await get('water_goal') ?? '') ?? 8;

  /// هدف السعرات اليومي (0 = مش محدد).
  Future<int> calorieGoal() async =>
      int.tryParse(await get('calorie_goal') ?? '') ?? 0;

  /// وضع «يوم صعب» — يهدّي التطبيق ويخفي الضغط.
  Future<bool> hardDayMode() async => await get('hard_day_mode') == '1';

  /// وضع السفر — يوقف تذكيرات الروتين مؤقتًا.
  Future<bool> travelMode() async => await get('travel_mode') == '1';

  Future<double> monthlyBudget() async =>
      double.tryParse(await get('monthly_budget') ?? '') ?? 0;

  Future<bool> appLockEnabled() async => await get('app_lock') == '1';

  /// إشعارات الأذان شغالة افتراضيًا.
  Future<bool> prayerNotificationsEnabled() async =>
      await get('prayer_notifications') != '0';

  Future<String> governorateName() async =>
      await get('governorate') ?? 'القاهرة';

  Future<bool> healthSyncEnabled() async => await get('health_sync') == '1';

  Future<bool> ramadanMode() async => await get('ramadan_mode') == '1';

  /// ملخص بكرة المسائي — شغال افتراضيًا الساعة 21:30.
  Future<bool> eveningSummaryEnabled() async =>
      await get('evening_summary') != '0';

  Future<String> eveningTime() async => await get('evening_time') ?? '21:30';
}
