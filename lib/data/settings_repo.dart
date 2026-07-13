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

  Future<void> setCalorieGoal(int kcal) async =>
      set('calorie_goal', kcal <= 0 ? '' : '$kcal');

  /// النظام الغذائي المُفعّل حاليًا (فاضي = مفيش).
  Future<String> activeDietPlan() async => await get('diet_plan') ?? '';
  Future<void> setActiveDietPlan(String id) async => set('diet_plan', id);

  /// أهداف الماكروز بالجرام (0 = مش محدد).
  Future<int> proteinTarget() async =>
      int.tryParse(await get('diet_protein_g') ?? '') ?? 0;
  Future<int> carbsTarget() async =>
      int.tryParse(await get('diet_carbs_g') ?? '') ?? 0;
  Future<int> fatTarget() async =>
      int.tryParse(await get('diet_fat_g') ?? '') ?? 0;

  Future<void> setMacroTargets(int protein, int carbs, int fat) async {
    await set('diet_protein_g', protein <= 0 ? '' : '$protein');
    await set('diet_carbs_g', carbs <= 0 ? '' : '$carbs');
    await set('diet_fat_g', fat <= 0 ? '' : '$fat');
  }

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

  /// تشغيل صوت أذان (تنبيه صوتى قوى) مع إشعار الصلاة — مقفول افتراضيًا.
  Future<bool> adhanSoundEnabled() async => await get('adhan_sound') == '1';
  Future<void> setAdhanSound(bool on) async =>
      set('adhan_sound', on ? '1' : '0');

  /// صوت أذان اختاره المستخدم من جهازه (content:// URI + قناة + اسم للعرض).
  /// مفيش أصوات مدمجة — كل مستخدم بيرفع ملف الأذان بتاعه.
  Future<String?> adhanCustomUri() async => await get('adhan_custom_uri');
  Future<String?> adhanCustomChannel() async => await get('adhan_custom_channel');
  Future<String> adhanCustomLabel() async => await get('adhan_custom_label') ?? '';
  Future<void> setAdhanCustom(
      {required String uri, required String label, required String channel}) async {
    await set('adhan_custom_uri', uri);
    await set('adhan_custom_label', label);
    await set('adhan_custom_channel', channel);
  }

  /// تذكير الجمعة (سورة الكهف + الصلاة على النبى) — شغّال افتراضيًا.
  Future<bool> fridayReminderEnabled() async =>
      await get('friday_reminder') != '0';
  Future<void> setFridayReminder(bool on) async =>
      set('friday_reminder', on ? '1' : '0');

  /// تذكير السنن الرواتب بعد كل فرض — مقفول افتراضيًا.
  Future<bool> rawatibRemindersEnabled() async =>
      await get('rawatib_reminders') == '1';
  Future<void> setRawatibReminders(bool on) async =>
      set('rawatib_reminders', on ? '1' : '0');

  /// تذكير السحور والإفطار (لأيام الصيام/رمضان) — مقفول افتراضيًا.
  Future<bool> fastingRemindersEnabled() async =>
      await get('fasting_reminders') == '1';
  Future<void> setFastingReminders(bool on) async =>
      set('fasting_reminders', on ? '1' : '0');

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

  /// حجم خط المصحف (نقطة) — الافتراضى 26.
  Future<double> quranFontSize() async =>
      double.tryParse(await get('quran_font') ?? '') ?? 26;
  Future<void> setQuranFontSize(double v) async =>
      set('quran_font', v.toStringAsFixed(0));

  /// آخر موضع قراءة: (رقم السورة، رقم الآية) — null لو مفيش.
  Future<({int surah, int ayah})?> quranBookmark() async {
    final s = int.tryParse(await get('quran_last_surah') ?? '');
    final a = int.tryParse(await get('quran_last_ayah') ?? '');
    if (s == null || a == null) return null;
    return (surah: s, ayah: a);
  }

  Future<void> setQuranBookmark(int surah, int ayah) async {
    await set('quran_last_surah', '$surah');
    await set('quran_last_ayah', '$ayah');
  }

  /// القارئ المختار للتلاوة (مجلد everyayah) — الافتراضى العفاسي.
  Future<String> quranReciter() async =>
      await get('quran_reciter') ?? 'Alafasy_128kbps';
  Future<void> setQuranReciter(String id) async => set('quran_reciter', id);

  /// طريقة عرض المصحف: 'page' (صور الصفحات) أو 'text' (نص + تفسير + صوت).
  Future<String> quranViewMode() async => await get('quran_view') ?? 'page';
  Future<void> setQuranViewMode(String m) async => set('quran_view', m);

  /// آخر صفحة مصحف (عرض الصور) — الافتراضى 1.
  Future<int> quranLastPage() async =>
      int.tryParse(await get('quran_last_page') ?? '') ?? 1;
  Future<void> setQuranLastPage(int p) async => set('quran_last_page', '$p');

  /// الوضع الليلى للمصحف (عكس ألوان الصفحة).
  Future<bool> mushafNight() async => await get('mushaf_night') == '1';
  Future<void> setMushafNight(bool on) async =>
      set('mushaf_night', on ? '1' : '0');

  /// سرعة التلاوة (0.75 / 1 / 1.25 / 1.5) — الافتراضى 1.
  Future<double> quranSpeed() async =>
      double.tryParse(await get('quran_speed') ?? '') ?? 1.0;
  Future<void> setQuranSpeed(double v) async =>
      set('quran_speed', v.toString());

  /// ترتيب كروت أدوات صفحة الصلاة (رتّبها المستخدم بالسحب).
  Future<List<String>> prayerToolsOrder() async {
    final raw = await get('prayer_tools_order') ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> setPrayerToolsOrder(List<String> ids) async =>
      set('prayer_tools_order', ids.join(','));

  /// ترتيب كروت أى صفحة (عام) — مفتاح لكل صفحة.
  Future<List<String>> cardOrder(String key) async {
    final raw = await get('order.$key') ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> setCardOrder(String key, List<String> ids) async =>
      set('order.$key', ids.join(','));

  Future<bool> ramadanMode() async => await get('ramadan_mode') == '1';

  /// ملخص بكرة المسائي — شغال افتراضيًا الساعة 21:30.
  Future<bool> eveningSummaryEnabled() async =>
      await get('evening_summary') != '0';

  Future<String> eveningTime() async => await get('evening_time') ?? '21:30';

  /// ميزانية شهرية لكل فئة مصروفات — مخزّنة "فئة:مبلغ|فئة:مبلغ".
  /// (أسماء الفئات عربية بدون : أو | فالتفكيك آمن.)
  Future<Map<String, double>> categoryBudgets() async {
    final raw = await get('category_budgets') ?? '';
    final map = <String, double>{};
    for (final part in raw.split('|')) {
      final i = part.lastIndexOf(':');
      if (i <= 0) continue;
      final amt = double.tryParse(part.substring(i + 1));
      if (amt != null && amt > 0) map[part.substring(0, i)] = amt;
    }
    return map;
  }

  Future<void> setCategoryBudget(String cat, double amount) async {
    final map = await categoryBudgets();
    if (amount <= 0) {
      map.remove(cat);
    } else {
      map[cat] = amount;
    }
    await set('category_budgets',
        map.entries.map((e) => '${e.key}:${e.value}').join('|'));
  }
}
