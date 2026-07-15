import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/section_pdf.dart';
import '../../data/tasks_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';

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

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TasksRepo();
  bool _loading = true;
  List<Project> _projects = [];
  List<Task> _tasks = [];

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
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _tasks = tasks;
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
          : Column(
              children: [
                _filterChips(scheme),
                Expanded(
                  child: _tasks.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(children: [
                            const SizedBox(height: 60),
                            EmptyHint(
                                icon: Icons.checklist_rtl,
                                text: tr('مفيش مهام هنا — ضيف مهمة بزرار +',
                                    'No tasks here — add one with +')),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                            children: [for (final t in _tasks) _taskTile(t, scheme)],
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _taskForm(),
        tooltip: tr('مهمة جديدة', 'New task'),
        child: const Icon(Icons.add),
      ),
    );
  }

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

  Widget _taskTile(Task t, ColorScheme scheme) {
    final pName = _projectName(t.projectId);
    final subtitle = <String>[
      ?pName,
      if (t.due != null) arDateTime(t.due!),
    ].join('  •  ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Checkbox(
          value: t.done,
          onChanged: (_) => _toggle(t),
        ),
        title: Text(t.title,
            style: TextStyle(
                decoration: t.done ? TextDecoration.lineThrough : null,
                color: t.done ? scheme.outline : null,
                fontWeight: FontWeight.w600)),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: t.overdue ? scheme.error : scheme.outline,
                    fontWeight: t.overdue ? FontWeight.w700 : null)),
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
              onSelected: (v) {
                if (v == 'edit') _taskForm(t);
                if (v == 'delete') _delete(t);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
        onTap: () => _taskForm(t),
      ),
    );
  }

  Future<void> _taskForm([Task? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final notes = TextEditingController(text: task?.notes ?? '');
    var priority = task?.priority ?? 1;
    var projectId = task?.projectId ?? (_filter != null && _filter! > 0 ? _filter : null);
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
              if (_projects.isNotEmpty) ...[
                DropdownButtonFormField<int?>(
                  initialValue: projectId,
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
        createdAt: task?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    notes.dispose();
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
