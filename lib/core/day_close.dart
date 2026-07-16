import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/meds_repo.dart';
import '../data/money_repo.dart';
import '../data/meals_repo.dart';
import '../data/settings_repo.dart';
import '../data/worship_repo.dart';
import '../models/models.dart';
import 'ar.dart';

/// حالة «قفل اليوم»: كل الناقص من النهارده فى مكان واحد — طبقة core من غير
/// ودجت عشان تتختبر (نفس نمط collectAttention/collectDashboard).
class DayCloseStatus {
  /// أرقام الصلوات اللى لسه ماتسجّلتش (٠=فجر .. ٤=عشا).
  final List<int> missedPrayers;
  final int waterMl;
  final int waterGoalMl;

  /// العادات النشطة اللى لسه ماتعملتش النهارده.
  final List<Habit> pendingHabits;

  /// جرعات الدوا المتوقّعة والمتسجّلة.
  final int expectedDoses;
  final int takenDoses;

  /// مصروف النهارده (للمراجعة، مش «ناقص»).
  final double todaySpend;

  /// سعرات وجبات النهارده.
  final double mealKcal;

  const DayCloseStatus({
    required this.missedPrayers,
    required this.waterMl,
    required this.waterGoalMl,
    required this.pendingHabits,
    required this.expectedDoses,
    required this.takenDoses,
    required this.todaySpend,
    required this.mealKcal,
  });

  int get remainingWaterMl =>
      (waterGoalMl - waterMl) < 0 ? 0 : waterGoalMl - waterMl;
  int get missedDoses =>
      (expectedDoses - takenDoses) < 0 ? 0 : expectedDoses - takenDoses;

  /// عدد البنود الناقصة (اللى ينفع تتقفل بضغطة).
  int get pendingCount =>
      missedPrayers.length +
      pendingHabits.length +
      missedDoses +
      (remainingWaterMl > 0 ? 1 : 0);

  bool get allDone => pendingCount == 0;
}

/// بيجمع حالة اليوم — كل قسم بيفشل بيتحسب فاضى بدل ما يكسر الشاشة.
Future<DayCloseStatus> collectDayClose([DateTime? at]) async {
  final now = at ?? DateTime.now();
  final day = dayKey(now);

  final prayed = await WorshipRepo().prayedOn(now);
  final missedPrayers = [
    for (var i = 0; i < 5; i++)
      if (!prayed.contains(i)) i
  ];

  final waterMl = await HealthRepo().waterMlOn(day);
  final waterGoalMl = await SettingsRepo().waterGoalMl();

  final habits = await HabitsRepo().active();
  final doneHabits = await HabitsRepo().doneOn(day);
  final pendingHabits = [
    for (final h in habits)
      if (h.id != null && !doneHabits.contains(h.id)) h
  ];

  final meds = await MedsRepo().all(activeOnly: true);
  final expectedDoses = meds.fold<int>(0, (s, m) => s + m.times.length);
  final takenDoses = (await MedsRepo().takenOn(day)).length;

  final todaySpend = await MoneyRepo().totalForDay(day);
  final mealKcal = (await MealsRepo().dayNutrients(day)).kcal;

  return DayCloseStatus(
    missedPrayers: missedPrayers,
    waterMl: waterMl,
    waterGoalMl: waterGoalMl,
    pendingHabits: pendingHabits,
    expectedDoses: expectedDoses,
    takenDoses: takenDoses.clamp(0, expectedDoses),
    todaySpend: todaySpend,
    mealKcal: mealKcal,
  );
}
