import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/savings_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _repo = SavingsRepo();
  bool _loading = true;
  List<SavingsGoal> _goals = [];
  final Map<int, int?> _months = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await _repo.all();
    _months.clear();
    for (final g in goals) {
      _months[g.id!] = await _repo.monthsToGoal(g);
    }
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  Future<void> _goalForm([SavingsGoal? goal]) async {
    final name = TextEditingController(text: goal?.name ?? '');
    final target =
        TextEditingController(text: goal == null ? '' : goal.target.toStringAsFixed(0));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          scrollable: true,
        title: Text(goal == null
            ? tr('هدف ادخار جديد', 'New savings goal')
            : tr('تعديل الهدف', 'Edit goal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: goal == null,
              decoration: InputDecoration(
                  labelText: tr('الهدف (مثلًا: موبايل جديد)',
                      'Goal (e.g. new phone)')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('المبلغ المطلوب (ج.م)', 'Target amount (EGP)')),
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
    );
    if (saved == true) {
      final t = parseNumber(target.text);
      if (name.text.trim().isNotEmpty && t != null && t > 0) {
        if (goal == null) {
          await _repo.addGoal(SavingsGoal(
            name: name.text.trim(),
            target: t,
            createdAt: DateTime.now().toIso8601String(),
          ));
        } else {
          await _repo.updateGoal(SavingsGoal(
            id: goal.id,
            name: name.text.trim(),
            target: t,
            createdAt: goal.createdAt,
            deadline: goal.deadline,
          ));
        }
        if (mounted) await _load();
      }
    }
    name.dispose();
    target.dispose();
  }

  Future<void> _addContribution(SavingsGoal g) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          scrollable: true,
        title: Text(tr('ضيف لـ "${g.name}"', 'Add to "${g.name}"')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              InputDecoration(labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('ضيف', 'Add'))),
        ],
      ),
    );
    if (saved == true) {
      final v = parseNumber(controller.text);
      if (v != null && v != 0) {
        await _repo.addContribution(g.id!, v);
        if (mounted) await _load();
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('أهداف الادخار', 'Savings goals')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? EmptyHint(
                  icon: Icons.savings_outlined,
                  actionLabel: tr('ضيف هدف', 'Add goal'),
                  onAction: () => _goalForm(),
                  text: tr(
                      'حدد هدف تجمعله — واعرف فاضلك كام شهر بمعدل ادخارك',
                      'Set a goal to save for — and see how many months at your pace'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    children: [
                      _totalCard(context),
                      ..._goals.map((g) => _goalCard(context, g)),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'savings_fab',
        onPressed: () => _goalForm(),
        tooltip: tr('هدف جديد', 'New goal'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// كارت علوي: إجمالي المدّخر عبر كل الأهداف + نسبة الوصول الكلية.
  Widget _totalCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final saved = _goals.fold<double>(0, (s, g) => s + g.saved);
    final target = _goals.fold<double>(0, (s, g) => s + g.target);
    final pct = target > 0 ? (saved / target * 100).round() : 0;
    final reached = _goals.where((g) => g.remaining <= 0).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.savings_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('إجمالي مدّخرك', 'Total saved'),
                    style: TextStyle(color: scheme.outline)),
              ),
              Text(egp(saved),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: target > 0 ? (saved / target).clamp(0.0, 1.0) : 0,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
                tr('${arNum(pct)}٪ من إجمالي أهدافك (${egp(target)})${reached > 0 ? ' • وصلت ${arNum(reached)}' : ''}',
                    '${arNum(pct)}% of your goals (${egp(target)})${reached > 0 ? ' • ${arNum(reached)} reached' : ''}'),
                style: TextStyle(color: scheme.outline, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(BuildContext context, SavingsGoal g) {
    final scheme = Theme.of(context).colorScheme;
    final done = g.remaining <= 0;
    final months = _months[g.id!];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(g.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await _goalForm(g);
                    } else if (v == 'delete') {
                      if (!await confirmDelete(
                          context, tr('الهدف "${g.name}"', 'goal "${g.name}"'))) {
                        return;
                      }
                      await _repo.deleteGoal(g.id!);
                      if (mounted) await _load();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                    PopupMenuItem(
                        value: 'delete', child: Text(tr('حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: g.progress,
                minHeight: 8,
                color: done ? Colors.green : scheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
                tr('${egp(g.saved)} من ${egp(g.target)} (٪${arNum((g.progress * 100).round())})',
                    '${egp(g.saved)} of ${egp(g.target)} (${arNum((g.progress * 100).round())}%)'),
                style: TextStyle(color: scheme.outline, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
                done
                    ? tr('🎉 وصلت للهدف!', '🎉 Goal reached!')
                    : months == null
                        ? tr('ابدأ تجمّع عشان نحسبلك المدة', 'Start saving to estimate the time')
                        : tr('فاضل ${egp(g.remaining)} — حوالي ${arNum(months)} شهر بمعدلك',
                            '${egp(g.remaining)} left — about ${arNum(months)} months at your pace'),
                style: TextStyle(
                    color: done ? Colors.green : scheme.onSurface, fontSize: 13)),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                onPressed: () => _addContribution(g),
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('ضيف مبلغ', 'Add money')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
