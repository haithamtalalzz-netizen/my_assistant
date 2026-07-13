import 'package:sqflite/sqflite.dart';

import '../core/db.dart';

class QuranBookmark {
  final int id;
  final int page;
  final String label;
  const QuranBookmark(this.id, this.page, this.label);
}

/// علامات المصحف المرجعية + الصفحات المقروءة (مؤشّر التقدّم).
class MushafRepo {
  Future<List<QuranBookmark>> bookmarks() async {
    final db = await AppDb.instance;
    final rows = await db.query('quran_bookmarks', orderBy: 'page ASC');
    return rows
        .map((r) => QuranBookmark(
            r['id'] as int, r['page'] as int, r['label'] as String))
        .toList();
  }

  Future<void> addBookmark(int page, String label) async {
    final db = await AppDb.instance;
    await db.insert('quran_bookmarks', {
      'page': page,
      'label': label,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteBookmark(int id) async {
    final db = await AppDb.instance;
    await db.delete('quran_bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // ---- الصفحات المقروءة ----

  Future<void> markRead(int page) async {
    final db = await AppDb.instance;
    await db.insert('quran_read_pages', {'page': page},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> readCount() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery('SELECT COUNT(*) c FROM quran_read_pages');
    return (rows.first['c'] as int?) ?? 0;
  }
}
