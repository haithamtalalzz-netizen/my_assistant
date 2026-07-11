import 'app_state.dart';
import 'food_db.dart';
import 'l10n.dart';

/// نظام غذائي جاهز — بيحدّد الهدف وتوزيع الماكروز ونموذج يوم.
class DietPlan {
  final String id;
  final String ar;
  final String en;
  final String descAr;
  final String descEn;

  /// 'deficit' / 'maintain' / 'surplus'.
  final String goal;

  /// فرق السعرات عن الحفاظ (سالب = تنشيف، موجب = تضخيم).
  final int calorieDelta;

  /// توزيع الماكروز % (المجموع 100).
  final int proteinPct;
  final int carbsPct;
  final int fatPct;

  /// صيام متقطّع؟
  final bool fasting;

  /// نموذج يوم (أسطر قصيرة).
  final List<String> sampleDayAr;
  final List<String> sampleDayEn;

  const DietPlan({
    required this.id,
    required this.ar,
    required this.en,
    required this.descAr,
    required this.descEn,
    required this.goal,
    required this.calorieDelta,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    this.fasting = false,
    required this.sampleDayAr,
    required this.sampleDayEn,
  });

  String get name => AppState.isEnglish ? en : ar;
  String get desc => AppState.isEnglish ? descEn : descAr;
  List<String> get sampleDay => AppState.isEnglish ? sampleDayEn : sampleDayAr;

  /// تقدير الحفاظ (maintenance) من الوزن — تقريبي (وزن×30)، وافتراضي لو مفيش وزن.
  int maintenanceCalories(double? weightKg) =>
      (weightKg != null && weightKg > 0) ? (weightKg * 30).round() : 2000;

  /// السعرات المستهدفة للنظام ده.
  int targetCalories(double? weightKg) {
    final t = maintenanceCalories(weightKg) + calorieDelta;
    return t.clamp(1200, 4000);
  }

  /// جرامات الماكروز المستهدفة (بروتين/كارب 4 سعر، دهون 9 سعر).
  Nutrients targetMacros(int calories) => Nutrients(
        kcal: calories.toDouble(),
        protein: calories * proteinPct / 100 / 4,
        carbs: calories * carbsPct / 100 / 4,
        fat: calories * fatPct / 100 / 9,
      );
}

String dietGoalLabel(String g) => switch (g) {
      'deficit' => tr('تنشيف / إنقاص وزن', 'Cut / lose weight'),
      'maintain' => tr('حفاظ على الوزن', 'Maintain weight'),
      'surplus' => tr('تضخيم / زيادة وزن', 'Bulk / gain weight'),
      _ => g,
    };

String dietGoalEmoji(String g) => switch (g) {
      'deficit' => '📉',
      'maintain' => '⚖️',
      'surplus' => '📈',
      _ => '🍽',
    };

