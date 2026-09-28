import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/section_pdf.dart';
import '../../data/tasks_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';
import 'focus_screen.dart';
import '../../core/calendar_sync.dart';

/// المهام والمشاريع — قوائم مهام بأولويات ومواعيد، مجمّعة فى مشاريع.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

const _priorityColors = [Colors.grey, Colors.blue, Colors.redAccent];
String _priorityLabel(int p) => switch (p) {
      0 => tr('منخفضة', 'Low'),
      2 => tr('عالية', 'High'),
      _ => tr('عادية', 'Normal'),
    };

String _repeatLabel(String rule) => switch (rule) {
      'daily' => tr('يومى', 'Daily'),
      'weekly' => tr('أسبوعى', 'Weekly'),
      'monthly' => tr('شهرى', 'Monthly'),
      _ => tr('بدون', 'None'),
    };

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TasksRepo();
  bool _loading = true;
  List<Project> _projects = [];
  List<Task> _tasks = [];

  /// تقدّم التشيك-ليست: task_id → (متعمل، إجمالى).
  Map<int, (int, int)> _subs = {};

  /// null = الكل، -1 = بدون مشروع، غير كده = id المشروع.
  int? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final projects = await _repo.projects();
    final tasks = await _repo.tasks(projectId: _filter);
    final subs = await _repo.subtaskProgressAll();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _tasks = tasks;
      _subs = subs;
      _loading = false;
    });
  }

  String? _projectName(int? id) {
    if (id == null) return null;
    for (final p in _projects) {
      if (p.id == id) return p.name;
    }
    return null;
  }

  Future<void> _toggle(Task t) async {
    await _repo.setDone(t.id!, !t.done);
    await _load();
  }

  Future<void> _delete(Task t) async {
    if (!await confirmDelete(context, tr('المهمة "${t.title}"', 'task "${t.title}"'))) {
      return;
    }
    await _repo.delete(t.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('المهام', 'Tasks')),
        actions: [
          searchAction(context),
          IconButton(
            tooltip: tr('جلسة تركيز', 'Focus session'),
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FocusScreen())),
          ),
          IconButton(
            tooltip: tr('تقرير PDF', 'PDF report'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _exportPdf,
          ),
          IconButton(
            tooltip: tr('المشاريع', 'Projects'),
            icon: const Icon(Icons.folder_outlined),
            onPressed: _manageProjects,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  AppPad(_hero(scheme), top: 12, bottom: 16),
                  _filterChips(scheme),
                  const SizedBox(height: 10),
                  if (_tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: EmptyHint(
                        icon: Icons.checklist_rtl,
                        text: tr('مفيش مهام هنا — ضيف مهمة بزرار +',
                            'No tasks here — add one with +'),
                        actionLabel: tr('ضيف مهمة', 'Add a task'),
                        onAction: _taskForm,
                      ),
                    )
                  else ...[
                    if (_overdue.isNotEmpty)
                      _group(tr('فاتت', 'Overdue'), _overdue, scheme),
                    if (_todayList.isNotEmpty)
                      _group(tr('النهارده', 'Today'), _todayList, scheme),
                    if (_later.isNotEmpty)
                      _group(tr('بعدين', 'Later'), _later, scheme),
                    if (_doneList.isNotEmpty)
                      _group(tr('خلصت', 'Done'), _doneList, scheme),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _taskForm(),
        tooltip: tr('مهمة جديدة', 'New task'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// المهام اللى فات ميعادها ولسه ما خلصتش.
  List<Task> get _overdue =>
      [for (final t in _tasks) if (!t.done && t.overdue) t];

  /// مهام النهارده (من غير الفايتة).
  List<Task> get _todayList {
    final today = dateOnly(DateTime.now());
    return [
      for (final t in _tasks)
        if (!t.done && !t.overdue && t.due != null && dateOnly(t.due!) == today)
          t
    ];
  }

  /// الباقى اللى لسه ما خلصش (بميعاد بعدين أو من غير ميعاد).
  List<Task> get _later {
    final shown = {..._overdue, ..._todayList};
    return [
      for (final t in _tasks)
        if (!t.done && !shown.contains(t)) t
    ];
  }

  List<Task> get _doneList => [for (final t in _tasks) if (t.done) t];

  /// المهمة اللى تبدأ بيها: أقدم فايتة، وإلا أول واحدة النهارده، وإلا أى
  /// مهمة مفتوحة — بترتيب الأولوية.
  Task? get _startWith {
    int rank(Task t) => t.overdue ? 0 : (t.due != null ? 1 : 2);
    final open = [for (final t in _tasks) if (!t.done) t]
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        final p = b.priority.compareTo(a.priority);
        if (p != 0) return p;
        if (a.due != null && b.due != null) return a.due!.compareTo(b.due!);
        return 0;
      });
    return open.isEmpty ? null : open.first;
  }

  Widget _hero(ColorScheme scheme) {
    final t = _startWith;
    final open = _tasks.where((e) => !e.done).length;
    final done = _doneList.length;
    final total = _tasks.length;
    if (t == null) {
      return AppHero(
        icon: total == 0 ? Icons.checklist : Icons.emoji_events_outlined,
        kicker: tr('مهامك', 'Your tasks'),
        title: total == 0
            ? tr('ابدأ بمهمة واحدة', 'Start with one task')
            : tr('خلّصت كل مهامك', 'All tasks done'),
        primaryLabel: tr('مهمة جديدة', 'New task'),
        primaryIcon: Icons.add,
        onPrimary: _taskForm,
      );
    }
    final prog = _subs[t.id];
    final pName = _projectName(t.projectId);
    return AppHero(
      icon: Icons.bolt,
      kicker: t.overdue
          ? tr('فاتت — ابدأ بيها', 'Overdue — start here')
          : tr('ابدأ بيها دلوقتى', 'Start with this'),
      title: t.title,
      trailingBig: prog != null && prog.$2 > 0
          ? '${arNum(prog.$1)}/${arNum(prog.$2)}'
          : null,
      trailingSmall:
          prog != null && prog.$2 > 0 ? tr('خطوات', 'steps') : null,
      primaryLabel: tr('خلّصتها', 'Done'),
      primaryIcon: Icons.check,
      onPrimary: () => _toggle(t),
      secondaryLabel: tr('ركّز 25 دقيقة', 'Focus 25 min'),
      onSecondary: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FocusScreen(taskId: t.id, taskTitle: t.title))),
      colors: t.overdue
          ? [scheme.error, Color.lerp(scheme.error, Colors.black, 0.3)!]
          : null,
      extra: total == 0
          ? null
          : AppHeroBar(
              done / total,
              [
                ?pName,
                tr('${arNum(done)} من ${arNum(total)} خلصوا',
                    '${arNum(done)} of ${arNum(total)} done'),
                tr('${arNum(open)} مفتوحة', '${arNum(open)} open'),
              ].join(' · ')),
    );
  }

  Widget _group(String title, List<Task> list, ColorScheme scheme) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPad(AppSectionTitle(title, trailing: arNum(list.length))),
        AppPad(AppCard(Column(children: [
          for (var i = 0; i < list.length; i++)
            _taskTile(list[i], scheme, last: i == list.length - 1),
        ]))),
        const SizedBox(height: 18),
      ]);

  Widget _filterChips(ColorScheme scheme) {
    Widget chip(String label, int? value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == value,
            onSelected: (_) {
              setState(() => _filter = value);
              _load();
            },
          ),
        );
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          chip(tr('الكل', 'All'), null),
          chip(tr('بدون مشروع', 'No project'), -1),
          for (final p in _projects) chip(p.name, p.id),
        ],
      ),
    );
  }

  Widget _taskTile(Task t, ColorScheme scheme, {bool last = false}) {
    final pName = _projectName(t.projectId);
    final prog = _subs[t.id];
    final subtitle = <String>[
      ?pName,
      if (t.due != null) arDateTime(t.due!),
      if (t.repeatRule.isNotEmpty)
        tr('تكرار ${_repeatLabel(t.repeatRule)}',
            'repeats ${_repeatLabel(t.repeatRule)}'),
      if (prog != null && prog.$2 > 0)
        tr('خطوات ${arNum(prog.$1)}/${arNum(prog.$2)}',
            'steps ${arNum(prog.$1)}/${arNum(prog.$2)}'),
    ].join('  •  ');
    return AppListRow(
      title: t.title,
      sub: subtitle.isEmpty ? null : subtitle,
      check: true,
      checked: t.done,
      divider: !last,
      onTap: () => _taskForm(t),
      onCheck: () => _toggle(t),
      trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: _priorityColors[t.priority], shape: BoxShape.circle),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'edit') _taskForm(t);
                if (v == 'subtasks') _subtasksSheet(t);
                if (v == 'focus') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FocusScreen(
                              taskId: t.id, taskTitle: t.title)));
                }
                if (v == 'calendar') CalendarSync.addTask(t);
                if (v == 'delete') _delete(t);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(
                    value: 'subtasks',
                    child: Text(tr('مهام فرعية', 'Subtasks'))),
                PopupMenuItem(
                    value: 'focus',
                    child: Text(tr('جلسة تركيز', 'Focus session'))),
                // مهمة من غير ميعاد مالهاش مكان فى التقويم.
                if (t.dueAt != null)
                  PopupMenuItem(
                      value: 'calendar',
                      child: Text(
                          tr('أضف لتقويم الموبايل', 'Add to phone calendar'))),
                PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
    );
  }

  Future<void> _taskForm([Task? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final notes = TextEditingController(text: task?.notes ?? '');
    var priority = task?.priority ?? 1;
    var projectId = task?.projectId ?? (_filter != null && _filter! > 0 ? _filter : null);
    var repeatRule = task?.repeatRule ?? '';
    DateTime? due = task?.due;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(task == null ? tr('مهمة جديدة', 'New task') : tr('تعديل مهمة', 'Edit task')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: title,
                autofocus: task == null,
                decoration: InputDecoration(labelText: tr('العنوان', 'Title')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: tr('ملاحظات (اختيارى)', 'Notes (optional)')),
              ),
              const SizedBox(height: 14),
              Text(tr('الأولوية', 'Priority'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  for (var p = 0; p <= 2; p++)
                    ChoiceChip(
                      label: Text(_priorityLabel(p)),
                      selected: priority == p,
                      onSelected: (_) => setD(() => priority = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // التكرار: المهمة المتكررة بتترحّل لموعدها الجاى بدل ما تتقفل.
              Text(tr('التكرار', 'Repeat'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  for (final r in const ['', 'daily', 'weekly', 'monthly'])
                    ChoiceChip(
                      label: Text(_repeatLabel(r)),
                      selected: repeatRule == r,
                      onSelected: (_) => setD(() => repeatRule = r),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_projects.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  initialValue: projectId,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: tr('المشروع', 'Project')),
                  items: [
                    DropdownMenuItem(value: null, child: Text(tr('بدون', 'None'))),
                    for (final p in _projects)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => projectId = v,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(due == null
                        ? tr('بدون موعد', 'No due date')
                        : arDateTime(due!)),
                  ),
                  if (due != null)
                    IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setD(() => due = null)),
                  TextButton.icon(
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(tr('موعد', 'Due')),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: due ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d == null) return;
                      if (!ctx.mounted) return;
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(due ?? DateTime.now()),
                      );
                      setD(() => due = DateTime(
                          d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );

    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(Task(
        id: task?.id,
        projectId: projectId,
        title: title.text.trim(),
        notes: notes.text.trim(),
        dueAt: due?.toIso8601String(),
        priority: priority,
        done: task?.done ?? false,
        doneAt: task?.doneAt,
        repeatRule: repeatRule,
        createdAt: task?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    notes.dispose();
  }

  /// شيت المهام الفرعية — تشيك-ليست جوه المهمة: إضافة/تعليم/حذف.
  Future<void> _subtasksSheet(Task t) async {
    final input = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: FutureBuilder<List<Subtask>>(
            future: _repo.subtasks(t.id!),
            builder: (_, snap) {
              final subs = snap.data ?? const <Subtask>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (subs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          tr('قسّم المهمة لخطوات صغيرة تتعلّم عليها.',
                              'Break the task into small steps.'),
                          style: TextStyle(
                              color: Theme.of(ctx).colorScheme.outline)),
                    ),
                  for (final s in subs)
                    CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: s.done,
                      title: Text(s.title,
                          style: TextStyle(
                              decoration: s.done
                                  ? TextDecoration.lineThrough
                                  : null)),
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await _repo.deleteSubtask(s.id!);
                          setSheet(() {});
                        },
                      ),
                      onChanged: (v) async {
                        await _repo.setSubtaskDone(s.id!, v ?? false);
                        setSheet(() {});
                      },
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          decoration: InputDecoration(
                              hintText: tr('خطوة جديدة…', 'New step…'),
                              isDense: true),
                          onSubmitted: (v) async {
                            if (v.trim().isEmpty) return;
                            await _repo.addSubtask(t.id!, v.trim());
                            input.clear();
                            setSheet(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final v = input.text.trim();
                          if (v.isEmpty) return;
                          await _repo.addSubtask(t.id!, v);
                          input.clear();
                          setSheet(() {});
                        },
                        child: Text(tr('إضافة', 'Add')),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    input.dispose();
    if (mounted) await _load();
  }

  Future<void> _exportPdf() async {
    await SectionPdf.share(
      title: tr('المهام', 'Tasks'),
      headers: [
        tr('المهمة', 'Task'),
        tr('الحالة', 'Status'),
        tr('الموعد', 'Due'),
        tr('الأولوية', 'Priority'),
      ],
      rows: [
        for (final t in _tasks)
          [
            t.title,
            t.done ? tr('تمّت', 'Done') : tr('مفتوحة', 'Open'),
            t.due == null ? '' : arShortDate(t.due!),
            _priorityLabel(t.priority),
          ]
      ],
    );
  }

  Future<void> _manageProjects() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('المشاريع', 'Projects'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final p in _projects)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      await _repo.deleteProject(p.id!);
                      await _load();
                      setSheet(() {});
                    },
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(tr('مشروع جديد', 'New project')),
                onPressed: () async {
                  final name = await _promptText(ctx, tr('اسم المشروع', 'Project name'));
                  if (name != null && name.trim().isNotEmpty) {
                    await _repo.saveProject(Project(
                        name: name.trim(),
                        createdAt: DateTime.now().toIso8601String()));
                    await _load();
                    setSheet(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _promptText(BuildContext ctx, String label) {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(label),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
  }
}
