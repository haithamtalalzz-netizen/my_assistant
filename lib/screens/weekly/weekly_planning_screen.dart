import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/appointments_repo.dart';
import '../../data/weekly_repo.dart';
import '../../models/models.dart';
import '../schedule/appointment_form.dart';

/// طقس التخطيط الأسبوعي — ١٠ دقايق: مراجعة الأسبوع، ٣ أسئلة، تجهيز الجاي.
class WeeklyPlanningScreen extends StatefulWidget {
  const WeeklyPlanningScreen({super.key});

  @override
  State<WeeklyPlanningScreen> createState() => _WeeklyPlanningScreenState();
}

class _WeeklyPlanningScreenState extends State<WeeklyPlanningScreen> {
  final _weekly = WeeklyRepo();
  final _appts = AppointmentsRepo();
  final _wentWell = TextEditingController();
  final _blockedMe = TextEditingController();
  final _nextFocus = TextEditingController();

  int _step = 0;
  bool _loading = true;
  WeekStats? _stats;
  List<Appointment> _overdue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wentWell.dispose();
    _blockedMe.dispose();
    _nextFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final stats = await _weekly.statsForLastWeek(now);
    final all = await _appts.all();
    final startOfToday = dateOnly(now);
    final existing = await _weekly.forWeek(currentWeekKey(now));
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _overdue =
          all.where((a) => !a.done && a.when.isBefore(startOfToday)).toList();
      if (existing != null) {
        _wentWell.text = existing.wentWell;
        _blockedMe.text = existing.blockedMe;
        _nextFocus.text = existing.nextFocus;
      }
      _loading = false;
    });
  }

  Future<void> _finish() async {
    final now = DateTime.now();
    await _weekly.save(WeeklyReview(
      weekKey: currentWeekKey(now),
      wentWell: _wentWell.text.trim(),
      blockedMe: _blockedMe.text.trim(),
      nextFocus: _nextFocus.text.trim(),
      createdAt: now.toIso8601String(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('خطة الأسبوع اتسجلت — أسبوع موفق!',
            'Week plan saved — have a great week!'))));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التخطيط الأسبوعي', 'Weekly planning')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _step,
              onStepContinue: () {
                if (_step < 2) {
                  setState(() => _step++);
                } else {
                  _finish();
                }
              },
              onStepCancel:
                  _step == 0 ? null : () => setState(() => _step--),
              controlsBuilder: (context, details) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(_step == 2
                          ? tr('خلصنا ✓', 'Done ✓')
                          : tr('التالي', 'Next')),
                    ),
                    if (details.onStepCancel != null)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(tr('ارجع', 'Back')),
                      ),
                  ],
                ),
              ),
              steps: [
                Step(
                  title: Text(tr('إزاي كان أسبوعك؟', 'How was your week?')),
                  isActive: _step >= 0,
                  content: _statsStep(context),
                ),
                Step(
                  title: Text(tr('٣ أسئلة سريعة', '3 quick questions')),
                  isActive: _step >= 1,
                  content: _questionsStep(context),
                ),
                Step(
                  title: Text(tr('جهز الأسبوع الجاي', 'Prep next week')),
                  isActive: _step >= 2,
                  content: _planStep(context),
                ),
              ],
            ),
    );
  }

  Widget _statRow(BuildContext context, IconData icon, String label,
      String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statsStep(BuildContext context) {
    final s = _stats!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow(context, Icons.event_available,
            tr('مواعيد اتعملت', 'Appointments done'),
            arNum(s.apptsDone)),
        _statRow(context, Icons.event_busy, tr('مواعيد فاتت', 'Missed'),
            arNum(s.apptsMissed)),
        if (s.habitsPossible > 0)
          _statRow(context, Icons.task_alt,
              tr('التزام العادات', 'Habit adherence'),
              '٪${arNum(s.habitPercent)}'),
        _statRow(context, Icons.account_balance_wallet_outlined,
            tr('مصاريف الأسبوع', 'Week spending'), egp(s.totalSpent)),
        if (s.avgSleep != null)
          _statRow(context, Icons.bedtime_outlined,
              tr('متوسط النوم', 'Avg sleep'),
              tr('${arNum(s.avgSleep!.toStringAsFixed(1))} س',
                  '${arNum(s.avgSleep!.toStringAsFixed(1))} h')),
        if (s.avgWater > 0)
          _statRow(context, Icons.water_drop_outlined,
              tr('متوسط المياه', 'Avg water'),
              tr('${arNum(s.avgWater.toStringAsFixed(1))} كوباية',
                  '${arNum(s.avgWater.toStringAsFixed(1))} glasses')),
        if (s.chronicPostponed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('اتأجلوا كتير — فكر تقسمهم لخطوات أصغر:',
                    'Often postponed — split into smaller steps:'),
                    style: TextStyle(
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600)),
                for (final a in s.chronicPostponed.take(3))
                  Text(tr('• ${a.title} (اتأجل ${arNum(a.postponeCount)} مرات)',
                      '• ${a.title} (postponed ${arNum(a.postponeCount)}×)'),
                      style: TextStyle(color: scheme.onTertiaryContainer)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _questionsStep(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _wentWell,
          maxLines: 2,
          decoration:
              InputDecoration(labelText: tr('إيه اللي مشي كويس الأسبوع ده؟',
                  'What went well this week?')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _blockedMe,
          maxLines: 2,
          decoration:
              InputDecoration(labelText: tr('إيه اللي عطّلك؟', 'What blocked you?')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nextFocus,
          maxLines: 2,
          decoration: InputDecoration(
              labelText: tr('أهم حاجة واحدة الأسبوع الجاي؟',
                  'One key thing for next week?')),
        ),
      ],
    );
  }

  Widget _planStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_overdue.isEmpty)
          Text(tr('مفيش مواعيد فاتت من غير ما تتعمل — ممتاز!',
              'No missed appointments — great!'))
        else ...[
          Text(tr('مواعيد فاتت — قرر فيها دلوقتي:',
              'Missed appointments — decide now:')),
          const SizedBox(height: 8),
          for (final a in _overdue)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                dense: true,
                title: Text(a.title),
                subtitle: Text(arShortDate(a.when)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _appts.setDone(a.id!, true);
                        if (mounted) await _load();
                      },
                      child: Text(tr('تمت', 'Done')),
                    ),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final tomorrow = DateTime(now.year, now.month,
                            now.day + 1, a.when.hour, a.when.minute);
                        await _appts.save(Appointment(
                          id: a.id,
                          title: a.title,
                          category: a.category,
                          when: tomorrow,
                          notes: a.notes,
                          remindBeforeMin: a.remindBeforeMin,
                        ));
                        if (mounted) await _load();
                      },
                      child: Text(tr('بكرة', 'Tomorrow')),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const AppointmentForm()));
            if (saved == true && mounted) await _load();
          },
          icon: const Icon(Icons.add),
          label: Text(tr('ضيف موعد للأسبوع الجاي', 'Add an appointment for next week')),
        ),
      ],
    );
  }
}
