import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/cycle_repo.dart';
import '../../data/settings_repo.dart';
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
  final _settings = SettingsRepo();
  bool _loading = true;
  bool _remindersOn = true;
  int _calOffset = 0; // شهر التقويم (0 = الحالي)
  CyclePrediction _pred = const CyclePrediction();
  List<CycleLog> _logs = [];
  CycleDay? _today;
  List<CycleDay> _recentDays = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _repo.all();
    final pred = await _repo.predict();
    final today = await _repo.dayLog(dayKey(DateTime.now()));
    final recentDays = await _repo.recentDays(limit: 14);
    final remindersOn = await _settings.get('cycle_reminders') != '0';
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _pred = pred;
      _today = today;
      _recentDays = recentDays;
      _remindersOn = remindersOn;
      _loading = false;
    });
  }

  Future<void> _toggleReminders() async {
    final on = !_remindersOn;
    await _settings.set('cycle_reminders', on ? '1' : '0');
    setState(() => _remindersOn = on);
    await _repo.ensureReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(on
              ? tr('تذكيرات الدورة اتفعّلت', 'Cycle reminders on')
              : tr('تذكيرات الدورة اتوقفت', 'Cycle reminders off'))));
    }
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
    await _repo.ensureReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('الدورة الشهرية', 'Menstrual cycle')),
        actions: [
          IconButton(
            tooltip: _remindersOn
                ? tr('تذكيرات الدورة: شغّالة', 'Cycle reminders: on')
                : tr('تذكيرات الدورة: موقوفة', 'Cycle reminders: off'),
            icon: Icon(_remindersOn
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined),
            onPressed: _toggleReminders,
          ),
        ],
      ),
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
                  const SizedBox(height: 12),
                  _calendarCard(context),
                  const SizedBox(height: 4),
                  _todayLogCard(context),
                  if (_recentDays.isNotEmpty) ...[
                    SectionHeader(tr('تسجيلاتك اليومية', 'Your daily logs')),
                    ..._recentDays.map(_dayTile),
                  ],
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

  Widget _todayLogCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _today;
    final has = t != null &&
        (t.mood.isNotEmpty ||
            t.symptoms.isNotEmpty ||
            t.flow.isNotEmpty ||
            t.weight != null ||
            t.note.isNotEmpty);
    return Card(
      child: ListTile(
        leading: Text(has && t.mood.isNotEmpty ? moodEmoji(t.mood) : '📝',
            style: const TextStyle(fontSize: 24)),
        title: Text(tr('تسجيل اليوم', "Today's log")),
        subtitle: Text(has
            ? [
                if (t.mood.isNotEmpty) moodLabel(t.mood),
                if (t.flow.isNotEmpty) flowLabel(t.flow),
                if (t.symptomList.isNotEmpty)
                  '${t.symptomList.length} ${tr('عرض', 'symptoms')}',
                if (t.weight != null) '${t.weight} ${tr('كجم', 'kg')}',
              ].join(' · ')
            : tr('سجّلي مزاجك وأعراضك ووزنك النهاردة',
                'Log your mood, symptoms & weight today')),
        trailing: Icon(Icons.edit_outlined, color: scheme.primary),
        onTap: () => _editDay(_today, dayKey(DateTime.now())),
      ),
    );
  }

  Widget _dayTile(CycleDay d) {
    final date = DateTime.tryParse(d.day);
    final parts = [
      if (d.flow.isNotEmpty) flowLabel(d.flow),
      for (final s in d.symptomList) symptomLabel(s),
      if (d.weight != null) '${d.weight} ${tr('كجم', 'kg')}',
    ];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(d.mood.isNotEmpty ? moodEmoji(d.mood) : '📝',
            style: const TextStyle(fontSize: 20)),
        title: Text(date != null ? arShortDate(date) : d.day),
        subtitle: parts.isEmpty
            ? (d.mood.isNotEmpty ? Text(moodLabel(d.mood)) : null)
            : Text(parts.join(' · '),
                maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _editDay(d, d.day),
      ),
    );
  }

  Future<void> _editDay(CycleDay? existing, String day) async {
    var mood = existing?.mood ?? '';
    final symptoms = {...?existing?.symptomList};
    var flow = existing?.flow ?? '';
    final weightCtrl = TextEditingController(
        text: existing?.weight != null ? '${existing!.weight}' : '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.82,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(tr('تسجيل اليوم', "Today's log"),
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _sheetLabel(tr('المزاج / الحالة النفسية', 'Mood')),
                Wrap(spacing: 6, children: [
                  for (final m in kMoods)
                    ChoiceChip(
                      label: Text('${moodEmoji(m)} ${moodLabel(m)}'),
                      selected: mood == m,
                      onSelected: (_) =>
                          setSheet(() => mood = mood == m ? '' : m),
                    ),
                ]),
                const SizedBox(height: 14),
                _sheetLabel(tr('الأعراض', 'Symptoms')),
                Wrap(spacing: 6, children: [
                  for (final s in kSymptoms)
                    FilterChip(
                      label: Text(symptomLabel(s)),
                      selected: symptoms.contains(s),
                      onSelected: (on) => setSheet(() =>
                          on ? symptoms.add(s) : symptoms.remove(s)),
                    ),
                ]),
                const SizedBox(height: 14),
                _sheetLabel(tr('شدة النزيف', 'Flow')),
                Wrap(spacing: 6, children: [
                  for (final f in kFlows)
                    ChoiceChip(
                      label: Text(flowLabel(f)),
                      selected: flow == f,
                      onSelected: (_) =>
                          setSheet(() => flow = flow == f ? '' : f),
                    ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tr('الوزن (كجم)', 'Weight (kg)'),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: tr('ملاحظة', 'Note'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await _repo.saveDay(CycleDay(
                      day: day,
                      mood: mood,
                      symptoms: symptoms.join(','),
                      flow: flow,
                      weight: parseNumber(weightCtrl.text),
                      note: noteCtrl.text.trim(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(tr('حفظ', 'Save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    weightCtrl.dispose();
    noteCtrl.dispose();
    await _load();
  }

  Widget _sheetLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  // ---- تقويم ملوّن ----
  static const _cPeriod = Color(0xFFE0567A); // دورة فعلية
  static const _cPredicted = Color(0xFFF3AEC0); // دورة متوقّعة
  static const _cOvulation = Color(0xFF8B5CF6); // تبويض
  static const _cFertile = Color(0xFF2DD4BF); // خصوبة
  static const _cPms = Color(0xFFF59E0B); // ما قبل الطمث

  Set<String> _actualPeriodDays() {
    final s = <String>{};
    for (final l in _logs) {
      final start = DateTime.tryParse(l.startDay);
      if (start == null) continue;
      for (var i = 0; i < l.periodDays; i++) {
        s.add(dayKey(start.add(Duration(days: i))));
      }
    }
    return s;
  }

  Color? _phaseColor(DateTime date, Set<String> actual) {
    final d = dateOnly(date);
    if (actual.contains(dayKey(d))) return _cPeriod;
    final p = _pred;
    bool between(DateTime? a, DateTime? b) =>
        a != null && b != null && !d.isBefore(a) && !d.isAfter(b);
    // دورة متوقّعة (nextStart .. +5)
    if (p.nextStart != null &&
        between(p.nextStart, p.nextStart!.add(const Duration(days: 4)))) {
      return _cPredicted;
    }
    if (p.ovulation != null && dayKey(p.ovulation!) == dayKey(d)) {
      return _cOvulation;
    }
    if (between(p.fertileStart, p.fertileEnd)) return _cFertile;
    // ما قبل الطمث: 5 أيام قبل الدورة الجاية
    if (p.nextStart != null &&
        between(p.nextStart!.subtract(const Duration(days: 5)),
            p.nextStart!.subtract(const Duration(days: 1)))) {
      return _cPms;
    }
    return null;
  }

  Widget _calendarCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final month = DateTime(now.year, now.month + _calOffset, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstCol = (month.weekday - 6 + 7) % 7;
    final actual = _actualPeriodDays();
    const dayLetters = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    final cells = <Widget>[];
    for (var i = 0; i < firstCol; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final color = _phaseColor(date, actual);
      final isToday = dayKey(date) == dayKey(now);
      cells.add(Center(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: scheme.primary, width: 2)
                : null,
          ),
          child: Text('$day',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: color != null ? Colors.white : scheme.onSurface)),
        ),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _calOffset--)),
                Expanded(
                  child: Text(arMonth(month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _calOffset++)),
              ],
            ),
            Row(
              children: [
                for (final l in dayLetters)
                  Expanded(
                    child: Center(
                      child: Text(l,
                          style: TextStyle(
                              fontSize: 11, color: scheme.outline)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              children: cells,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _legend(_cPeriod, tr('الدورة', 'Period')),
                _legend(_cPredicted, tr('متوقّعة', 'Predicted')),
                _legend(_cFertile, tr('خصوبة', 'Fertile')),
                _legend(_cOvulation, tr('تبويض', 'Ovulation')),
                _legend(_cPms, tr('ما قبل الطمث', 'PMS')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

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
