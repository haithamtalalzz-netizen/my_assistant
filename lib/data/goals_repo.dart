import '../core/db.dart';
import '../models/models.dart';

/// الأهداف بمعالم (milestones) + نسبة الإنجاز من المعالم المكتملة.
class GoalsRepo {
  Future<List<Goal>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('goals', orderBy: 'done, id DESC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> save(Goal g) async {
    final db = await AppDb.instance;
    if (g.id == null) return db.insert('goals', g.toMap());
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
    return g.id!;
  }

  Future<void> setDone(int id, bool done) async {
    final db = await AppDb.instance;
    await db.update('goals', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('goal_milestones', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ---- المعالم ----

  Future<List<GoalMilestone>> milestones(int goalId) async {
    final db = await AppDb.instance;
    final rows = await db.query('goal_milestones',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'sort, id');
    return rows.map(GoalMilestone.fromMap).toList();
  }

  Future<int> addMilestone(int goalId, String title) async {
    final db = await AppDb.instance;
    final sort = (await milestones(goalId)).length;
    return db.insert('goal_milestones',
        GoalMilestone(goalId: goalId, title: title, sort: sort).toMap());
  }

  Future<void> toggleMilestone(int id, bool done) async {
    final db = await AppDb.instance;
    await db.update('goal_milestones', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMilestone(int id) async {
    final db = await AppDb.instance;
    await db.delete('goal_milestones', where: 'id = ?', whereArgs: [id]);
  }

  /// (المكتملة، الإجمالى) لمعالم هدف.
  Future<(int, int)> progress(int goalId) async {
    final list = await milestones(goalId);
    final done = list.where((m) => m.done).length;
    return (done, list.length);
  }
}
