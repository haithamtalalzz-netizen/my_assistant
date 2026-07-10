import 'package:sqflite/sqflite.dart';

import '../core/db.dart';

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
}
