import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_state.dart';
import 'food_db.dart' show FoodItem;

/// صنف أكل بقيمه الغذائية الكاملة لكل ١٠٠ جم — **كل الأرقام منقولة حرفياً من
/// USDA FoodData Central (SR Legacy، ملكية عامة)**. مفيش أى رقم متكتوب بالإيد.
///
/// الأصل بيتبنى بـ`tools/build_food_db.py` -> `assets/food/usda_foods.json`.
class UsdaFood {
  final int id;
  final String en;
  final String? ar;
  final String cat;

  /// لكل ١٠٠ جم.
  final double kcal, protein, carbs, fat;

  /// عناصر إضافية (null = USDA ماعندهاش القيمة دى للصنف ده).
  final double? fiber, sugar, sodium, chol, sat, calcium, iron, potassium;

  /// طريقة التحضير/الطهى المستخرجة من وصف USDA (raw/boiled/fried/...).
  final String? prep;

  /// رقم مجموعة «نفس الصنف بطرق طهى مختلفة» (null = مالوش بدائل).
  final int? group;

  /// حصة منزلية من USDA: الوصف + وزنها بالجرام.
  final String? portionLabel;
  final int? portionGrams;

  const UsdaFood({
    required this.id,
    required this.en,
    this.ar,
    required this.cat,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.chol,
    this.sat,
    this.calcium,
    this.iron,
    this.potassium,
    this.prep,
    this.group,
    this.portionLabel,
    this.portionGrams,
  });

  factory UsdaFood.fromJson(Map<String, dynamic> m) {
    double? d(String k) => (m[k] as num?)?.toDouble();
    return UsdaFood(
      id: m['id'] as int,
      en: m['en'] as String,
      ar: m['ar'] as String?,
      cat: m['cat'] as String? ?? '',
      kcal: d('kcal') ?? 0,
      protein: d('p') ?? 0,
      carbs: d('c') ?? 0,
      fat: d('f') ?? 0,
      fiber: d('fiber'),
      sugar: d('sugar'),
      sodium: d('sodium'),
      chol: d('chol'),
      sat: d('sat'),
      calcium: d('calcium'),
      iron: d('iron'),
      potassium: d('potassium'),
      prep: m['prep'] as String?,
      group: m['g'] as int?,
      portionLabel: m['pl'] as String?,
      portionGrams: (m['pg'] as num?)?.round(),
    );
  }

  /// الاسم المعروض: عربى لو موجود (٨٦٪ من القاعدة)، وإلا وصف USDA الإنجليزى.
  String get name => AppState.isEnglish ? en : (ar ?? en);

  /// الحصة الافتراضية بالجرام (حصة USDA أو ١٠٠ جم).
  int get defaultGrams => portionGrams ?? 100;

  /// المشروبات بتتقاس بالملى، الباقى بالجرام.
  bool get isDrink =>
      cat.contains('مشروبات') || cat.contains('Beverages');

  /// بيحوّل الصنف لـ[FoodItem] عشان يشتغل مع منتقى الأكل وتسجيل الوجبات
  /// الموجودين — **الأرقام بتتنقل زى ما هى، مفيش أى تحويل أو تقريب**.
  FoodItem toFoodItem() => FoodItem(
        ar ?? en,
        en,
        kcal,
        protein,
        carbs,
        fat,
        unit: isDrink ? 'مل' : 'جم',
        portion: defaultGrams.toDouble(),
        group: cat,
      );

  /// القيم لكمية معيّنة بالجرام — ضرب خطى بسيط على قيم الـ١٠٠ جم.
  UsdaNutrients forGrams(double g) {
    final r = g / 100.0;
    double? m(double? v) => v == null ? null : v * r;
    return UsdaNutrients(
      kcal: kcal * r,
      protein: protein * r,
      carbs: carbs * r,
      fat: fat * r,
      fiber: m(fiber),
      sugar: m(sugar),
      sodium: m(sodium),
      chol: m(chol),
      sat: m(sat),
      calcium: m(calcium),
      iron: m(iron),
      potassium: m(potassium),
    );
  }
}

/// قيم غذائية محسوبة لكمية.
class UsdaNutrients {
  final double kcal, protein, carbs, fat;
  final double? fiber, sugar, sodium, chol, sat, calcium, iron, potassium;
  const UsdaNutrients({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.chol,
    this.sat,
    this.calcium,
    this.iron,
    this.potassium,
  });
}

