import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/cycle_report.dart';
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
  String _mode = 'normal'; // normal / ttc / pregnant
  int _calOffset = 0; // شهر التقويم (0 = الحالي)
  CyclePrediction _pred = const CyclePrediction();
  List<CycleLog> _logs = [];
  CycleDay? _today;
  List<CycleDay> _recentDays = [];
  List<PhaseInsight> _insights = [];
  bool _pillOn = false;
  String _pillTime = '21:00';
  bool _pillTakenToday = false;
  int _pillStreak = 0;
  List<int> _intervals = [];
  CycleHealthLink _health = const CycleHealthLink();

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
    final mode = await _settings.get('cycle_mode') ?? 'normal';
    final insights = await _repo.phaseInsights();
    final pillOn = await _settings.get('pill_reminder') == '1';
    final pillTime = await _settings.get('pill_time') ?? '21:00';
    final pillTaken = await _repo.pillTakenOn(dayKey(DateTime.now()));
    final pillStreak = await _repo.pillStreak();
    final intervals = await _repo.cycleIntervals();
    final health = await _repo.phaseHealth();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _pred = pred;
      _today = today;
      _recentDays = recentDays;
      _remindersOn = remindersOn;
      _mode = mode;
      _insights = insights;
      _pillOn = pillOn;
      _pillTime = pillTime;
      _pillTakenToday = pillTaken;
      _pillStreak = pillStreak;
      _intervals = intervals;
      _health = health;
      _loading = false;
    });
  }

  Future<void> _togglePill(bool on) async {
    await _settings.set('pill_reminder', on ? '1' : '0');
    setState(() => _pillOn = on);
    await _repo.ensureReminders();
  }

  Future<void> _pickPillTime() async {
    final parts = _pillTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 21,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
    );
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _settings.set('pill_time', t);
    setState(() => _pillTime = t);
    await _repo.ensureReminders();
  }

  Future<void> _takePill() async {
    final day = dayKey(DateTime.now());
    await _repo.setPillTaken(day, !_pillTakenToday);
    await _load();
  }

  Future<void> _editPeriodLength(CycleLog log) async {
    var days = log.periodDays;
    final saved = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr('مدة الدورة (أيام)', 'Period length (days)')),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () =>
                      setD(() => days = (days - 1).clamp(1, 14))),
              Text(arNum(days),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () =>
                      setD(() => days = (days + 1).clamp(1, 14))),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, days),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved != null && log.id != null) {
      await _repo.updatePeriodLength(log.id!, saved);
      await _load();
    }
  }

  Future<void> _setMode(String m) async {
    await _settings.set('cycle_mode', m);
    setState(() => _mode = m);
  }

  int? _pregnancyWeek() {
    final lmp = _pred.lastStart;
    if (lmp == null) return null;
    final days = dateOnly(DateTime.now()).difference(lmp).inDays;
    if (days < 0 || days > 320) return null;
    return (days ~/ 7) + 1;
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
            tooltip: tr('تقرير PDF للطبيبة', 'PDF report for doctor'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              await CycleReport.generateAndShare();
            },
          ),
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
                  _modeSelector(context),
                  const SizedBox(height: 12),
                  if (_mode == 'pregnant')
                    _pregnancyCard(context)
                  else ...[
                    _statusCard(context),
                    if (_pred.hasData && (_pred.daysUntilNext ?? 0) <= -3) ...[
                      const SizedBox(height: 8),
                      _lateCard(context),
                    ],
                    if (_mode == 'ttc' && _pred.hasData) ...[
                      const SizedBox(height: 8),
                      _ttcBanner(context),
                    ],
                    const SizedBox(height: 12),
                    if (_pred.hasData) _predictionsCard(context),
                    const SizedBox(height: 12),
                    _calendarCard(context),
                  ],
                  const SizedBox(height: 4),
                  _todayLogCard(context),
                  const SizedBox(height: 4),
                  _pillCard(context),
                  if (_intervals.length >= 2) ...[
                    SectionHeader(tr('انتظام الدورة', 'Cycle regularity')),
                    _regularityCard(context),
                  ],
                  if (_insights.isNotEmpty) ...[
                    SectionHeader(
                        tr('أنماط الأعراض والمزاج', 'Symptom & mood patterns')),
                    _patternsCard(context),
                  ],
                  if (_health.hasAny) ...[
                    SectionHeader(tr('الدورة وصحتك', 'Cycle & your health')),
                    _healthLinkCard(context),
                  ],
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

  Widget _lateCard(BuildContext context) {
    final late = -(_pred.daysUntilNext ?? 0);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                tr('دورتك متأخرة ${arNum(late)} يوم — سجّليها أول ما تنزل، أو لو حابة تطمني اعملي اختبار حمل.',
                    'Period ${arNum(late)} days late — log it when it comes, or take a pregnancy test to be sure.'),
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }

  Widget _pillCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Text('💊', style: TextStyle(fontSize: 22)),
            title: Text(tr('حبوب منع الحمل', 'Birth-control pill')),
            subtitle: Text(_pillOn
                ? tr('تذكير يومي الساعة $_pillTime', 'Daily reminder at $_pillTime')
                : tr('تذكير يومي في معاد ثابت', 'A daily reminder')),
            value: _pillOn,
            onChanged: _togglePill,
          ),
          if (_pillOn) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.schedule),
              title: Text(tr('معاد التذكير', 'Reminder time')),
              trailing: TextButton(
                  onPressed: _pickPillTime, child: Text(_pillTime)),
            ),
            ListTile(
              dense: true,
              leading: Icon(
                  _pillTakenToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _pillTakenToday ? Colors.green : scheme.outline),
              title: Text(_pillTakenToday
                  ? tr('خدتي حبة النهاردة ✓', 'Taken today ✓')
                  : tr('خدتي حبة النهاردة؟', 'Taken your pill today?')),
              subtitle: _pillStreak > 0
                  ? Text(tr('${arNum(_pillStreak)} يوم متتالي 🔥',
                      '${arNum(_pillStreak)}-day streak 🔥'))
                  : null,
              trailing: FilledButton(
                onPressed: _takePill,
                child: Text(_pillTakenToday
                    ? tr('تراجع', 'Undo')
                    : tr('خدتها', 'Took it')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _regularityCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iv = _intervals;
    final minV = iv.reduce((a, b) => a < b ? a : b);
    final maxV = iv.reduce((a, b) => a > b ? a : b);
    final regular = (maxV - minV) <= 5;
    final maxY = (maxV + 4).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(regular ? Icons.check_circle : Icons.info_outline,
                    color: regular ? Colors.green : Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                    regular
                        ? tr('دورتك منتظمة', 'Your cycle is regular')
                        : tr('دورتك غير منتظمة شوية',
                            'Your cycle is a bit irregular'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
                tr('أقصر: ${arNum(minV)} يوم · أطول: ${arNum(maxV)} يوم',
                    'Shortest: ${arNum(minV)}d · Longest: ${arNum(maxV)}d'),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 10,
                            getTitlesWidget: (v, _) => Text(arNum(v.toInt()),
                                style: const TextStyle(fontSize: 9)))),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (var i = 0; i < iv.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                            toY: iv[i].toDouble(),
                            width: 12,
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(3)),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthLinkCard(BuildContext context) {
    final h = _health;
    final scheme = Theme.of(context).colorScheme;
    Widget row(String label, double? sens, double? rest, String unit) {
      if (sens == null || rest == null) return const SizedBox.shrink();
      final diff = sens - rest;
      final up = diff > 0;
      final arrow = diff.abs() < 0.1 ? '≈' : (up ? '↑' : '↓');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
                '${sens.toStringAsFixed(1)} $unit',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Text(arrow,
                style: TextStyle(
                    color: arrow == '↑'
                        ? Colors.orange
                        : arrow == '↓'
                            ? Colors.blue
                            : scheme.outline,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Text('(${rest.toStringAsFixed(1)})',
                style: TextStyle(fontSize: 12, color: scheme.outline)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                tr('في الدورة/ما قبل الطمث مقابل باقي الشهر',
                    'During period/PMS vs the rest of the month'),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 6),
            row(tr('النوم', 'Sleep'), h.sleepSensitive, h.sleepRest,
                tr('س', 'h')),
            row(tr('المياه', 'Water'), h.waterSensitive, h.waterRest,
                tr('كوب', 'cups')),
            row(tr('الوزن', 'Weight'), h.weightSensitive, h.weightRest,
                tr('كجم', 'kg')),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector(BuildContext context) => Center(
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'normal',
                icon: const Text('🌸'),
                label: Text(tr('متابعة', 'Track'))),
            ButtonSegment(
                value: 'ttc',
                icon: const Text('🌱'),
                label: Text(tr('محاولة حمل', 'TTC'))),
            ButtonSegment(
                value: 'pregnant',
                icon: const Text('👶'),
                label: Text(tr('حمل', 'Pregnancy'))),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _setMode(s.first),
        ),
      );

  Widget _ttcBanner(BuildContext context) {
    final p = _pred;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.fertileStart != null && p.ovulation != null
                  ? tr('أعلى فرص الحمل: ${arShortDate(p.fertileStart!)} – ${arShortDate(p.fertileEnd!)} · التبويض ${arShortDate(p.ovulation!)}',
                      'Best chances: ${arShortDate(p.fertileStart!)} – ${arShortDate(p.fertileEnd!)} · ovulation ${arShortDate(p.ovulation!)}')
                  : tr('سجّلي دوراتك عشان نحسب أيام الخصوبة',
                      'Log your periods to compute fertile days'),
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pregnancyCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final week = _pregnancyWeek();
    final lmp = _pred.lastStart;
    if (week == null || lmp == null) {
      return Card(
        child: ListTile(
          leading: const Text('👶', style: TextStyle(fontSize: 26)),
          title: Text(tr('وضع الحمل', 'Pregnancy mode')),
          subtitle: Text(tr(
              'سجّلي أول يوم في آخر دورة عشان نحسب أسبوع الحمل وموعد الولادة',
              'Log your last period start to compute weeks & due date')),
          trailing: const Icon(Icons.add),
          onTap: () => _logStart(),
        ),
      );
    }
    final due = lmp.add(const Duration(days: 280));
    final left = due.difference(dateOnly(DateTime.now())).inDays;
    final trimester = week <= 13
        ? tr('الأول', 'First')
        : week <= 27
            ? tr('الثاني', 'Second')
            : tr('الثالث', 'Third');
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('👶', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Text(tr('الأسبوع ${arNum(week)} من الحمل', 'Week ${arNum(week)}'),
                  style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Text(tr('الثلث $trimester من الحمل', '$trimester trimester'),
                style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 2),
            Text(
                tr('موعد الولادة المتوقّع: ${arShortDate(due)}',
                    'Due date: ${arShortDate(due)}'),
                style: TextStyle(color: scheme.onPrimaryContainer)),
            if (left >= 0)
              Text(tr('باقي ${arNum(left)} يوم تقريبًا', '~${arNum(left)} days left'),
                  style: TextStyle(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                      fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _patternsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final ins in _insights)
            ListTile(
              dense: true,
              title: Text(
                  '${phaseName(ins.phase)}  (${arNum(ins.days)} ${tr('يوم', 'days')})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([
                if (ins.topMood != null)
                  '${moodEmoji(ins.topMood!)} ${moodLabel(ins.topMood!)}',
                for (final s in ins.topSymptoms) symptomLabel(s.key),
              ].join(' · ')),
            ),
        ],
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
        subtitle: Text(tr('بداية الدورة · المدة ${arNum(log.periodDays)} أيام',
            'Period start · ${arNum(log.periodDays)} days')),
        onTap: () => _editPeriodLength(log),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            await _repo.delete(log.id!);
            await _load();
            await _repo.ensureReminders();
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
