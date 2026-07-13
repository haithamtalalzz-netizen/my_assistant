import '../core/db.dart';
import '../models/models.dart';

/// مفكرة الأعراض — سجل يومى للأعراض (بيغذّى تقرير الدكتور).
class SymptomsRepo {
  Future<List<SymptomLog>> recent({int limit = 200}) async {
    final db = await AppDb.instance;
    final rows = await db.query('symptom_logs',
        orderBy: 'day DESC, id DESC', limit: limit);
    return rows.map(SymptomLog.fromMap).toList();
  }

  /// الأعراض من تاريخ معيّن (لتقرير الدكتور).
  Future<List<SymptomLog>> since(String dayKeyFrom) async {
    final db = await AppDb.instance;
    final rows = await db.query('symptom_logs',
        where: 'day >= ?', whereArgs: [dayKeyFrom], orderBy: 'day, id');
    return rows.map(SymptomLog.fromMap).toList();
  }

  Future<int> save(SymptomLog s) async {
    final db = await AppDb.instance;
    if (s.id == null) return db.insert('symptom_logs', s.toMap());
    await db.update('symptom_logs', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('symptom_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// أكثر الأعراض تكرارًا (للاتجاهات).
  Future<List<({String symptom, int count})>> topSymptoms({int limit = 5}) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT symptom, COUNT(*) c FROM symptom_logs '
        'GROUP BY symptom ORDER BY c DESC LIMIT ?',
        [limit]);
    return [
      for (final r in rows)
        (symptom: r['symptom'] as String, count: r['c'] as int)
    ];
  }
}
