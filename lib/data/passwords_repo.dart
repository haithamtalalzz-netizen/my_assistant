import '../core/db.dart';
import '../models/models.dart';

/// كلمات السر — الوصول محمى بالبصمة على مستوى الشاشة؛ مخزّنة محليًا فى قاعدة
/// البيانات (زى الخزنة السرية — قفل وصول، مش تشفير).
class PasswordsRepo {
  Future<List<PasswordEntry>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('passwords', orderBy: 'label');
    return rows.map(PasswordEntry.fromMap).toList();
  }

  Future<int> save(PasswordEntry e) async {
    final db = await AppDb.instance;
    if (e.id == null) return db.insert('passwords', e.toMap());
    await db.update('passwords', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
    return e.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
  }
}
