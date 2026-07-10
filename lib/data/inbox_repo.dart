import '../core/db.dart';
import '../models/models.dart';

/// صندوق الوارد السريع: أي فكرة تترمى هنا وتتصنف بعدين.
class InboxRepo {
  Future<List<InboxNote>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('inbox_notes', orderBy: 'id DESC');
    return rows.map(InboxNote.fromMap).toList();
  }

  Future<int> count() async {
    final db = await AppDb.instance;
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM inbox_notes');
    return rows.first['c'] as int;
  }

  Future<int> add(String text) async {
    final db = await AppDb.instance;
    return db.insert('inbox_notes', InboxNote(
      text: text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    ).toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('inbox_notes', where: 'id = ?', whereArgs: [id]);
  }
}
