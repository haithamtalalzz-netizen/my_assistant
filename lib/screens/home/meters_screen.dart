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

  Widget _meterCard(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;
    final list = _byType[type] ?? [];
    final latest = list.isNotEmpty ? list.first : null;
    // الاستهلاك = آخر قراءة − اللي قبلها.
    double? consumption;
    if (list.length >= 2) consumption = list[0].reading - list[1].reading;
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
                Text(
                    tr('الاستهلاك عن اللي قبلها: ${arNum(consumption % 1 == 0 ? consumption.toInt() : consumption.toStringAsFixed(1))}',
                        'Consumption vs previous: ${arNum(consumption % 1 == 0 ? consumption.toInt() : consumption.toStringAsFixed(1))}'),
                    style: TextStyle(color: scheme.outline, fontSize: 13)),
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
