import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../models/models.dart';

const List<String> kMeasurementTypes = ['ضغط', 'سكر', 'وزن', 'حرارة'];

class MeasurementsRepo {
  Future<int> add(Measurement m) async {
    final db = await AppDb.instance;
    return db.insert('measurements', m.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> recent({int limit = 60, String? type}) async {
    final db = await AppDb.instance;
    final rows = await db.query('measurements',
        where: type == null ? null : 'type = ?',
        whereArgs: type == null ? null : [type],
        orderBy: 'day DESC, id DESC',
        limit: limit);
    return rows.map(Measurement.fromMap).toList();
  }

  /// القياسات من تاريخ معين — لتقرير الدكتور.
  Future<List<Measurement>> since(String dayKeyFrom) async {
    final db = await AppDb.instance;
    final rows = await db.query('measurements',
        where: 'day >= ?', whereArgs: [dayKeyFrom], orderBy: 'day, id');
    return rows.map(Measurement.fromMap).toList();
  }

  // ---- سجل الخطوات (بيتكتب تلقائيًا من Health Connect) ----

  Future<void> upsertSteps(String day, int steps) async {
    final db = await AppDb.instance;
    await db.insert('steps_logs', {'day': day, 'steps': steps},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, int>> stepsSince(String dayKeyFrom) async {
    final db = await AppDb.instance;
    final rows = await db.query('steps_logs',
        where: 'day >= ?', whereArgs: [dayKeyFrom]);
    return {
      for (final r in rows) r['day'] as String: r['steps'] as int,
    };
  }

  // ---- سجل اللياقة: سعرات ومسافة (بيتكتب تلقائيًا من الساعة الذكية) ----

  /// بيحدّث سعرات/مسافة اليوم. أي قيمة null بتفضل زي ما هي (COALESCE) عشان
  /// مانمسحش بيان موجود لو المقياس ده مش متاح في القراءة الحالية.
  Future<void> upsertFitness(String day,
      {int? calories, double? distanceKm}) async {
    if (calories == null && distanceKm == null) return;
    final db = await AppDb.instance;
    await db.rawInsert(
      '''
      INSERT INTO fitness_logs (day, calories, distance_km) VALUES (?, ?, ?)
      ON CONFLICT(day) DO UPDATE SET
        calories = COALESCE(excluded.calories, calories),
        distance_km = COALESCE(excluded.distance_km, distance_km)
      ''',
      [day, calories, distanceKm],
    );
  }

  /// سعرات ومسافة كل يوم من تاريخ معين — للرؤى وتقرير الدكتور.
  Future<Map<String, ({int? calories, double? distanceKm})>> fitnessSince(
      String dayKeyFrom) async {
    final db = await AppDb.instance;
    final rows = await db.query('fitness_logs',
        where: 'day >= ?', whereArgs: [dayKeyFrom]);
    return {
      for (final r in rows)
        r['day'] as String: (
          calories: (r['calories'] as num?)?.toInt(),
          distanceKm: (r['distance_km'] as num?)?.toDouble(),
        ),
    };
  }
}
