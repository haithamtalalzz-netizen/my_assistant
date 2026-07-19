import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/leave_repo.dart';
import '../data/settings_repo.dart';
import '../widgets/common.dart';

/// «رصيد الإجازات» — كام يوم إجازة فاضل من رصيدك السنوى + سجل اللى اتاخد.
class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen> {
  final _repo = LeaveRepo();
  final _settings = SettingsRepo();
  bool _loading = true;
  int _entitlement = 21;
  double _taken = 0;
  List<LeaveEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _entitlement =
        int.tryParse(await _settings.get('annual_leave_entitlement') ?? '') ??
            21;
    _entries = await _repo.forYear();
    _taken = await _repo.takenInYear();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _fmtDays(double d) =>
      d == d.roundToDouble() ? arNum(d.round()) : arNum(d.toStringAsFixed(1));

  Future<void> _editEntitlement() async {
    final ctrl = TextEditingController(text: _entitlement.toString());
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('رصيدك السنوى (أيام)', 'Annual entitlement (days)')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, int.tryParse(toEnglishDigits(ctrl.text.trim()))),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    if (v != null && v > 0) {
      await _settings.set('annual_leave_entitlement', v.toString());
      setState(() => _entitlement = v);
    }
  }

  Future<void> _addLeave() async {
    var date = DateTime.now();
    final daysC = TextEditingController(text: '1');
    var kind = kLeaveKinds.first;
    final noteC = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('تسجيل إجازة', 'Log leave'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text('${tr('التاريخ', 'Date')}: ${arShortDate(date)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(date.year - 1),
                    lastDate: DateTime(date.year + 1, 12, 31),
                  );
                  if (d != null) setSheet(() => date = d);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: daysC,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: tr('عدد الأيام', 'Days'),
                    helperText: tr('نص يوم = 0.5', 'Half day = 0.5')),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final k in kLeaveKinds)
                    ChoiceChip(
                      label: Text(k),
                      selected: kind == k,
                      onSelected: (_) => setSheet(() => kind = k),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteC,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: tr('ملاحظة (اختيارى)', 'Note (optional)')),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      final days = double.tryParse(toEnglishDigits(daysC.text.trim())) ?? 1;
      if (days > 0) {
        await _repo.add(dayKey(date), days, kind: kind, note: noteC.text.trim());
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = _entitlement - _taken;
    final ratio =
        _entitlement > 0 ? (_taken / _entitlement).clamp(0.0, 1.0) : 0.0;
    final low = remaining <= 3;
    return Scaffold(
      appBar: AppBar(title: Text(tr('رصيد الإجازات', 'Leave balance'))),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addLeave,
              icon: const Icon(Icons.add),
              label: Text(tr('تسجيل إجازة', 'Log leave')),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text('${tr('المتبقّى هذا العام', 'Remaining this year')} '
                      '(${arNum(DateTime.now().year)})'),
                  const SizedBox(height: 6),
                  Text('${_fmtDays(remaining)} ${tr('يوم', 'days')}',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: low ? const Color(0xFFCC8A2E) : scheme.primary)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: ratio, minHeight: 8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _editEntitlement,
                        child: Text(
                            '${tr('الرصيد', 'Entitlement')}: ${arNum(_entitlement)} ✎',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      Text('${tr('المأخوذ', 'Taken')}: ${_fmtDays(_taken)}',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              if (_entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyHint(
                    icon: Icons.beach_access_outlined,
                    text: tr(
                        'مسجّلتش أى إجازة السنة دى — سجّل إجازاتك عشان تتابع رصيدك.',
                        'No leave logged this year — log your leave to track the balance.'),
                  ),
                )
              else
                for (final e in _entries) _entryRow(scheme, e),
            ]),
    );
  }

  Widget _entryRow(ColorScheme scheme, LeaveEntry e) {
    final d = DateTime.tryParse(e.day);
    return SwipeToDelete(
      id: e.id ?? e.day,
      onDelete: () async {
        if (e.id != null) await _repo.delete(e.id!);
        await _load();
      },
      onUndo: () async {
        await _repo.add(e.day, e.days, kind: e.kind, note: e.note);
        await _load();
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: Text(_fmtDays(e.days),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer)),
          ),
          title: Text(e.kind.isEmpty ? tr('إجازة', 'Leave') : e.kind),
          subtitle: Text([
            if (d != null) arShortDate(d),
            if (e.note.isNotEmpty) e.note,
          ].join(' • ')),
        ),
      ),
    );
  }
}
