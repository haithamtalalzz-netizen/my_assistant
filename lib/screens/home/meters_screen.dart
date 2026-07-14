import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/meters_repo.dart';
import '../../models/models.dart';
import '../../widgets/search_action.dart';

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> {
  final _repo = MetersRepo();
  bool _loading = true;
  final Map<String, List<MeterReading>> _byType = {};

  @override
  void initState() {
    super.initState();
    _repo.ensureMonthlyReminder();
    _load();
  }

  Future<void> _load() async {
    _byType.clear();
    for (final t in kMeterTypes) {
      _byType[t] = await _repo.forType(t);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  IconData _iconFor(String t) => switch (t) {
        'electricity' => Icons.bolt,
        'water' => Icons.water_drop,
        'gas' => Icons.local_fire_department,
        _ => Icons.speed,
      };

  Future<void> _addReading(String type) async {
    final reading = TextEditingController();
    final cost = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          scrollable: true,
        title: Text(tr('قراءة ${meterTypeLabel(type)}',
            '${meterTypeLabel(type)} reading')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reading,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: tr('القراءة', 'Reading')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('التكلفة (اختياري)', 'Cost (optional)')),
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
      final r = parseNumber(reading.text);
      if (r != null) {
        await _repo.add(MeterReading(
          meterType: type,
          reading: r,
          cost: parseNumber(cost.text),
          day: dayKey(DateTime.now()),
        ));
        if (mounted) await _load();
      }
    }
    reading.dispose();
    cost.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('قراءات العدادات', 'Meter readings')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              children: [
                for (final t in kMeterTypes) _meterCard(context, t),
              ],
            ),
    );
  }

  /// رسم الاستهلاك (بارات) + تقدير الفاتورة (متوسط × سعر الوحدة).
  Widget _consumptionSection(String type, ColorScheme scheme) {
    return FutureBuilder<List<({String day, double delta})>>(
      future: _repo.consumptions(type),
      builder: (context, snap) {
        final cons = snap.data ?? const [];
        if (cons.length < 2) return const SizedBox.shrink();
        final maxV =
            cons.fold<double>(0, (m, c) => c.delta > m ? c.delta : m);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('الاستهلاك حسب الفترة', 'Consumption by period'),
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
              const SizedBox(height: 4),
              for (final c in cons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 52,
                          child: Text(arShortDate(DateTime.parse(c.day)),
                              style: const TextStyle(fontSize: 10))),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (_, bc) => Stack(
                            children: [
                              Container(
                                height: 14,
                                decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(7)),
                              ),
                              Container(
                                height: 14,
                                width: maxV == 0
                                    ? 0
                                    : bc.maxWidth * (c.delta / maxV),
                                decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 42,
                        child: Text(
                            arNum(c.delta % 1 == 0
                                ? c.delta.toInt()
                                : c.delta.toStringAsFixed(1)),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              FutureBuilder<double>(
                future: _repo.estimateBill(type),
                builder: (_, est) {
                  final e = est.data ?? 0;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                            e > 0
                                ? tr('تقدير الفاتورة الجاية: ${egp(e)}',
                                    'Estimated next bill: ${egp(e)}')
                                : tr('حدّد سعر الوحدة لتقدير الفاتورة',
                                    'Set a unit price to estimate the bill'),
                            style: TextStyle(
                                fontSize: 12,
                                color: e > 0 ? scheme.primary : scheme.outline,
                                fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () => _setRate(type),
                        child: Text(tr('السعر', 'Price')),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setRate(String type) async {
    final current = await _repo.rate(type);
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(2) : '');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('سعر وحدة ${meterTypeLabel(type)}',
            '${meterTypeLabel(type)} unit price')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: tr('السعر لكل وحدة (ج.م)', 'Price per unit (EGP)')),
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
      await _repo.setRate(
          type, double.tryParse(toEnglishDigits(ctrl.text.trim())) ?? 0);
      if (mounted) setState(() {});
    }
    ctrl.dispose();
  }

  Widget _meterCard(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;
    final list = _byType[type] ?? [];
    final latest = list.isNotEmpty ? list.first : null;
    // الاستهلاك = آخر قراءة − اللي قبلها.
    double? consumption;
    if (list.length >= 2) consumption = list[0].reading - list[1].reading;
    // مقارنة بالفترة اللي قبلها (استهلكت أكتر ولا أقل؟).
    double? prevConsumption;
    if (list.length >= 3) prevConsumption = list[1].reading - list[2].reading;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(type), color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(meterTypeLabel(type),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _addReading(type),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr('قراءة', 'Reading')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (latest == null)
              Text(tr('مفيش قراءات لسه', 'No readings yet'),
                  style: TextStyle(color: scheme.outline))
            else ...[
              Text(
                  tr('آخر قراءة: ${arNum(latest.reading % 1 == 0 ? latest.reading.toInt() : latest.reading)} '
                      '(${arShortDate(DateTime.parse(latest.day))})',
                      'Last: ${arNum(latest.reading % 1 == 0 ? latest.reading.toInt() : latest.reading)} '
                      '(${arShortDate(DateTime.parse(latest.day))})')),
              if (consumption != null)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                          tr('الاستهلاك: ${arNum(consumption % 1 == 0 ? consumption.toInt() : consumption.toStringAsFixed(1))}',
                              'Consumption: ${arNum(consumption % 1 == 0 ? consumption.toInt() : consumption.toStringAsFixed(1))}'),
                          style: TextStyle(color: scheme.outline, fontSize: 13)),
                    ),
                    if (prevConsumption != null &&
                        consumption != prevConsumption) ...[
                      const SizedBox(width: 6),
                      Icon(
                          consumption > prevConsumption
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          // استهلاك أعلى = أحمر، أقل = أخضر.
                          color: consumption > prevConsumption
                              ? scheme.error
                              : Colors.green),
                    ],
                  ],
                ),
              if (list.length >= 2) _consumptionSection(type, scheme),
              if (list.length > 1)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => _showHistory(type, list),
                    child: Text(tr('السجل (${arNum(list.length)})',
                        'History (${arNum(list.length)})')),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showHistory(String type, List<MeterReading> list) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(meterTypeLabel(type),
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final r in list)
              ListTile(
                dense: true,
                title: Text(arNum(
                    r.reading % 1 == 0 ? r.reading.toInt() : r.reading)),
                subtitle: Text([
                  arShortDate(DateTime.parse(r.day)),
                  if (r.cost != null) egp(r.cost!),
                ].join(' • ')),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    await _repo.delete(r.id!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) await _load();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
