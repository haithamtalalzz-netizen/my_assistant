import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kMedicalTypes = ['visit', 'lab', 'imaging', 'procedure'];

/// عرض نوع السجل الطبي.
String medicalTypeLabel(String t) => switch (t) {
      'visit' => tr('زيارة', 'Visit'),
      'lab' => tr('تحاليل', 'Lab test'),
      'imaging' => tr('أشعة', 'Imaging'),
      'procedure' => tr('إجراء', 'Procedure'),
      _ => t,
    };

class MedicalRepo {
  Future<int> save(MedicalRecord r) async {
    final db = await AppDb.instance;
    if (r.id == null) {
      return db.insert('medical_records', r.toMap());
    }
    await db.update('medical_records', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
    return r.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('medical_records', where: 'id = ?', whereArgs: [id]);
  }

  /// كل السجلات (أو نوع واحد) — الأحدث أولًا.
  Future<List<MedicalRecord>> all({String? type}) async {
    final db = await AppDb.instance;
    final rows = await db.query('medical_records',
        where: type == null ? null : 'type = ?',
        whereArgs: type == null ? null : [type],
        orderBy: 'day DESC, id DESC');
    return rows.map(MedicalRecord.fromMap).toList();
  }

  /// السجلات من تاريخ معين — لتقرير الدكتور.
  Future<List<MedicalRecord>> since(String dayKeyFrom) async {
    final db = await AppDb.instance;
    final rows = await db.query('medical_records',
        where: 'day >= ?', whereArgs: [dayKeyFrom], orderBy: 'day DESC');
    return rows.map(MedicalRecord.fromMap).toList();
  }
}
