import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

/// المهام والمشاريع — قوائم مهام بأولويات ومواعيد، مجمّعة فى مشاريع.
class TasksRepo {
  // ---- المشاريع ----

  Future<List<Project>> projects({bool includeArchived = false}) async {
    final db = await AppDb.instance;
    final rows = await db.query('projects',
        where: includeArchived ? null : 'archived = 0',
        orderBy: 'archived, id DESC');
    return rows.map(Project.fromMap).toList();
  }

  Future<int> saveProject(Project p) async {
    final db = await AppDb.instance;
    if (p.id == null) return db.insert('projects', p.toMap());
    await db.update('projects', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  Future<void> deleteProject(int id) async {
    final db = await AppDb.instance;
    // شيل ربط المهام (تفضل موجودة بدون مشروع).
    await db.update('tasks', {'project_id': null},
        where: 'project_id = ?', whereArgs: [id]);
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ---- المهام ----

  /// [projectId] = null → كل المهام؛ [projectId] = -1 → بدون مشروع.
  Future<List<Task>> tasks({int? projectId, bool openOnly = false}) async {
    final db = await AppDb.instance;
    final where = <String>[];
    final args = <Object?>[];
    if (openOnly) where.add('done = 0');
    if (projectId == -1) {
      where.add('project_id IS NULL');
    } else if (projectId != null) {
      where.add('project_id = ?');
      args.add(projectId);
    }
    final rows = await db.query('tasks',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        // المفتوحة أولاً، ثم حسب الأولوية، ثم الأقرب موعدًا.
        orderBy: 'done, priority DESC, '
            "CASE WHEN due_at IS NULL THEN 1 ELSE 0 END, due_at, id DESC");
    return rows.map(Task.fromMap).toList();
  }

  /// المهام المفتوحة اللى موعدها النهاردة أو فات (للرئيسية/التنبيهات).
  Future<List<Task>> dueTasks(DateTime now) async {
    final all = await tasks(openOnly: true);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return [
      for (final t in all)
        if (t.due != null && t.due!.isBefore(end)) t
    ];
  }

  Future<int> openCount() async => (await tasks(openOnly: true)).length;

  Future<int> save(Task t) async {
    final db = await AppDb.instance;
    final int id;
    if (t.id == null) {
      id = await db.insert('tasks', t.toMap());
    } else {
      id = t.id!;
      await db.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(t.copyWithId(id));
    return id;
  }

  Future<void> setDone(int id, bool done) async {
    final db = await AppDb.instance;
    await db.update(
        'tasks',
        {
          'done': done ? 1 : 0,
          'done_at': done ? DateTime.now().toIso8601String() : null
        },
        where: 'id = ?',
        whereArgs: [id]);
    if (done) await Notifications.cancel(Notifications.taskNotifId(id));
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.taskNotifId(id));
  }

  Future<void> _reschedule(Task t) async {
    if (t.id == null) return;
    await Notifications.cancel(Notifications.taskNotifId(t.id!));
    final due = t.due;
    if (t.done || due == null || due.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.taskNotifId(t.id!),
      title: tr('مهمة مستحقة', 'Task due'),
      body: t.title,
      when: due,
    );
  }

  Future<void> rescheduleAll() async {
    for (final t in await tasks(openOnly: true)) {
      await _reschedule(t);
    }
  }
}

extension _TaskCopy on Task {
  Task copyWithId(int id) => Task(
        id: id,
        projectId: projectId,
        title: title,
        notes: notes,
        dueAt: dueAt,
        priority: priority,
        done: done,
        doneAt: doneAt,
        createdAt: createdAt,
      );
}
