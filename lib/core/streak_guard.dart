import '../data/habits_repo.dart';
import '../models/models.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

/// حماية السلاسل: لو فيه عادة سلسلتها ≥ ٧ أيام ولسه ماتعملتش النهارده،
/// تنبيه واحد الساعة ٩ مساءً. بيتلغى ويتعاد حسابه مع كل فتحة وكل تبديل عادة.
class StreakGuard {
  static const int minStreak = 7;
  static const int hour = 21;

  /// دالة نقية للاختبار: العادات المعرضة للكسر.
  static List<String> atRisk({
    required List<Habit> habits,
    required Map<int, int> streaks,
    required Set<int> doneToday,
  }) =>
      [
        for (final h in habits)
          if ((streaks[h.id] ?? 0) >= minStreak && !doneToday.contains(h.id))
            h.name
      ];

  static Future<void> ensureScheduled() async {
    await Notifications.cancel(Notifications.streakNotifId);
    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day, hour);
    if (at.isBefore(now)) return; // فات معاد الليلة

    final repo = HabitsRepo();
    final habits = await repo.active();
    if (habits.isEmpty) return;
    final doneToday = await repo.doneOn(dayKey(now));
    final streaks = <int, int>{};
    for (final h in habits) {
      streaks[h.id!] = computeStreak(await repo.daysFor(h.id!), now);
    }
    final risky =
        atRisk(habits: habits, streaks: streaks, doneToday: doneToday);
    if (risky.isEmpty) return;

    final first = risky.first;
    final streak = streaks[habits.firstWhere((h) => h.name == first).id]!;
    await Notifications.scheduleOnce(
      id: Notifications.streakNotifId,
      title: tr('سلسلتك في خطر!', 'Your streak is at risk!'),
      body: risky.length == 1
          ? tr(
              '«$first» (${arNum(streak)} يوم متواصل) لسه ماتعملتش النهارده — لسه فيه وقت',
              '"$first" (${arNum(streak)} days in a row) not done today yet — there\'s still time')
          : tr(
              '${arNum(risky.length)} عادات بسلاسل طويلة لسه ماتعملتش النهارده — أهمها «$first»',
              '${arNum(risky.length)} habits with long streaks not done today — top one: "$first"'),
      when: at,
    );
  }
}
