import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../models/models.dart';

class HealthRepo {
  Future<int> waterOn(String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('water_logs', where: 'day = ?', whereArgs: [day]);
    if (rows.isEmpty) return 0;
    return rows.first['glasses'] as int;
  }

  /// يزود/يقلل عداد المياه ويرجع القيمة الجديدة.
  Future<int> addWater(String day, int delta) async {
    final db = await AppDb.instance;
    final current = await waterOn(day);
    final next = (current + delta).clamp(0, 99);
    await db.insert('water_logs', {'day': day, 'glasses': next},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return next;
  }

  Future<double?> sleepOn(String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('sleep_logs', where: 'day = ?', whereArgs: [day]);
    if (rows.isEmpty) return null;
    return (rows.first['hours'] as num).toDouble();
  }

  Future<void> setSleep(String day, double hours) async {
    final db = await AppDb.instance;
    await db.insert('sleep_logs', {'day': day, 'hours': hours},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- تقويم/سجل الصحة ----

  /// أيام الشهر اللى فيها أى نشاط صحى (مياه/نوم/خطوات/قياسات/وجبات/لياقة).
  Future<Set<String>> activeDaysInMonth(int year, int month) async {
    final db = await AppDb.instance;
    final like =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-%';
    const tables = [
      'water_logs',
      'sleep_logs',
      'steps_logs',
      'measurements',
      'meals',
      'fitness_logs',
    ];
    final days = <String>{};
    for (final t in tables) {
      final rows = await db
          .rawQuery('SELECT DISTINCT day FROM $t WHERE day LIKE ?', [like]);
      for (final r in rows) {
        days.add(r['day'] as String);
      }
    }
    return days;
  }

  /// ملخّص صحّى ليوم واحد.
  Future<HealthDay> dayReport(String day) async {
    final db = await AppDb.instance;
    final water = await waterOn(day);
    final sleep = await sleepOn(day);
    final steps = Sqflite.firstIntValue(await db
            .rawQuery('SELECT steps FROM steps_logs WHERE day = ?', [day])) ??
        0;
    final calories = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COALESCE(CAST(SUM(calories) AS INTEGER),0) '
            'FROM meals WHERE day = ?',
            [day])) ??
        0;
    final meals = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM meals WHERE day = ?', [day])) ??
        0;
    final measurements =
        (await db.query('measurements', where: 'day = ?', whereArgs: [day]))
            .map(Measurement.fromMap)
            .toList();
    return HealthDay(
      water: water,
      sleep: sleep,
      steps: steps,
      calories: calories,
      meals: meals,
      measurements: measurements,
    );
  }
}

/// ملخّص صحّى ليوم واحد (للتقويم).
class HealthDay {
  final int water;
  final double? sleep;
  final int steps;
  final int calories;
  final int meals;
  final List<Measurement> measurements;
  const HealthDay({
    required this.water,
    required this.sleep,
    required this.steps,
    required this.calories,
    required this.meals,
    required this.measurements,
  });

  bool get hasAny =>
      water > 0 ||
      sleep != null ||
      steps > 0 ||
      calories > 0 ||
      meals > 0 ||
      measurements.isNotEmpty;
}
