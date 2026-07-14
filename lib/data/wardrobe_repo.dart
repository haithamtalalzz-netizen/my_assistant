import '../core/ar.dart';
import '../core/db.dart';
import '../core/gemini.dart';
import '../core/l10n.dart';
import '../core/weather.dart';
import '../models/models.dart';

const List<String> kClothingCategories = [
  'top',
  'bottom',
  'outer',
  'shoes',
  'accessory',
];

const List<String> kClothingSeasons = ['all', 'summer', 'winter'];
const List<String> kClothingFormality = ['casual', 'formal', 'sport'];

String clothingCategoryLabel(String c) => switch (c) {
      'top' => tr('قميص/تيشيرت', 'Top'),
      'bottom' => tr('بنطلون', 'Bottom'),
      'outer' => tr('جاكيت', 'Outerwear'),
      'shoes' => tr('حذاء', 'Shoes'),
      'accessory' => tr('إكسسوار', 'Accessory'),
      _ => c,
    };

String clothingSeasonLabel(String s) => switch (s) {
      'all' => tr('كل المواسم', 'All seasons'),
      'summer' => tr('صيفي', 'Summer'),
      'winter' => tr('شتوي', 'Winter'),
      _ => s,
    };

String clothingFormalityLabel(String f) => switch (f) {
      'casual' => tr('كاجوال', 'Casual'),
      'formal' => tr('رسمي', 'Formal'),
      'sport' => tr('رياضي', 'Sport'),
      _ => f,
    };

/// الموسم المناسب حسب أعلى حرارة النهارده.
String seasonForTemp(double maxTemp) {
  if (maxTemp >= 30) return 'summer';
  if (maxTemp <= 18) return 'winter';
  return 'all';
}

class WardrobeRepo {
  Future<int> save(ClothingItem c) async {
    final db = await AppDb.instance;
    if (c.id == null) return db.insert('clothes', c.toMap());
    await db.update('clothes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    return c.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('clothes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ClothingItem>> all({String? category}) async {
    final db = await AppDb.instance;
    final rows = await db.query('clothes',
        where: category == null ? null : 'category = ?',
        whereArgs: category == null ? null : [category],
        orderBy: 'favorite DESC, name');
    return rows.map(ClothingItem.fromMap).toList();
  }

  Future<void> markWorn(int id, {DateTime? now}) async {
    final db = await AppDb.instance;
    await db.update('clothes', {'last_worn': dayKey(now ?? DateTime.now())},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---- تتبّع الغسيل ----

  Future<void> setNeedsWash(int id, bool needs) async {
    final db = await AppDb.instance;
    await db.update('clothes', {'needs_wash': needs ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// القطع اللى محتاجة غسيل (سلة الغسيل).
  Future<List<ClothingItem>> laundry() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('clothes', where: 'needs_wash = 1', orderBy: 'name');
    return rows.map(ClothingItem.fromMap).toList();
  }

  Future<int> laundryCount() async => (await laundry()).length;

  /// «غسلت الكل» — تفريغ السلة.
  Future<void> washAll() async {
    final db = await AppDb.instance;
    await db.update('clothes', {'needs_wash': 0}, where: 'needs_wash = 1');
  }

  /// اقتراح تلبيسة بالقواعد: عنصر لكل خانة يطابق الموسم والرسمية، ويفضّل
  /// الأقل لبسًا مؤخرًا (last_worn الأقدم/الفاضي الأول). الجاكيت للشتا بس.
  /// [weather] لتحديد الموسم تلقائيًا (لو null بنجيبه).
  Future<Map<String, ClothingItem?>> suggestOutfit({
    required String formality,
    WeatherToday? weather,
  }) async {
    final w = weather ?? await WeatherService.today();
    final season = w == null ? 'all' : seasonForTemp(w.maxTemp);
    final all = await all_();
    ClothingItem? pick(String category) {
      final matches = all.where((c) {
        if (c.category != category) return false;
        if (c.season != 'all' && season != 'all' && c.season != season) {
          return false;
        }
        if (c.formality != formality) return false;
        return true;
      }).toList();
      if (matches.isEmpty) return null;
      // الأقل لبسًا مؤخرًا الأول (الفاضي = عمره مااتلبس = أولوية).
      matches.sort((a, b) => (a.lastWorn ?? '').compareTo(b.lastWorn ?? ''));
      return matches.first;
    }

    return {
      'top': pick('top'),
      'bottom': pick('bottom'),
      if (season == 'winter') 'outer': pick('outer'),
      'shoes': pick('shoes'),
    };
  }

  Future<List<ClothingItem>> all_() async {
    final db = await AppDb.instance;
    final rows = await db.query('clothes');
    return rows.map(ClothingItem.fromMap).toList();
  }

  static Future<bool> aiAvailable() => GeminiClient.hasKey();

  /// اقتراح تلبيسة ذكي عبر Gemini (لو فيه مفتاح) — يرجع نص أو null.
  Future<String?> geminiOutfit({required String formality}) async {
    final items = await all_();
    if (items.isEmpty) return null;
    final w = await WeatherService.today();
    final weatherLine = w == null
        ? 'غير معروف'
        : 'الحرارة العظمى ${w.maxTemp.round()}°، ${w.condition}';
    final wardrobe = items
        .map((c) =>
            '- ${c.name} (${clothingCategoryLabel(c.category)}، ${c.color.isEmpty ? 'لون غير محدد' : c.color}، ${clothingSeasonLabel(c.season)}، ${clothingFormalityLabel(c.formality)})')
        .join('\n');
    return GeminiClient.ask(
      system: 'انت مستشار أناقة عملي ومختصر. اقترح تلبيسة من خزانة المستخدم فقط '
          '(متقترحش حاجة مش موجودة). راعِ الطقس والمناسبة وتناسق الألوان. '
          'الرد سطرين-ثلاثة بالعربي المصري.',
      question: 'طقس النهارده: $weatherLine.\n'
          'المناسبة: ${clothingFormalityLabel(formality)}.\n'
          'خزانتي:\n$wardrobe\n\n'
          'إيه أنسب تلبيسة ألبسها النهارده؟',
    );
  }
}
