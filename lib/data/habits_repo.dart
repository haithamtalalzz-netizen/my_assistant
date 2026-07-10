import '../core/ar.dart';
import '../core/db.dart';
import '../core/streak_guard.dart';
import '../models/models.dart';

/// حساب سلسلة الإنجاز: يمشي لورا من النهارده، وعنده "يوم رحمة" واحد
/// كل ٧ أيام — يوم واحد فايت مايكسرش السلسلة لكن مايتحسبش فيها.
/// النهارده لو لسه ماتعملش مايكسرش السلسلة برضه.
int computeStreak(Set<String> doneDays, DateTime today) {
  var streak = 0;
  var mercy = 1;
  var scanned = 0;
  var d = dateOnly(today);
  if (!doneDays.contains(dayKey(d))) {
    d = d.subtract(const Duration(days: 1));
  }
  while (scanned < 3660) {
    if (doneDays.contains(dayKey(d))) {
      streak++;
    } else if (mercy > 0) {
      mercy--;
    } else {
      break;
    }
    scanned++;
    if (scanned % 7 == 0) mercy = 1;
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

class HabitsRepo {
  Future<List<Habit>> active() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('habits', where: 'archived = 0', orderBy: 'id');
    return rows.map(Habit.fromMap).toList();
  }

  Future<int> add(String name) async {
    final db = await AppDb.instance;
    return db.insert('habits',
        Habit(name: name, createdAt: dayKey(DateTime.now())).toMap());
  }

  Future<void> archive(int id) async {
    final db = await AppDb.instance;
    await db.update('habits', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
  }

  /// آخر أيام إنجاز للعادة كمفاتيح YYYY-MM-DD.
  Future<Set<String>> daysFor(int habitId, {int limit = 400}) async {
    final db = await AppDb.instance;
    final rows = await db.query('habit_logs',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        orderBy: 'day DESC',
        limit: limit);
    return rows.map((r) => r['day'] as String).toSet();
  }

  /// العادات المتعملة في يوم معين.
  Future<Set<int>> doneOn(String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('habit_logs', where: 'day = ?', whereArgs: [day]);
    return rows.map((r) => r['habit_id'] as int).toSet();
  }

  /// يقلب حالة اليوم ويرجع الحالة الجديدة — وبيعيد حساب تنبيه حماية السلاسل.
  Future<bool> toggle(int habitId, String day) async {
    final db = await AppDb.instance;
    final deleted = await db.delete('habit_logs',
        where: 'habit_id = ? AND day = ?', whereArgs: [habitId, day]);
    final bool result;
    if (deleted > 0) {
      result = false;
    } else {
      await db.insert('habit_logs', {'habit_id': habitId, 'day': day});
      result = true;
    }
    await StreakGuard.ensureScheduled();
    return result;
  }
}
