import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/worship_extras_repo.dart';
import '../../widgets/common.dart';

/// تتبّع الصدقات — سجّل صدقاتك وحدّد هدفًا شهريًّا.
class SadaqahScreen extends StatefulWidget {
  const SadaqahScreen({super.key});

  @override
  State<SadaqahScreen> createState() => _SadaqahScreenState();
}

class _SadaqahScreenState extends State<SadaqahScreen> {
  final _repo = WorshipExtrasRepo();
  List<SadaqahEntry> _list = [];
  double _month = 0;
  double _goal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.sadaqat();
    final month = await _repo.sadaqahThisMonth();
    final goal = await _repo.sadaqahGoal();
    if (!mounted) return;
    setState(() {
      _list = list;
      _month = month;
      _goal = goal;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(tr('صدقة جديدة', 'New charity')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: tr('المبلغ', 'Amount')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              decoration: InputDecoration(
                  labelText: tr('لمين / ملاحظة (اختيارى)',
                      'To whom / note (optional)')),
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
    if (ok == true) {
      final v = parseNumber(amount.text) ?? 0;
      await _repo.addSadaqah(v, note.text);
      if (mounted) await _load();
    }
    amount.dispose();
    note.dispose();
  }

  Future<void> _editGoal() async {
    final ctrl =
        TextEditingController(text: _goal > 0 ? _goal.toStringAsFixed(0) : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('الهدف الشهرى', 'Monthly goal')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: tr('المبلغ', 'Amount')),
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
    if (ok == true) {
      await _repo.setSadaqahGoal(parseNumber(ctrl.text) ?? 0);
      if (mounted) await _load();
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('صدقاتى', 'My charity')),
        actions: [
          IconButton(
            tooltip: tr('الهدف الشهرى', 'Monthly goal'),
            icon: const Icon(Icons.flag_outlined),
            onPressed: _editGoal,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _summaryCard(scheme),
                const SizedBox(height: 16),
                if (_list.isEmpty)
                  EmptyHint(
                      icon: Icons.volunteer_activism_outlined,
                      text: tr('سجّل صدقاتك — «وما أنفقتم من شىء فهو يخلفه»',
                          'Log your charity'))
                else ...[
                  Text(tr('السجل', 'Log'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _list.length; i++)
                    _entryTile(i, _list[i], scheme),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'sadaqah_fab',
        onPressed: _add,
        tooltip: tr('صدقة جديدة', 'New charity'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryCard(ColorScheme scheme) {
    final pct = _goal > 0 ? (_month / _goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('صدقات هذا الشهر', "This month's charity"),
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(egp(_month),
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900)),
          if (_goal > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: pct, minHeight: 9),
            ),
            const SizedBox(height: 4),
            Text(
                tr('من هدف ${egp(_goal)} (${arNum((pct * 100).round())}٪)',
                    'of ${egp(_goal)} goal (${arNum((pct * 100).round())}%)'),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: _editGoal,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(tr('حدّد هدفًا شهريًّا', 'Set a monthly goal')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryTile(int i, SadaqahEntry e, ColorScheme scheme) {
    final d = DateTime.tryParse(e.day);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.volunteer_activism, color: scheme.primary),
        title: Text(egp(e.amount),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text([
          if (d != null) arShortDate(d),
          if (e.note.isNotEmpty) e.note,
        ].join(' • '), style: TextStyle(fontSize: 12, color: scheme.outline)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            if (!await confirmDelete(context, tr('الصدقة', 'this entry'))) {
              return;
            }
            await _repo.removeSadaqahAt(i);
            if (mounted) await _load();
          },
        ),
      ),
    );
  }
}
