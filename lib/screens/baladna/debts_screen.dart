import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/debts_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _repo = DebtsRepo();
  bool _loading = true;
  List<Debt> _debts = [];
  double _owedToMe = 0;
  double _iOwe = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final debts = await _repo.all();
    debts.sort((a, b) => b.amount.compareTo(a.amount)); // الأكبر أول
    final (owedToMe, iOwe) = await _repo.totals();
    if (!mounted) return;
    setState(() {
      _debts = debts;
      _owedToMe = owedToMe;
      _iOwe = iOwe;
      _loading = false;
    });
  }

  Future<void> _addDebt() async {
    final person = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    var direction = 'لى';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(tr('دين أو سلفة', 'Debt or loan')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'لى',
                      label: Text(tr('ليا عند حد', 'Owed to me'))),
                  ButtonSegment(
                      value: 'عليا', label: Text(tr('عليا لحد', 'I owe'))),
                ],
                selected: {direction},
                onSelectionChanged: (s) =>
                    setDialogState(() => direction = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: person,
                autofocus: true,
                decoration: InputDecoration(labelText: tr('مين؟', 'Who?')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration:
                    InputDecoration(labelText: tr('ملاحظة (اختياري)', 'Note (optional)')),
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
    if (saved == true) {
      final value = parseNumber(amount.text);
      if (person.text.trim().isNotEmpty && value != null && value > 0) {
        await _repo.add(Debt(
          person: person.text.trim(),
          amount: value,
          direction: direction,
          note: note.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ));
        if (mounted) await _load();
      }
    }
    person.dispose();
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final net = _owedToMe - _iOwe;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('الديون والسلف', 'Debts & loans')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(context, tr('ليك عند الناس', 'Owed to you'),
                            _owedToMe, scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                            context, tr('عليك للناس', 'You owe'), _iOwe, scheme.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      net == 0
                          ? tr('متعادل', 'Even')
                          : net > 0
                              ? tr('الصافي ليك: ${egp(net)}', 'Net owed to you: ${egp(net)}')
                              : tr('الصافي عليك: ${egp(-net)}', 'Net you owe: ${egp(-net)}'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: net >= 0 ? scheme.primary : scheme.error),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_debts.isEmpty)
                    EmptyHint(
                        icon: Icons.handshake_outlined,
                        actionLabel: tr('سجّل دين', 'Log a debt'),
                        onAction: _addDebt,
                        text:
                            tr('مفيش ديون متسجلة — سجل اللي ليك واللي عليك\nوبالصوت كمان: «سلفت أحمد ٢٠٠»',
                                'No debts yet — log what you owe and what you\'re owed\nvoice too: "سلفت أحمد ٢٠٠"'))
                  else
                    ..._debts.map((d) => _debtTile(context, d)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debt_fab',
        onPressed: _addDebt,
        icon: const Icon(Icons.add),
        label: Text(tr('دين جديد', 'New debt')),
      ),
    );
  }

  Widget _statBox(
      BuildContext context, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(egp(value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _debtTile(BuildContext context, Debt d) {
    final scheme = Theme.of(context).colorScheme;
    final color = d.theyOweMe ? scheme.primary : scheme.error;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
              d.theyOweMe ? Icons.south_west : Icons.north_east,
              color: color),
        ),
        title: Text(d.person),
        subtitle: Text(
            '${d.theyOweMe ? tr('ليك عنده', 'owes you') : tr('عليك له', 'you owe')}${d.note.isEmpty ? '' : ' • ${d.note}'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(egp(d.amount),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'settle':
                    await _repo.setSettled(d.id!, true);
                    if (mounted) await _load();
                  case 'delete':
                    await _repo.delete(d.id!);
                    if (mounted) await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'settle', child: Text(tr('اتسددت ✓', 'Settled ✓'))),
                PopupMenuItem(
                    value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
