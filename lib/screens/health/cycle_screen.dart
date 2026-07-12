import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/cycle_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// تتبّع الدورة الشهرية للسيدات — تسجيل البدايات + توقّع الدورة الجاية وأيام الخصوبة.
class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  final _repo = CycleRepo();
  bool _loading = true;
  CyclePrediction _pred = const CyclePrediction();
  List<CycleLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _repo.all();
    final pred = await _repo.predict();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _pred = pred;
      _loading = false;
    });
  }

  Future<void> _logStart({DateTime? initial}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: tr('اختاري يوم بداية الدورة', 'Pick the period start day'),
    );
    if (picked == null) return;
    await _repo.add(CycleLog(
      startDay: dayKey(picked),
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('الدورة الشهرية', 'Menstrual cycle'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  _statusCard(context),
                  const SizedBox(height: 12),
                  if (_pred.hasData) _predictionsCard(context),
                  SectionHeader(tr('الدورات المسجّلة', 'Logged periods')),
                  if (_logs.isEmpty)
                    EmptyHint(
                      icon: Icons.favorite_outline,
                      text: tr(
                          'سجّلي يوم بداية دورتك — التطبيق هيحسب الدورة الجاية وأيام الخصوبة',
                          'Log your period start — the app predicts your next period & fertile days'),
                    )
                  else
                    ..._logs.map(_logTile),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cycle_fab',
        onPressed: () => _logStart(),
        icon: const Icon(Icons.add),
        label: Text(tr('سجّلي بداية الدورة', 'Log period start')),
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_pred.hasData) {
      return Card(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Text('🌸', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    tr('سجّلي أول دورة عشان نبدأ نحسبلك',
                        'Log your first period to start predictions'),
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }
    final until = _pred.daysUntilNext ?? 0;
    final phase = _phaseLabel();
    final line = until > 0
        ? tr('باقي $until يوم على الدورة الجاية', '$until days until next period')
        : until == 0
            ? tr('الدورة متوقّعة النهاردة', 'Period expected today')
            : tr('متأخرة ${-until} يوم', '${-until} days late');
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(phase,
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                if (_pred.currentDay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                        tr('يوم ${arNum(_pred.currentDay!)}',
                            'Day ${arNum(_pred.currentDay!)}'),
                        style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(line,
                style: TextStyle(
                    color: scheme.onPrimaryContainer, fontSize: 14)),
            const SizedBox(height: 2),
            Text(
                tr('متوسط طول الدورة: ${arNum(_pred.avgCycleLength)} يوم',
                    'Average cycle: ${arNum(_pred.avgCycleLength)} days'),
                style: TextStyle(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _predictionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _predRow(Icons.event, tr('الدورة الجاية', 'Next period'),
                _pred.nextStart, Colors.pink),
            const Divider(height: 1),
            _predRow(
                Icons.spa_outlined,
                tr('أيام الخصوبة', 'Fertile window'),
                _pred.fertileStart,
                Colors.teal,
                endDate: _pred.fertileEnd),
            const Divider(height: 1),
            _predRow(Icons.brightness_low, tr('يوم التبويض', 'Ovulation'),
                _pred.ovulation, Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _predRow(IconData icon, String label, DateTime? date, Color color,
      {DateTime? endDate}) {
    final scheme = Theme.of(context).colorScheme;
    final text = date == null
        ? '—'
        : endDate != null
            ? '${arShortDate(date)} – ${arShortDate(endDate)}'
            : arShortDate(date);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: scheme.onSurface)),
    );
  }

  Widget _logTile(CycleLog log) {
    final d = DateTime.tryParse(log.startDay);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: const Text('🩸', style: TextStyle(fontSize: 20)),
        title: Text(d != null ? arShortDate(d) : log.startDay),
        subtitle: Text(tr('بداية الدورة', 'Period start')),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            await _repo.delete(log.id!);
            await _load();
          },
        ),
      ),
    );
  }

  String _phaseLabel() {
    final day = _pred.currentDay;
    if (day == null) return tr('دورتك', 'Your cycle');
    final today = dateOnly(DateTime.now());
    final fs = _pred.fertileStart, fe = _pred.fertileEnd;
    if (day <= 5) return tr('فترة الدورة', 'Menstruation');
    if (fs != null &&
        fe != null &&
        !today.isBefore(fs) &&
        !today.isAfter(fe)) {
      return tr('أيام الخصوبة', 'Fertile days');
    }
    return tr('الفترة العادية', 'Regular phase');
  }
}
