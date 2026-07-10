import '../core/ar.dart';
import '../core/db.dart';
import '../core/insights.dart';
import 'habits_repo.dart';
import 'measurements_repo.dart';
import 'money_repo.dart';

/// بيجمع بيانات آخر [windowDays] يوم من كل الجداول ويحضرها لمحرك الرؤى.
class InsightsRepo {
  static const int windowDays = 60;

  Future<InsightData> assemble({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final db = await AppDb.instance;
    final today = dateOnly(current);
    final from = today.subtract(const Duration(days: windowDays - 1));
    final fromKey = dayKey(from);

    // قراءات جماعية لكل جدول — استعلام واحد لكل نوع.
    final sleepRows = await db.query('sleep_logs',
        where: 'day >= ?', whereArgs: [fromKey]);
    final sleepBy = {
      for (final r in sleepRows)
        r['day'] as String: (r['hours'] as num).toDouble()
    };
    final waterRows = await db.query('water_logs',
        where: 'day >= ?', whereArgs: [fromKey]);
    final waterBy = {
      for (final r in waterRows) r['day'] as String: r['glasses'] as int
    };
    final spendRows = await db.rawQuery(
        'SELECT day, SUM(amount) AS total FROM expenses WHERE day >= ? GROUP BY day',
        [fromKey]);
    final spendBy = {
      for (final r in spendRows)
        r['day'] as String: (r['total'] as num).toDouble()
    };
    final workoutRows = await db.query('workout_logs',
        where: 'day >= ?', whereArgs: [fromKey]);
    final workoutDays = {for (final r in workoutRows) r['day'] as String};
    final measurementsRepo = MeasurementsRepo();
    final stepsBy = await measurementsRepo.stepsSince(fromKey);
    final fitnessBy = await measurementsRepo.fitnessSince(fromKey);

    // العادات: عدد النشطة + إنجازات كل يوم.
    final habits = await HabitsRepo().active();
    final habitLogRows = await db.query('habit_logs',
        where: 'day >= ?', whereArgs: [fromKey]);
    final habitDoneCount = <String, int>{};
    final habitDoneByHabit = <int, int>{};
    for (final r in habitLogRows) {
      final day = r['day'] as String;
      habitDoneCount[day] = (habitDoneCount[day] ?? 0) + 1;
      final id = r['habit_id'] as int;
      habitDoneByHabit[id] = (habitDoneByHabit[id] ?? 0) + 1;
    }

    final days = <DailyMetrics>[];
    for (var i = 0; i < windowDays; i++) {
      final d = from.add(Duration(days: i));
      final key = dayKey(d);
      final fit = fitnessBy[key];
      days.add(DailyMetrics(
        day: key,
        sleep: sleepBy[key],
        water: waterBy[key] ?? 0,
        spend: spendBy[key] ?? 0,
        habitRatio: habits.isEmpty
            ? null
            : (habitDoneCount[key] ?? 0) / habits.length,
        workout: workoutDays.contains(key),
        steps: stepsBy[key],
        calories: fit?.calories,
        distanceKm: fit?.distanceKm,
      ));
    }

    // فئات الشهر الحالي والسابق.
    final money = MoneyRepo();
    final monthCat = await money.byCategory(current.year, current.month);
    final prevMonth = DateTime(current.year, current.month - 1);
    final prevCat = await money.byCategory(prevMonth.year, prevMonth.month);

    // سلاسل العادات + نسبة الالتزام آخر ٣٠ يوم.
    final habitsRepo = HabitsRepo();
    final streaks = <String, int>{};
    final completion = <String, double>{};
    final last30From = today.subtract(const Duration(days: 29));
    for (final h in habits) {
      final done = await habitsRepo.daysFor(h.id!);
      streaks[h.name] = computeStreak(done, current);
      // نسبة الالتزام بتتحسب من يوم إنشاء العادة لو أحدث من ٣٠ يوم.
      final created = DateTime.tryParse(h.createdAt) ?? last30From;
      final start = created.isAfter(last30From) ? created : last30From;
      final span = today.difference(dateOnly(start)).inDays + 1;
      if (span < 7) continue;
      var count = 0;
      for (var i = 0; i < span; i++) {
        if (done.contains(dayKey(start.add(Duration(days: i))))) count++;
      }
      completion[h.name] = count / span;
    }

    return InsightData(
      days: days,
      monthByCategory: monthCat,
      prevMonthByCategory: prevCat,
      habitStreaks: streaks,
      habitCompletion: completion,
    );
  }
}
