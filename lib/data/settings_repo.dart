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

  /// موقع مخصّص (أي مدينة في العالم) — إحداثيات محفوظة من البحث الجغرافي.
  /// null = مفيش موقع مخصّص، استخدم المحافظة.
  Future<({double lat, double lng, String label})?> customLocation() async {
    final lat = double.tryParse(await get('loc_lat') ?? '');
    final lng = double.tryParse(await get('loc_lng') ?? '');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng, label: await get('loc_label') ?? '');
  }

  Future<void> setCustomLocation(double lat, double lng, String label) async {
    await set('loc_lat', '$lat');
    await set('loc_lng', '$lng');
    await set('loc_label', label);
  }

  /// الرجوع لمحافظة مصرية (يمسح الموقع العالمي المخصّص).
  Future<void> clearCustomLocation() async {
    final db = await AppDb.instance;
    await db.delete('settings',
        where: 'key IN (?, ?, ?)',
        whereArgs: ['loc_lat', 'loc_lng', 'loc_label']);
  }

  /// اسم الموقع المعروض: المدينة العالمية لو متحددة، وإلا المحافظة.
  Future<String> locationLabel() async {
    final loc = await customLocation();
    if (loc != null && loc.label.isNotEmpty) return loc.label;
    return governorateName();
  }

  Future<bool> healthSyncEnabled() async => await get('health_sync') == '1';

  /// عناصر الصفحة الرئيسية المخفية (يتحكم فيها المستخدم من الإعدادات).
  Future<Set<String>> hiddenHomeSections() async {
    final raw = await get('home_hidden') ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> setHomeSectionHidden(String key, bool hidden) async {
    final current = await hiddenHomeSections();
    if (hidden) {
      current.add(key);
    } else {
      current.remove(key);
    }
    await set('home_hidden', current.join(','));
  }

  Future<bool> ramadanMode() async => await get('ramadan_mode') == '1';

  /// ملخص بكرة المسائي — شغال افتراضيًا الساعة 21:30.
  Future<bool> eveningSummaryEnabled() async =>
      await get('evening_summary') != '0';

  Future<String> eveningTime() async => await get('evening_time') ?? '21:30';
}
