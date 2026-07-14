import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/appointments_repo.dart';
import '../../widgets/month_year_wheel.dart';
import 'appointment_form.dart';

/// عرض شهرى للمواعيد — نقاط على الأيام اللى فيها مواعيد، والضغط على يوم يوري
/// مواعيده ويسمح بالإضافة. بيتنقّل للأمام والخلف (مش زى تقاويم السجل).
class AppointmentsCalendarScreen extends StatefulWidget {
  const AppointmentsCalendarScreen({super.key});

  @override
  State<AppointmentsCalendarScreen> createState() =>
      _AppointmentsCalendarScreenState();
}

class _AppointmentsCalendarScreenState
    extends State<AppointmentsCalendarScreen> {
  final _repo = AppointmentsRepo();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _active = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final all = await _repo.all();
    final prefix =
        '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';
    final days = <String>{};
    for (final a in all) {
      final k = _key(a.when);
      if (k.startsWith(prefix)) days.add(k);
    }
    if (mounted) setState(() => _active = days);
  }

  void _shift(int d) {
    setState(() => _month = DateTime(_month.year, _month.month + d));
    _load();
  }

  Future<void> _pickMonthYear() async {
    final picked = await showMonthYearWheel(context,
        initial: _month, maxMonth: DateTime(DateTime.now().year + 5, 12));
    if (picked == null || !mounted) return;
    setState(() => _month = DateTime(picked.year, picked.month));
    _load();
  }

  Future<void> _openDay(DateTime day) async {
    final appts = await _repo.forDay(day);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(arFullDate(day),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (appts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(tr('مفيش مواعيد فى اليوم ده',
                      'No appointments on this day')),
                )
              else
                for (final a in appts)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        a.done ? Icons.check_circle : Icons.event,
                        color: a.done
                            ? Colors.green
                            : Theme.of(ctx).colorScheme.primary),
                    title: Text(a.title,
                        style: TextStyle(
                            decoration:
                                a.done ? TextDecoration.lineThrough : null)),
                    subtitle: Text(arTime(a.when)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AppointmentForm(appointment: a)));
                      await _load();
                    },
                  ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(tr('ضيف موعد', 'Add appointment')),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AppointmentForm()));
                    await _load();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = AppState.isEnglish ? 'en' : 'ar';
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = (first.weekday - 6 + 7) % 7; // السبت أول العمود
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(tr('تقويم المواعيد', 'Appointments calendar'))),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: InkWell(
                  onTap: _pickMonthYear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('MMMM y', locale).format(_month),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down,
                            color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: [
              for (final d in const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 0.9),
              itemCount: lead + daysInMonth,
              itemBuilder: (_, i) {
                if (i < lead) return const SizedBox.shrink();
                final dayNum = i - lead + 1;
                final date = DateTime(_month.year, _month.month, dayNum);
                final active = _active.contains(_key(date));
                final isToday = _key(date) == _key(today);
                return InkWell(
                  onTap: () => _openDay(date),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: active
                          ? scheme.primary.withValues(alpha: 0.20)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(arNum(dayNum),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: scheme.primary, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AppointmentForm()));
          await _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
