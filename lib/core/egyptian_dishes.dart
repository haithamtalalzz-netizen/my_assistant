import 'app_state.dart';
import 'usda_food_db.dart';

/// مكوّن فى وصفة أكلة مصرية: `fdcId` من قاعدة USDA المشحونة + وزنه بالجرام.
/// **الوزن هو التقدير الوحيد؛ القيم الغذائية نفسها بتتحسب من أرقام USDA.**
class DishPart {
  final int fdcId;
  final double grams;
  const DishPart(this.fdcId, this.grams);
}

/// أكلة مصرية = اسم + وصفة (مكوّنات بأوزانها). السعرات **محسوبة** من USDA،
/// مش مكتوبة بالإيد — فتفضل موثوقة زى باقى الدليل.
class EgyptianDish {
  final String ar;
  final String en;

  /// وزن الطبق النموذجى بالجرام (لعرض «لكل طبق»).
  final double servingGrams;
  final List<DishPart> parts;

  const EgyptianDish({
    required this.ar,
    required this.en,
    required this.servingGrams,
    required this.parts,
  });

  String get name => AppState.isEnglish ? en : ar;
}

/// أوزان المكوّنات تقديرية لطبق نموذجى (البحث والمراجعة اتعملوا يدوى)،
/// والـ`fdcId` كلهم اتأكّد إنهم فى الأصل المشحون بالقيم الصح.
///
/// الـids المستخدمة (من `assets/food/usda_foods.json`):
///  168880 رز أبيض مطبوخ · 169737 مكرونة مطبوخة · 172421 عدس مسلوق
///  173800 حمص معلّب · 170054 صلصة طماطم · 170000 بصل نيّئ
///  171411 زيت نباتى · 171413 زيت زيتون · 173424 بيض مسلوق
///  171800 لحمة مفرومة مطبوخة · 171477 صدور فراخ مشوى · 169229 باذنجان مطبوخ
///  168420 ملوخية مطبوخة · 168604 طحينة · 173753 فول مدمس · 170189 نيّئ..
const List<EgyptianDish> kEgyptianDishes = [
  EgyptianDish(
    ar: 'كشرى',
    en: 'Koshari',
    servingGrams: 450,
    parts: [
      DishPart(168880, 150), // رز
      DishPart(169737, 120), // مكرونة
      DishPart(172421, 100), // عدس
      DishPart(173800, 40), // حمص
      DishPart(170054, 60), // صلصة طماطم
      DishPart(170000, 20), // بصل مقلى (كتقدير)
      DishPart(171411, 15), // زيت
    ],
  ),
  EgyptianDish(
    ar: 'عدس بشوربة',
    en: 'Lentil soup',
    servingGrams: 300,
    parts: [
      DishPart(172421, 220), // عدس
      DishPart(170000, 30), // بصل
      DishPart(171411, 10), // زيت
    ],
  ),
  EgyptianDish(
    ar: 'فول مدمس',
    en: 'Ful medames',
    servingGrams: 220,
    parts: [
      DishPart(173753, 180), // فول
      DishPart(171413, 12), // زيت زيتون
    ],
  ),
  EgyptianDish(
    ar: 'ملوخية',
    en: 'Molokhia',
    servingGrams: 250,
    parts: [
      DishPart(168420, 220), // ملوخية
      DishPart(171411, 15), // سمنة/زيت (كتقدير)
    ],
  ),
  EgyptianDish(
    ar: 'ملوخية بالفراخ',
    en: 'Molokhia with chicken',
    servingGrams: 350,
    parts: [
      DishPart(168420, 200), // ملوخية
      DishPart(171477, 120), // صدور فراخ
      DishPart(171411, 15), // زيت
    ],
  ),
  EgyptianDish(
    ar: 'رز بالشعرية',
    en: 'Rice with vermicelli',
    servingGrams: 200,
    parts: [
      DishPart(168880, 170), // رز
      DishPart(169737, 20), // شعرية (كمكرونة تقريباً)
      DishPart(171411, 12), // زيت
    ],
  ),
  EgyptianDish(
    ar: 'مكرونة بالصلصة',
    en: 'Pasta with tomato sauce',
    servingGrams: 300,
    parts: [
      DishPart(169737, 220), // مكرونة
      DishPart(170054, 70), // صلصة
      DishPart(171411, 10), // زيت
    ],
  ),
  EgyptianDish(
    ar: 'بابا غنوج',
    en: 'Baba ganoush',
    servingGrams: 150,
    parts: [
      DishPart(169229, 110), // باذنجان مطبوخ
      DishPart(168604, 25), // طحينة
      DishPart(171413, 8), // زيت زيتون
    ],
  ),
  EgyptianDish(
    ar: 'صلصة طحينة',
    en: 'Tahini sauce',
    servingGrams: 60,
    parts: [
      DishPart(168604, 40), // طحينة
    ],
  ),
  EgyptianDish(
    ar: 'كفتة مشوية',
    en: 'Grilled kofta',
    servingGrams: 150,
    parts: [
      DishPart(171800, 140), // لحمة مفرومة مطبوخة
      DishPart(170000, 10), // بصل
    ],
  ),
  EgyptianDish(
    ar: 'عجّة بيض',
    en: 'Egg omelet (eggah)',
    servingGrams: 130,
    parts: [
      DishPart(173424, 100), // بيض
      DishPart(170000, 15), // بصل
      DishPart(171411, 10), // زيت
    ],
  ),
];

/// بحث فى الأكلات المصرية بالعربى أو الإنجليزى (تطبيع الهمزات).
List<EgyptianDish> searchDishes(String query) {
  final q = normalizeAr(query);
  if (q.isEmpty) return const [];
  return [
    for (final d in kEgyptianDishes)
      if (normalizeAr(d.ar).contains(q) || d.en.toLowerCase().contains(q)) d
  ];
}

/// بيحسب القيم الغذائية لطبق من مكوّناته باستخدام أرقام USDA — بيرجّع null
/// لو أى مكوّن مش لاقيه فى القاعدة (مايخترعش رقم).
Future<UsdaNutrients?> dishNutrients(EgyptianDish dish) async {
  final all = await UsdaDb.all();
  final byId = {for (final f in all) f.id: f};
  double kcal = 0, p = 0, c = 0, f = 0;
  double? fiber, sugar, sodium, sat;
  for (final part in dish.parts) {
    final food = byId[part.fdcId];
    if (food == null) return null; // مكوّن مفقود → مانحسبش تقدير غلط
    final n = food.forGrams(part.grams);
    kcal += n.kcal;
    p += n.protein;
    c += n.carbs;
    f += n.fat;
    if (n.fiber != null) fiber = (fiber ?? 0) + n.fiber!;
    if (n.sugar != null) sugar = (sugar ?? 0) + n.sugar!;
    if (n.sodium != null) sodium = (sodium ?? 0) + n.sodium!;
    if (n.sat != null) sat = (sat ?? 0) + n.sat!;
  }
  return UsdaNutrients(
    kcal: kcal,
    protein: p,
    carbs: c,
    fat: f,
    fiber: fiber,
    sugar: sugar,
    sodium: sodium,
    sat: sat,
  );
}