/// طرق الطهى بالعربى (نفس مفاتيح الـJSON).
String prepLabel(String? prep) => switch (prep) {
      'raw' => AppState.isEnglish ? 'Raw' : 'نيّئ',
      'boiled' => AppState.isEnglish ? 'Boiled' : 'مسلوق',
      'fried' => AppState.isEnglish ? 'Fried' : 'مقلى',
      'roasted' => AppState.isEnglish ? 'Roasted' : 'مشوى فى الفرن',
      'grilled' => AppState.isEnglish ? 'Grilled' : 'مشوى',
      'steamed' => AppState.isEnglish ? 'Steamed' : 'على البخار',
      'baked' => AppState.isEnglish ? 'Baked' : 'فى الفرن',
      'stewed' => AppState.isEnglish ? 'Stewed' : 'مسبّك',
      'microwaved' => AppState.isEnglish ? 'Microwaved' : 'ميكروويف',
      'cooked' => AppState.isEnglish ? 'Cooked' : 'مطبوخ',
      'canned' => AppState.isEnglish ? 'Canned' : 'معلّب',
      'dried' => AppState.isEnglish ? 'Dried' : 'مجفف',
      'frozen' => AppState.isEnglish ? 'Frozen' : 'مجمّد',
      _ => '',
    };

/// تطبيع عربى للبحث: بيشيل التشكيل ويوحّد أ/إ/آ->ا و ى->ي و ة->ه.
String normalizeAr(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    // تشكيل
    if (r >= 0x064B && r <= 0x0652) continue;
    var c = String.fromCharCode(r);
    c = switch (c) {
      'أ' || 'إ' || 'آ' => 'ا',
      'ى' => 'ي',
      'ة' => 'ه',
      'ؤ' => 'و',
      'ئ' => 'ي',
      _ => c,
    };
    b.write(c);
  }
  return b.toString().toLowerCase().trim();
}

/// بيفكّ الـJSON فى isolate (٢ ميجا) عشان الواجهة ماتهنّجش.
List<UsdaFood> _parse(String raw) {
  final list = jsonDecode(raw) as List;
  return [
    for (final e in list) UsdaFood.fromJson(e as Map<String, dynamic>)
  ];
}

/// قاعدة أكل USDA — بتتحمّل مرة واحدة وتتخزّن فى الذاكرة.
class UsdaDb {
  static List<UsdaFood>? _all;
  static Map<int, List<UsdaFood>>? _groups;
  static Future<List<UsdaFood>>? _loading;

  /// كل الأصناف (٦٨٧٦) — بتتحمّل كسول.
  static Future<List<UsdaFood>> all() {
    if (_all != null) return Future.value(_all);
    return _loading ??= _load();
  }

  static Future<List<UsdaFood>> _load() async {
    final raw = await rootBundle.loadString('assets/food/usda_foods.json');
    final list = await compute(_parse, raw);
    _all = list;
    final g = <int, List<UsdaFood>>{};
    for (final f in list) {
      if (f.group != null) (g[f.group!] ??= []).add(f);
    }
    _groups = g;
    _loading = null;
    return list;
  }

  /// بحث بالعربى أو الإنجليزى — بيرتّب المطابقة من أول الاسم الأول.
  static Future<List<UsdaFood>> search(String query, {int limit = 60}) async {
    final q = normalizeAr(query);
    if (q.length < 2) return const [];
    final list = await all();
    final starts = <UsdaFood>[];
    final contains = <UsdaFood>[];
    for (final f in list) {
      final ar = f.ar == null ? '' : normalizeAr(f.ar!);
      final en = f.en.toLowerCase();
      if (ar.startsWith(q) || en.startsWith(q)) {
        starts.add(f);
      } else if (ar.contains(q) || en.contains(q)) {
        contains.add(f);
      }
      if (starts.length >= limit) break;
    }
    return [...starts, ...contains].take(limit).toList();
  }

  /// «نفس الصنف بطرق طهى تانية» — مرتّبة بالسعرات.
  static Future<List<UsdaFood>> variants(UsdaFood f) async {
    await all();
    final g = f.group;
    if (g == null) return const [];
    final list = [...?_groups?[g]]..sort((a, b) => a.kcal.compareTo(b.kcal));
    return list;
  }

  /// للاختبارات: تحميل من نص JSON بدل الأصل.
  @visibleForTesting
  static void loadForTests(String rawJson) {
    _all = _parse(rawJson);
    final g = <int, List<UsdaFood>>{};
    for (final f in _all!) {
      if (f.group != null) (g[f.group!] ??= []).add(f);
    }
    _groups = g;
  }

  @visibleForTesting
  static void reset() {
    _all = null;
    _groups = null;
    _loading = null;
  }
}
