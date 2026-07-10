import '../core/db.dart';
import '../models/models.dart';

class SecretNotesRepo {
  Future<int> save(SecretNote n) async {
    final db = await AppDb.instance;
    if (n.id == null) return db.insert('secret_notes', n.toMap());
    await db.update('secret_notes', n.toMap(),
        where: 'id = ?', whereArgs: [n.id]);
    return n.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('secret_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SecretNote>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('secret_notes', orderBy: 'id DESC');
    return rows.map(SecretNote.fromMap).toList();
  }
}
