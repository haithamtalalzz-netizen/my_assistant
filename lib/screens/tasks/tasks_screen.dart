import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/section_pdf.dart';
import '../../data/tasks_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import '../../widgets/bar_actions.dart';
import '../../widgets/search_action.dart';
import 'focus_screen.dart';
import '../../core/calendar_sync.dart';
import '../../core/privacy.dart';

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

  /// كل المهام — مننا بنشتق المعروض حسب الفلتر.
  ///
  /// بنجيبها **مرة واحدة** لإن كروت المشاريع فوق محتاجة عداد لكل مشروع؛
  /// لو كل كارت استعلم لوحده هنعمل استعلام لكل مشروع كل مرة الشاشة
  /// تترسم.
  List<Task> _allTasks = [];

  Future<void> _load() async {
    final projects = await _repo.projects();
    final tasks = await _repo.tasks();
    final subs = await _repo.subtaskProgressAll();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _allTasks = tasks;
      _tasks = _applyFilter(tasks);
      _subs = subs;
      _loading = false;
    });
  }

  List<Task> _applyFilter(List<Task> all) => switch (_filter) {
        null => all,
        -1 => [for (final t in all) if (t.projectId == null) t],
        final id => [for (final t in all) if (t.projectId == id) t],
      };

  void _setFilter(int? value) => setState(() {
        // دوسة تانية على نفس المشروع بترجّعك للكل — من غير كده مفيش
        // طريقة تخرج من مشروع غير ما تدوّر على زرار «الكل».
        _filter = _filter == value ? null : value;
        _tasks = _applyFilter(_allTasks);
      });

  /// (خلصت، الإجمالى) لمشروع — أو للمهام من غير مشروع لو [id] = -1.
  (int, int) _projectCount(int? id) {
    final list = id == -1
        ? [for (final t in _allTasks) if (t.projectId == null) t]
        : [for (final t in _allTasks) if (t.projectId == id) t];
    return (list.where((t) => t.done).length, list.length);
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
        title: Text(tr('مهامى', 'My tasks')),
        // ٥ أيقونات على موبايل ٣٢٠ كانت بتاكل العنوان («مهامى» بيتقصّ).
        // `barActions` بتنزّل اللى مايسعش فى قايمة «⋮».
        actions: barActions(context, [
          BarAction(Icons.visibility_outlined, tr('اخفِ بياناتى', 'Hide data'),
              Privacy.toggle),
          BarAction(
              Icons.search, tr('بحث', 'Search'), () => openSearch(context)),
          BarAction(
              Icons.timer_outlined,
              tr('جلسة تركيز', 'Focus session'),
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FocusScreen()))),
          BarAction(Icons.picture_as_pdf_outlined, tr('تقرير PDF', 'PDF report'),
              _exportPdf),
          BarAction(Icons.folder_outlined, tr('المشاريع', 'Projects'),
              _manageProjects),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  const SizedBox(height: 6),
                  _projectCards(scheme),
                  AppPad(AppGroupHead(_openTitle,
                      trail: tr(
                          '${arNum(_doneList.length)} من ${arNum(_tasks.length)}',
                          '${arNum(_doneList.length)} of ${arNum(_tasks.length)}'))),
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
                    const SizedBox(height: 18),
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

  Widget _group(String title, List<Task> list, ColorScheme scheme) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPad(AppGroupHead(title, trail: arNum(list.length))),
        for (var i = 0; i < list.length; i++)
          AppPad(_taskTile(list[i], scheme, last: i == list.length - 1)),
      ]);

  /// ألوان المشاريع — لون ثابت لكل مشروع من اسمه عشان تعرفه من لونه.
  static const _projectPalette = [
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  Color _projectColor(Project p) => p.color != 0
      ? Color(p.color)
      : _projectPalette[p.name.hashCode.abs() % _projectPalette.length];

  /// كروت المشاريع فوق الشاشة.
  ///
  /// شريط الشرائح القديم كان بيقول اسم المشروع بس — الكارت بيقول
  /// **كام خلصت من كام**، وده اللى بيخلّيك تعرف المشروع الواقف فين من
  /// غير ما تفتحه.
  Widget _projectCards(ColorScheme scheme) {
    Widget card(String name, Color c, IconData icon, int? value) {
      final (done, total) = _projectCount(value);
      final on = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(left: 9),
        child: SizedBox(
          width: 158,
          child: Material(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _setFilter(value),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: c.withValues(alpha: on ? 0.9 : 0.25),
                      width: on ? 2 : 1),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, size: 17, color: c),
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                          tr('${arNum(done)} من ${arNum(total)}',
                              '${arNum(done)} of ${arNum(total)}'),
                          style: TextStyle(
                              fontSize: 10.5, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 7),
                      // 🔴 المسار أبيض: لو خد لون الكارت الملوّن بيختفى
                      // والشريط يبان مليان دايماً.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 6,
                          backgroundColor: scheme.surface,
                          valueColor: AlwaysStoppedAnimation(c),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      );
    }

    final (noProjDone, noProjTotal) = _projectCount(-1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_projects.isNotEmpty) ...[
        AppPad(AppGroupHead(tr('مشاريعك', 'Your projects'),
            trail: arNum(_projects.length))),
        SizedBox(
          height: 152,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            children: [
              for (final p in _projects)
                card(p.name, _projectColor(p), Icons.folder_outlined, p.id),
            ],
          ),
        ),
        const SizedBox(height: 9),
      ],
      if (noProjTotal > 0)
        AppPad(Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _setFilter(-1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _filter == -1
                        ? scheme.primary
                        : scheme.outlineVariant,
                    width: _filter == -1 ? 2 : 1),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inbox_outlined,
                    size: 17, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(tr('من غير مشروع', 'No project'),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(
                    tr('${arNum(noProjDone)} من ${arNum(noProjTotal)}',
                        '${arNum(noProjDone)} of ${arNum(noProjTotal)}'),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
        )),
    ]);
  }

  /// عنوان القسم المفتوح — اسم المشروع وعدّاده، أو «كل المهام».
  String get _openTitle => switch (_filter) {
        null => tr('كل المهام', 'All tasks'),
        -1 => tr('من غير مشروع', 'No project'),
        final id => _projectName(id) ?? tr('مشروع', 'Project'),
      };

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
      icon: t.done
          ? Icons.check_circle_outline
          : (t.overdue ? Icons.error_outline : Icons.checklist),
      tint: t.done
          ? scheme.primary
          : (t.overdue ? scheme.error : _priorityColors[t.priority]),
      check: true,
      checked: t.done,
      divider: !last,
      onTap: () => _taskForm(t),
      onCheck: () => _toggle(t),
      trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نقطة على **كل** مهمة مالهاش مفتاح، فبتتقرا كزينة مش كمعلومة.
            // العالية بس هى اللى ليها علامة، فالعلامة تبقى معناها واضح.
            if (t.priority >= 2 && !t.done)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 2),
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
                  // من غير dense: بتضغط ارتفاع الـtrailing فنصّ
                  // الزرار بيتقصّ من تحت (٢٢px والكلمة محتاجة ٢٨).
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
