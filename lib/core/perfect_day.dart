import 'package:sqflite/sqflite.dart';

import '../data/habits_repo.dart';
import '../data/settings_repo.dart';
import '../data/worship_repo.dart';
import '../models/models.dart';
import 'ar.dart';
import 'db.dart';

/// حالة «أنظمة» يوم واحد — الصلاة + العادات + المياه. اليوم «مثالي» لما تلاتتهم خُضر.
/// خالص من Flutter (قابل للاختبار). العادات تُقاس بالعادات النشطة **الحالية**
/// (تقريب مقبول لعدّاد تحفيزي — يوم قديم قبل ما تضيف عادة ممكن ما يُحسبش مثالي).
class DaySystems {
  final int prayers; // صلوات مسجّلة (0..5)
  final int habitsDone;
  final int habitsTotal;
  final int waterMl;
  final int waterGoalMl;

  const DaySystems({
    required this.prayers,
    required this.habitsDone,
    required this.habitsTotal,
    required this.waterMl,
    required this.waterGoalMl,
  });

  bool get prayersOk => prayers >= 5;
  // مفيش عادات نشطة = النظام ده مايسقّطش اليوم.
  bool get habitsOk => habitsTotal == 0 ? true : habitsDone >= habitsTotal;
  bool get waterOk => waterGoalMl > 0 && waterMl >= waterGoalMl;

  bool get isPerfect => prayersOk && habitsOk && waterOk;
}

Future<int> _waterMlOn(Database db, String dayK) async {
  final r = await db
      .rawQuery('SELECT ml FROM water_logs WHERE day = ?', [dayK]);
  return r.isNotEmpty ? (r.first['ml'] as int? ?? 0) : 0;
}

Future<DaySystems> _systemsForDay(
  DateTime day, {
  required Database db,
  required List<Habit> activeHabits,
  required int goalMl,
}) async {
  final dayK = dayKey(day);
  final prayed = await WorshipRepo().prayedOn(day);
  final done = await HabitsRepo().doneOn(dayK);
  final habitsDone =
      activeHabits.where((h) => h.id != null && done.contains(h.id)).length;
  return DaySystems(
    prayers: prayed.length,
    habitsDone: habitsDone,
    habitsTotal: activeHabits.length,
    waterMl: await _waterMlOn(db, dayK),
    waterGoalMl: goalMl,
  );
}

/// حالة أنظمة يوم معيّن (افتراضيًا النهاردة).
Future<DaySystems> systemsForDay(DateTime day, {Database? database}) async {
  final db = database ?? await AppDb.instance;
  return _systemsForDay(
    day,
    db: db,
    activeHabits: await HabitsRepo().active(),
    goalMl: await SettingsRepo().waterGoalMl(),
  );
}

/// عدد الأيام المثالية من أول الشهر الحالي لحد النهاردة.
Future<int> perfectDaysThisMonth({Database? database}) async {
  final db = database ?? await AppDb.instance;
  final active = await HabitsRepo().active();
  final goal = await SettingsRepo().waterGoalMl();
  final now = DateTime.now();
  var count = 0;
  for (var d = 1; d <= now.day; d++) {
    final s = await _systemsForDay(DateTime(now.year, now.month, d),
        db: db, activeHabits: active, goalMl: goal);
    if (s.isPerfect) count++;
  }
  return count;
}

/// أطول سلسلة أيام مثالية متتالية منتهية النهاردة (أو أمس لو النهاردة لسه).
Future<int> perfectStreak({Database? database}) async {
  final db = database ?? await AppDb.instance;
  final active = await HabitsRepo().active();
  final goal = await SettingsRepo().waterGoalMl();
  final now = DateTime.now();
  var streak = 0;
  for (var i = 0; i < 366; i++) {
    final s = await _systemsForDay(now.subtract(Duration(days: i)),
        db: db, activeHabits: active, goalMl: goal);
    if (s.isPerfect) {
      streak++;
    } else if (i == 0) {
      // النهاردة لسه مكملتش — ماتكسرش السلسلة، بُصّ لإمبارح.
      continue;
    } else {
      break;
    }
  }
  return streak;
}
