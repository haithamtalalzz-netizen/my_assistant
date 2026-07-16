import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';

/// ميزان السعرات: أكل آخر ٧ أيام المتسجّل مقابل هدف السعرات، ومعدل تغيّر
/// الوزن الفعلى من القياسات — كله أرقام محسوبة من بيانات المستخدم نفسه،
/// مفيش أى تقدير مخترع. طبقة core من غير ودجت عشان تتختبر.
class KcalBalance {
  /// آخر ٧ أيام (الأقدم الأول): (مفتاح اليوم، سعرات الوجبات المتسجّلة).
  final List<(String, double)> days;

  /// هدف السعرات اليومى (٠ = مش محدد).
  final int goal;

  /// معدل تغيّر الوزن كجم/أسبوع من القياسات الفعلية (null = أقل من قياسين).
  final double? weightWeeklyRate;

  const KcalBalance({
    required this.days,
    required this.goal,
    required this.weightWeeklyRate,
  });

  /// الأيام اللى فيها وجبات متسجّلة فعلًا (يوم من غير تسجيل مش «صفر أكل»).
  List<(String, double)> get loggedDays =>
      [for (final d in days) if (d.$2 > 0) d];

  double get avgIntake {
    final logged = loggedDays;
    if (logged.isEmpty) return 0;
    return logged.fold<double>(0, (s, d) => s + d.$2) / logged.length;
  }

  /// متوسط الفرق عن الهدف فى اليوم (سالب = عجز). null لو مفيش هدف أو تسجيل.
  double? get dailyBalance =>
      goal <= 0 || loggedDays.isEmpty ? null : avgIntake - goal;
}

Future<KcalBalance> collectKcalBalance([DateTime? at]) async {
  final now = at ?? DateTime.now();
  final meals = MealsRepo();
  final days = <(String, double)>[];
  for (var i = 6; i >= 0; i--) {
    final key = dayKey(now.subtract(Duration(days: i)));
    final n = await meals.dayNutrients(key);
    days.add((key, n.kcal));
  }

  final goal = await SettingsRepo().calorieGoal();

  // معدل الوزن: أول وآخر قياس فى آخر ٦٠ قياس — لازم يفصل بينهم ٣ أيام
  // على الأقل عشان المعدل يبقى له معنى.
  double? rate;
  final weights =
      (await MeasurementsRepo().recent(limit: 60, type: 'وزن'))
          .reversed
          .toList();
  if (weights.length >= 2) {
    final first = weights.first;
    final last = weights.last;
    final d1 = DateTime.tryParse(first.day);
    final d2 = DateTime.tryParse(last.day);
    if (d1 != null && d2 != null) {
      final spanDays = d2.difference(d1).inDays;
      if (spanDays >= 3) {
        rate = (last.value - first.value) / spanDays * 7;
      }
    }
  }

  return KcalBalance(days: days, goal: goal, weightWeeklyRate: rate);
}
