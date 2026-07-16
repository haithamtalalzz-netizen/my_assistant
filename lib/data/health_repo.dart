import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../models/models.dart';

class HealthRepo {
  /// الكوباية الافتراضية = ٢٥٠ مل (للتوافق مع البيانات القديمة والدوال بالأكواب).
  static const int cupMl = 250;

  /// المياه بالملى ليوم — بيرجّع عمود `ml`، ولو صفر وفيه أكواب قديمة (glasses)
  /// بيحوّلها (× ٢٥٠) عشان البيانات القديمة ماتضيعش.
  Future<int> waterMlOn(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('water_logs', where: 'day = ?', whereArgs: [day]);
    if (rows.isEmpty) return 0;
    final ml = (rows.first['ml'] as int? ?? 0);
    if (ml > 0) return ml;
    final glasses = (rows.first['glasses'] as int? ?? 0);
    return glasses * cupMl;
  }

  /// يزود/يقلل المياه بالملى ويرجّع الإجمالى الجديد.
  Future<int> addWaterMl(String day, int deltaMl) async {
    final next = (await waterMlOn(day) + deltaMl).clamp(0, 20000);
    return setWaterMl(day, next);
  }

  /// يحدّد المياه بالملى لليوم مباشرة.
  Future<int> setWaterMl(String day, int ml) async {
    final db = await AppDb.instance;
    final v = ml.clamp(0, 20000);
    // نحدّث الأكواب كمان (round) عشان الدوال القديمة تفضل شغّالة.
    await db.insert('water_logs',
        {'day': day, 'ml': v, 'glasses': (v / cupMl).round()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return v;
  }

  /// عدد الأكواب (توافق) = المياه بالملى ÷ ٢٥٠.
  Future<int> waterOn(String day) async =>
      (await waterMlOn(day) / cupMl).round();

  /// يزود/يقلل بالأكواب (توافق) — بيحوّلها لملى.
  Future<int> addWater(String day, int delta) async =>
      (await addWaterMl(day, delta * cupMl) / cupMl).round();

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
