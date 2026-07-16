import '../core/ar.dart';
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
    if (done) {
      // مهمة متكررة: بدل ما تتقفل، بتترحّل لموعدها الجاى وتفضل مفتوحة.
      final rows =
          await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) {
        final t = Task.fromMap(rows.first);
        if (t.repeatRule.isNotEmpty) {
          final next = nextOccurrence(t.due ?? DateTime.now(), t.repeatRule);
          await db.update('tasks', {'due_at': next.toIso8601String()},
              where: 'id = ?', whereArgs: [id]);
          // المهام الفرعية بتترجع فاضية للدورة الجاية.
          await db.update('subtasks', {'done': 0},
              where: 'task_id = ?', whereArgs: [id]);
          await _reschedule(t.copyWithId(id).copyWithDue(next));
          return;
        }
      }
    }
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

  /// الموعد الجاى لقاعدة تكرار — لو الموعد فات بيترحّل لأقرب مستقبل
  /// (عشان مهمة متأخرة أسبوع ماتطلعش بموعد لسه فات برضه).
  static DateTime nextOccurrence(DateTime from, String rule,
      [DateTime? now]) {
    final ref = now ?? DateTime.now();
    var d = from;
    DateTime step(DateTime x) => switch (rule) {
          'daily' => x.add(const Duration(days: 1)),
          'weekly' => x.add(const Duration(days: 7)),
          'monthly' => DateTime(x.year, x.month + 1, x.day, x.hour, x.minute),
          _ => x.add(const Duration(days: 1)),
        };
    d = step(d);
    var guard = 0;
    while (d.isBefore(ref) && guard < 1200) {
      d = step(d);
      guard++;
    }
    return d;
  }

  // ---- المهام الفرعية ----

  Future<List<Subtask>> subtasks(int taskId) async {
    final db = await AppDb.instance;
    final rows = await db.query('subtasks',
        where: 'task_id = ?', whereArgs: [taskId], orderBy: 'done, id');
    return rows.map(Subtask.fromMap).toList();
  }

  Future<int> addSubtask(int taskId, String title) async {
    final db = await AppDb.instance;
    return db.insert('subtasks', Subtask(taskId: taskId, title: title).toMap());
  }

  Future<void> setSubtaskDone(int id, bool done) async {
    final db = await AppDb.instance;
    await db.update('subtasks', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSubtask(int id) async {
    final db = await AppDb.instance;
    await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  /// تقدّم التشيك-ليست لكل المهام مرة واحدة: task_id → (متعمل، إجمالى).
  Future<Map<int, (int, int)>> subtaskProgressAll() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT task_id, COUNT(*) AS total, COALESCE(SUM(done), 0) AS done '
        'FROM subtasks GROUP BY task_id');
    return {
      for (final r in rows)
        (r['task_id'] as int): (
          (r['done'] as num).toInt(),
          (r['total'] as num).toInt()
        )
    };
  }

  /// (المتعمل، الإجمالى) لمهمة — للتشيك-ليست على كارت المهمة.
  Future<(int, int)> subtaskProgress(int taskId) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS total, COALESCE(SUM(done), 0) AS done '
        'FROM subtasks WHERE task_id = ?',
        [taskId]);
    return (
      (rows.first['done'] as num).toInt(),
      (rows.first['total'] as num).toInt()
    );
  }

  // ---- جلسات التركيز (بومودورو) ----

  Future<void> logFocus({int? taskId, required int minutes}) async {
    final db = await AppDb.instance;
    await db.insert('focus_sessions', {
      'task_id': taskId,
      'minutes': minutes,
      'day': dayKey(DateTime.now()),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// إجمالى دقايق التركيز فى يوم.
  Future<int> focusMinutesOn(String day) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(minutes), 0) AS m FROM focus_sessions '
        'WHERE day = ?',
        [day]);
    return (rows.first['m'] as num).toInt();
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await db.delete('subtasks', where: 'task_id = ?', whereArgs: [id]);
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
        repeatRule: repeatRule,
        createdAt: createdAt,
      );

  Task copyWithDue(DateTime due) => Task(
        id: id,
        projectId: projectId,
        title: title,
        notes: notes,
        dueAt: due.toIso8601String(),
        priority: priority,
        done: false,
        doneAt: doneAt,
        repeatRule: repeatRule,
        createdAt: createdAt,
      );
}