/// أنظمة غذائية جاهزة يختار منها المستخدم.
const List<DietPlan> kDietPlans = [
  DietPlan(
    id: 'balanced',
    ar: 'متوازن',
    en: 'Balanced',
    descAr: 'نظام صحي متوازن للحفاظ على وزنك وطاقتك — مناسب لأغلب الناس.',
    descEn: 'A balanced healthy plan to maintain weight and energy — fits most people.',
    goal: 'maintain',
    calorieDelta: 0,
    proteinPct: 30,
    carbsPct: 40,
    fatPct: 30,
    sampleDayAr: [
      'فطار: بيض + عيش سن + خضار',
      'غدا: صدور فراخ + رز + سلطة',
      'عشا: زبادي + فاكهة + مكسرات',
    ],
    sampleDayEn: [
      'Breakfast: eggs + whole-wheat bread + veg',
      'Lunch: chicken breast + rice + salad',
      'Dinner: yogurt + fruit + nuts',
    ],
  ),
  DietPlan(
    id: 'cutting',
    ar: 'تنشيف (عجز سعرات)',
    en: 'Cutting (deficit)',
    descAr: 'عجز ٥٠٠ سعرة لخسارة دهون تدريجية مع بروتين عالي يحافظ على العضل.',
    descEn: '500-kcal deficit for gradual fat loss with high protein to keep muscle.',
    goal: 'deficit',
    calorieDelta: -500,
    proteinPct: 40,
    carbsPct: 35,
    fatPct: 25,
    sampleDayAr: [
      'فطار: بيض مسلوق + جبنة قريش',
      'غدا: سمك/فراخ مشوي + سلطة كبيرة',
      'عشا: زبادي يوناني + خضار',
    ],
    sampleDayEn: [
      'Breakfast: boiled eggs + cottage cheese',
      'Lunch: grilled fish/chicken + big salad',
      'Dinner: Greek yogurt + veg',
    ],
  ),
  DietPlan(
    id: 'bulking',
    ar: 'تضخيم (فائض سعرات)',
    en: 'Bulking (surplus)',
    descAr: 'فائض ٤٠٠ سعرة وكارب أعلى لبناء العضل مع التمرين بالأوزان.',
    descEn: '400-kcal surplus and higher carbs to build muscle with resistance training.',
    goal: 'surplus',
    calorieDelta: 400,
    proteinPct: 30,
    carbsPct: 50,
    fatPct: 20,
    sampleDayAr: [
      'فطار: شوفان + لبن + موز + زبدة فول سوداني',
      'غدا: لحمة/فراخ + رز + خضار',
      'عشا: بيض + عيش + بروتين واي',
    ],
    sampleDayEn: [
      'Breakfast: oats + milk + banana + peanut butter',
      'Lunch: beef/chicken + rice + veg',
      'Dinner: eggs + bread + whey protein',
    ],
  ),
  DietPlan(
    id: 'high_protein',
    ar: 'عالي البروتين',
    en: 'High protein',
    descAr: 'بروتين مرتفع للشبع وبناء العضل مع سعرات ثابتة.',
    descEn: 'High protein for satiety and muscle building at maintenance calories.',
    goal: 'maintain',
    calorieDelta: 0,
    proteinPct: 40,
    carbsPct: 35,
    fatPct: 25,
    sampleDayAr: [
      'فطار: بيض + جبنة قريش + شوفان',
      'غدا: صدور فراخ + عدس + سلطة',
      'عشا: تونة + زبادي يوناني',
    ],
    sampleDayEn: [
      'Breakfast: eggs + cottage cheese + oats',
      'Lunch: chicken breast + lentils + salad',
      'Dinner: tuna + Greek yogurt',
    ],
  ),
  DietPlan(
    id: 'low_carb',
    ar: 'قليل الكارب',
    en: 'Low carb',
    descAr: 'كارب منخفض ودهون صحية أعلى — كويس للتحكم في السكر والشبع.',
    descEn: 'Low carbs with higher healthy fats — good for blood-sugar control and satiety.',
    goal: 'deficit',
    calorieDelta: -300,
    proteinPct: 35,
    carbsPct: 15,
    fatPct: 50,
    sampleDayAr: [
      'فطار: بيض بالسمنة + أفوكادو',
      'غدا: لحمة/سمك + خضار ورقي + زيت زيتون',
      'عشا: جبنة + مكسرات',
    ],
    sampleDayEn: [
      'Breakfast: eggs in ghee + avocado',
      'Lunch: meat/fish + leafy veg + olive oil',
      'Dinner: cheese + nuts',
    ],
  ),
  DietPlan(
    id: 'fasting_16_8',
    ar: 'صيام متقطّع (16:8)',
    en: 'Intermittent fasting (16:8)',
    descAr: 'تأكل في نافذة ٨ ساعات وتصوم ١٦ — بعجز خفيف لخسارة الدهون.',
    descEn: 'Eat within an 8-hour window, fast for 16 — slight deficit for fat loss.',
    goal: 'deficit',
    calorieDelta: -400,
    proteinPct: 30,
    carbsPct: 40,
    fatPct: 30,
    fasting: true,
    sampleDayAr: [
      '١٢ ظهرًا: فراخ + رز + سلطة',
      '٤ عصرًا: زبادي + فاكهة + مكسرات',
      '٨ مساءً: بيض + خضار (آخر وجبة)',
    ],
    sampleDayEn: [
      '12pm: chicken + rice + salad',
      '4pm: yogurt + fruit + nuts',
      '8pm: eggs + veg (last meal)',
    ],
  ),
];

DietPlan? dietPlanById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final p in kDietPlans) {
    if (p.id == id) return p;
  }
  return null;
}
