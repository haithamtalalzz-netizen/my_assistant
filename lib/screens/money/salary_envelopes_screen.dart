import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/salary_plan.dart';
import '../../data/settings_repo.dart';

/// «أظرف المرتب» — وزّع مرتبك يوم القبض على أظرف (التزامات/مصاريف/ادخار)
/// بالنسبة المئوية + عدّاد تنازلي ليوم القبض. الإعداد كله في الإعدادات (بدون DB).
class SalaryEnvelopesScreen extends StatefulWidget {
  const SalaryEnvelopesScreen({super.key});

  @override
  State<SalaryEnvelopesScreen> createState() => _SalaryEnvelopesScreenState();
}

class _SalaryEnvelopesScreenState extends State<SalaryEnvelopesScreen> {
  final _settings = SettingsRepo();
  bool _loading = true;
  double _salary = 0;
  int _payday = 25;
  List<SalaryEnvelope> _envelopes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _salary = double.tryParse(await _settings.get('salary_amount') ?? '') ?? 0;
    _payday = int.tryParse(await _settings.get('salary_payday') ?? '') ?? 25;
    _envelopes = parseEnvelopes(await _settings.get('salary_envelopes'));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _persist() async {
    await _settings.set('salary_amount', _salary.toStringAsFixed(0));
    await _settings.set('salary_payday', _payday.toString());
    await _settings.set('salary_envelopes', encodeEnvelopes(_envelopes));
  }

  String _money(double v) => '${arNum(v.round())} ${tr('ج', 'EGP')}';

  Future<double?> _askNumber(String title, double current,
      {String hint = ''}) async {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, double.tryParse(toEnglishDigits(ctrl.text.trim()))),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    return v;
  }

  Future<SalaryEnvelope?> _editEnvelope(SalaryEnvelope? e) async {
    final nameC = TextEditingController(text: e?.name ?? '');
    final pctC =
        TextEditingController(text: e != null ? e.percent.toStringAsFixed(0) : '');
    return showDialog<SalaryEnvelope>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(e == null ? tr('ظرف جديد', 'New envelope') : tr('تعديل', 'Edit')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameC,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: tr('الاسم', 'Name')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: pctC,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: tr('النسبة %', 'Percent %')),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
            onPressed: () {
              final name = nameC.text.trim();
              final pct = double.tryParse(toEnglishDigits(pctC.text.trim())) ?? 0;
              if (name.isEmpty) return;
              Navigator.pop(ctx, SalaryEnvelope(name, pct));
            },
            child: Text(tr('حفظ', 'Save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: Text(tr('أظرف المرتب', 'Salary envelopes'))),
          body: const Center(child: CircularProgressIndicator()));
    }
    final total = totalPercent(_envelopes);
    final days = daysUntilPayday(_payday, DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(tr('أظرف المرتب', 'Salary envelopes'))),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // عدّاد القبض
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text('💰', style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              days == 0
                  ? tr('النهاردة يوم القبض! 🎉', "Today is payday! 🎉")
                  : tr('فاضل ${arNum(days)} يوم على القبض',
                      '${arNum(days)} days to payday'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // المرتب + يوم القبض
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(tr('المرتب الشهرى', 'Monthly salary')),
              trailing: Text(_salary > 0 ? _money(_salary) : tr('اضبط', 'Set'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final v = await _askNumber(
                    tr('المرتب الشهرى', 'Monthly salary'), _salary);
                if (v != null) {
                  setState(() => _salary = v);
                  await _persist();
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(tr('يوم القبض من الشهر', 'Payday (day of month)')),
              trailing: Text(arNum(_payday),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final v = await _askNumber(
                    tr('يوم القبض (١–٣١)', 'Payday (1–31)'), _payday.toDouble());
                if (v != null) {
                  setState(() => _payday = v.round().clamp(1, 31));
                  await _persist();
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Text(tr('الأظرف', 'Envelopes'),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: scheme.primary)),
          const Spacer(),
          _totalChip(scheme, total),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < _envelopes.length; i++) _envelopeCard(scheme, i),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final e = await _editEnvelope(null);
                if (e != null) {
                  setState(() => _envelopes.add(e));
                  await _persist();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(tr('إضافة ظرف', 'Add envelope')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                setState(() => _envelopes = List.of(kDefaultEnvelopes));
                await _persist();
              },
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: Text(tr('التوزيع المقترح', 'Suggested')),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _totalChip(ColorScheme scheme, double total) {
    final ok = (total - 100).abs() < 0.01;
    final c = ok ? const Color(0xFF16A34A) : const Color(0xFFCC8A2E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(20)),
      child: Text('${tr('المجموع', 'Total')} ${arNum(total.round())}%',
          style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _envelopeCard(ColorScheme scheme, int i) {
    final e = _envelopes[i];
    final amount = _salary * e.percent / 100;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${arNum(e.percent.round())}%'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_salary > 0)
            Text(_money(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: scheme.primary)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              final ed = await _editEnvelope(e);
              if (ed != null) {
                setState(() => _envelopes[i] = ed);
                await _persist();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 20, color: scheme.error),
            onPressed: () async {
              setState(() => _envelopes.removeAt(i));
              await _persist();
            },
          ),
        ]),
      ),
    );
  }
}
