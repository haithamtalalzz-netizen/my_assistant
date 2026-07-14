import 'package:sqflite/sqflite.dart';

import 'ar.dart';
import 'db.dart';
import 'l10n.dart';

/// سطر فى المراجعة السنوية.
class YearStat {
  final String emoji;
  final String label;
  final String value;
  const YearStat(this.emoji, this.label, this.value);
}

/// يجمّع ملخّص السنة عبر كل البنود (فلوس/مهام/صحة/عبادة/قراءة…).
Future<List<YearStat>> collectYearReview(int year) async {
  final db = await AppDb.instance;
  final yp = '$year%';

  Future<double> sum(String table, String col, String dayCol) async {
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM($col),0) t FROM $table WHERE $dayCol LIKE ?', [yp]);
    return (r.first['t'] as num).toDouble();
  }

  Future<int> count(String sql) async =>
      Sqflite.firstIntValue(await db.rawQuery(sql, [yp])) ?? 0;

  final spent = await sum('expenses', 'amount', 'day');
  final income = await sum('income', 'amount', 'day');
  final tasksDone =
      await count("SELECT COUNT(*) FROM tasks WHERE done = 1 AND done_at LIKE ?");
  final workouts = await count('SELECT COUNT(*) FROM gym_sessions WHERE day LIKE ?');
  final fullPrayerDays = await count(
      'SELECT COUNT(*) FROM (SELECT day FROM prayer_log WHERE day LIKE ? '
      'GROUP BY day HAVING COUNT(*) >= 5)');
  final habitDone = await count('SELECT COUNT(*) FROM habit_logs WHERE day LIKE ?');
  final gratitudeDays =
      await count('SELECT COUNT(DISTINCT day) FROM gratitude WHERE day LIKE ?');
  final meals = await count('SELECT COUNT(*) FROM meals WHERE day LIKE ?');
  final waterCups = (await sum('water_logs', 'glasses', 'day')).round();
  final booksDone = Sqflite.firstIntValue(await db
          .rawQuery("SELECT COUNT(*) FROM books WHERE status = 'done'")) ??
      0;
  final net = income - spent;

  return [
    YearStat('💰', tr('صرفت', 'Spent'), egp(spent)),
    YearStat('📈', tr('دخلك', 'Income'), egp(income)),
    YearStat('⚖️', tr('صافى (وفّرت)', 'Net saved'), egp(net)),
    YearStat('✅', tr('مهام خلّصتها', 'Tasks done'), arNum(tasksDone)),
    YearStat('🏋️', tr('تمارين', 'Workouts'), arNum(workouts)),
    YearStat('🕌', tr('أيام صلّيت فيها الخمس', 'Full-prayer days'),
        arNum(fullPrayerDays)),
    YearStat('🔁', tr('مرات علّمت عادة', 'Habit check-ins'), arNum(habitDone)),
    YearStat('🙏', tr('أيام امتنان', 'Gratitude days'), arNum(gratitudeDays)),
    YearStat('📚', tr('كتب خلّصتها', 'Books finished'), arNum(booksDone)),
    YearStat('🍽', tr('وجبات سجّلتها', 'Meals logged'), arNum(meals)),
    YearStat('💧', tr('كوبايات مياه', 'Water cups'), arNum(waterCups)),
  ];
}
