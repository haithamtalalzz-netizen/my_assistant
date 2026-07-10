import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import 'settings_repo.dart';

class WorkoutRepo {
  /// الخطة: weekday (1=الإثنين .. 7=الأحد بترقيم Dart) → اسم التمرين.
  Future<Map<int, String>> plan() async {
    final db = await AppDb.instance;
    final rows = await db.query('workout_plan');
    return {
      for (final r in rows) r['weekday'] as int: r['title'] as String,
    };
  }

  /// يحفظ الخطة كاملة ويعيد جدولة تذكيرات أيام التمرين.
  Future<void> savePlan(Map<int, String> plan) async {
    final db = await AppDb.instance;
    await db.delete('workout_plan');
    for (final e in plan.entries) {
      if (e.value.trim().isEmpty) continue;
      await db.insert('workout_plan',
          {'weekday': e.key, 'title': e.value.trim()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await rescheduleReminders();
  }

  Future<bool> doneOn(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('workout_logs', where: 'day = ?', whereArgs: [day]);
    return rows.isNotEmpty;
  }

  Future<void> setDone(String day, bool done, {String title = ''}) async {
    final db = await AppDb.instance;
    if (done) {
      await db.insert('workout_logs', {'day': day, 'title': title},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('workout_logs', where: 'day = ?', whereArgs: [day]);
    }
  }

  /// اقتراح إعادة الجدولة: تمرين امبارح كان مخطط ومتعملش،
  /// والنهارده مفيش تمرين مخطط أصلًا.
  Future<String?> missedYesterdaySuggestion(DateTime now) async {
    final yesterday = dateOnly(now).subtract(const Duration(days: 1));
    final currentPlan = await plan();
    final plannedYesterday = currentPlan[yesterday.weekday];
    if (plannedYesterday == null) return null;
    if (await doneOn(dayKey(yesterday))) return null;
    if (currentPlan[now.weekday] != null) return null;
    return plannedYesterday;
  }

  Future<void> rescheduleReminders() async {
    for (var d = 1; d <= 7; d++) {
      await Notifications.cancel(Notifications.workoutNotifId(d));
    }
    final currentPlan = await plan();
    if (currentPlan.isEmpty) return;
    final time = await SettingsRepo().get('workout_time') ?? '18:00';
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 18;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    for (final e in currentPlan.entries) {
      await Notifications.scheduleWeekly(
        id: Notifications.workoutNotifId(e.key),
        title: tr('وقت التمرين', 'Workout time'),
        body: tr('النهارده: ${e.value}', 'Today: ${e.value}'),
        weekday: e.key,
        hour: hour,
        minute: minute,
      );
    }
  }
}
