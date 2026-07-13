import '../core/db.dart';
import '../models/models.dart';

/// التعلّم — كورسات/دورات بتتبّع تقدّم بالوحدات (دروس/محاضرات).
class CoursesRepo {
  Future<List<Course>> all() async {
    final db = await AppDb.instance;
    // النشطة أولاً، ثم المتوقّفة، ثم المكتملة.
    final rows = await db.query('courses',
        orderBy: "CASE status WHEN 'active' THEN 0 "
            "WHEN 'paused' THEN 1 ELSE 2 END, id DESC");
    return rows.map(Course.fromMap).toList();
  }

  Future<int> save(Course c) async {
    final db = await AppDb.instance;
    if (c.id == null) return db.insert('courses', c.toMap());
    await db.update('courses', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    return c.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  /// يزوّد/يقلّل الوحدات المنجزة، ويعلّم «مكتمل» لو وصلت الإجمالى.
  Future<void> bumpProgress(Course c, int delta) async {
    final db = await AppDb.instance;
    final done = (c.doneUnits + delta).clamp(0, c.totalUnits == 0 ? 999999 : c.totalUnits);
    final status = (c.totalUnits > 0 && done >= c.totalUnits) ? 'done' : c.status == 'done' ? 'active' : c.status;
    await db.update('courses', {'done_units': done, 'status': status},
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> setStatus(int id, String status) async {
    final db = await AppDb.instance;
    await db.update('courses', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }
}
