import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/goals_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// الأهداف بمعالم — كل هدف له معالم، والتقدّم من المعالم المكتملة.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _repo = GoalsRepo();
  bool _loading = true;
  List<Goal> _goals = [];
  final Map<int, (int, int)> _progress = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await _repo.all();
    _progress.clear();
    for (final g in goals) {
      if (g.id != null) _progress[g.id!] = await _repo.progress(g.id!);
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('الأهداف', 'Goals'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _goals.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.flag_outlined,
                          text: tr('مفيش أهداف — ضيف هدف بزرار +',
                              'No goals yet — add one with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final g in _goals) _goalCard(g)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goalForm(),
        tooltip: tr('هدف جديد', 'New goal'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _goalCard(Goal g) {
    final scheme = Theme.of(context).colorScheme;
    final (done, total) = _progress[g.id] ?? (0, 0);
    final ratio = total == 0 ? (g.done ? 1.0 : 0.0) : done / total;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _openGoal(g),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(g.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration:
                                g.done ? TextDecoration.lineThrough : null,
                            color: g.done ? scheme.outline : null)),
                  ),
                  Text('${arNum((ratio * 100).round())}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: scheme.primary)),
                ],
              ),
              if (g.target != null) ...[
                const SizedBox(height: 2),
                Text(tr('الموعد: ${arShortDate(g.target!)}',
                    'Target: ${arShortDate(g.target!)}'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
              ],
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: ratio, minHeight: 7),
              ),
              const SizedBox(height: 4),
              Text(
                  total == 0
                      ? tr('لا معالم بعد', 'No milestones yet')
                      : tr('${arNum(done)} من ${arNum(total)} معالم',
                          '${arNum(done)} of ${arNum(total)} milestones'),
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoal(Goal g) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => _GoalDetail(goal: g)));
    if (mounted) await _load();
  }

  Future<void> _goalForm([Goal? goal]) async {
    final title = TextEditingController(text: goal?.title ?? '');
    final notes = TextEditingController(text: goal?.notes ?? '');
    DateTime? target = goal?.target;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(goal == null ? tr('هدف جديد', 'New goal') : tr('تعديل هدف', 'Edit goal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: title,
                autofocus: goal == null,
                decoration: InputDecoration(labelText: tr('الهدف', 'Goal')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: tr('ملاحظات (اختيارى)', 'Notes (optional)')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(target == null
                        ? tr('بدون موعد مستهدف', 'No target date')
                        : arShortDate(target!)),
                  ),
                  if (target != null)
                    IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setD(() => target = null)),
                  TextButton.icon(
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(tr('موعد', 'Date')),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: target ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setD(() => target = d);
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
      await _repo.save(Goal(
        id: goal?.id,
        title: title.text.trim(),
        notes: notes.text.trim(),
        targetDate: target?.toIso8601String(),
        done: goal?.done ?? false,
        createdAt: goal?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    notes.dispose();
  }
}

/// صفحة هدف واحد — تفاصيله ومعالمه.
class _GoalDetail extends StatefulWidget {
  final Goal goal;
  const _GoalDetail({required this.goal});

  @override
  State<_GoalDetail> createState() => _GoalDetailState();
}

class _GoalDetailState extends State<_GoalDetail> {
  final _repo = GoalsRepo();
  List<GoalMilestone> _milestones = [];
  late Goal _goal = widget.goal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.milestones(_goal.id!);
    if (!mounted) return;
    setState(() => _milestones = list);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = _milestones.where((m) => m.done).length;
    final ratio = _milestones.isEmpty ? 0.0 : done / _milestones.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.title),
        actions: [
          IconButton(
            tooltip: _goal.done ? tr('إلغاء الإنجاز', 'Reopen') : tr('تم', 'Done'),
            icon: Icon(_goal.done ? Icons.undo : Icons.check_circle_outline),
            onPressed: () async {
              await _repo.setDone(_goal.id!, !_goal.done);
              setState(() => _goal = Goal(
                    id: _goal.id,
                    title: _goal.title,
                    notes: _goal.notes,
                    targetDate: _goal.targetDate,
                    done: !_goal.done,
                    createdAt: _goal.createdAt,
                  ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          if (_goal.notes.isNotEmpty) ...[
            Text(_goal.notes, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, minHeight: 8),
          ),
          const SizedBox(height: 6),
          Text(
              _milestones.isEmpty
                  ? tr('ضيف معالم تقسّم بيها هدفك', 'Add milestones to break it down')
                  : tr('${arNum(done)} من ${arNum(_milestones.length)} — ${arNum((ratio * 100).round())}%',
                      '${arNum(done)} of ${arNum(_milestones.length)} — ${arNum((ratio * 100).round())}%'),
              style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 8),
          for (final m in _milestones)
            CheckboxListTile(
              value: m.done,
              onChanged: (v) async {
                await _repo.toggleMilestone(m.id!, v ?? false);
                await _load();
              },
              title: Text(m.title,
                  style: TextStyle(
                      decoration: m.done ? TextDecoration.lineThrough : null)),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  await _repo.deleteMilestone(m.id!);
                  await _load();
                },
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMilestone,
        icon: const Icon(Icons.add),
        label: Text(tr('معلم', 'Milestone')),
      ),
    );
  }

  Future<void> _addMilestone() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('معلم جديد', 'New milestone')),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(tr('إضافة', 'Add'))),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await _repo.addMilestone(_goal.id!, c.text.trim());
      await _load();
    }
    c.dispose();
  }
}
