import '../core/db.dart';

/// ملاحظة حرّة فى بند «تذكيراتى».
class Note {
  final int? id;
  final String text;
  final bool pinned;
  final String createdAt;
  final String updatedAt;

  const Note({
    this.id,
    required this.text,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromMap(Map<String, Object?> m) => Note(
        id: m['id'] as int?,
        text: m['text'] as String? ?? '',
        pinned: ((m['pinned'] as int?) ?? 0) == 1,
        createdAt: m['created_at'] as String? ?? '',
        updatedAt: m['updated_at'] as String? ?? '',
      );
}

/// تخزين ملاحظات «تذكيراتى» — المثبّت فوق، ثم الأحدث تعديلًا.
class NotesRepo {
  Future<List<Note>> all({String? search}) async {
    final db = await AppDb.instance;
    final rows = await db.query(
      'notes',
      where: (search != null && search.trim().isNotEmpty) ? 'text LIKE ?' : null,
      whereArgs: (search != null && search.trim().isNotEmpty)
          ? ['%${search.trim()}%']
          : null,
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> byId(int id) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('notes', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Future<int> count() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery('SELECT COUNT(*) c FROM notes');
    return (r.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<int> add(String text) async {
    final db = await AppDb.instance;
    final now = DateTime.now().toIso8601String();
    return db.insert('notes', {
      'text': text.trim(),
      'pinned': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(int id, String text) async {
    final db = await AppDb.instance;
    await db.update(
        'notes',
        {'text': text.trim(), 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> setPinned(int id, bool pinned) async {
    final db = await AppDb.instance;
    await db.update('notes', {'pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
