import 'dart:math';

import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/day_log_repo.dart';
import '../widgets/common.dart';

/// «آلة الزمن» — افتح أى يوم من حياتك وشوف كل اللى اتسجّل فيه (من كل الأقسام)
/// عبر `DayLogRepo.forDay`. تنقّل بين الأيام أو اقفز لتاريخ أو ليوم عشوائى.
class TimeMachineScreen extends StatefulWidget {
  const TimeMachineScreen({super.key});

  @override
  State<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends State<TimeMachineScreen> {
  final _repo = DayLogRepo();
  DateTime _day = DateTime.now();
  List<DayEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ev = await _repo.forDay(dayKey(_day));
    if (!mounted) return;
    setState(() {
      _events = ev;
      _loading = false;
    });
  }

  bool get _isToday => dayKey(_day) == dayKey(DateTime.now());

  void _go(int deltaDays) {
    final next = _day.add(Duration(days: deltaDays));
    if (next.isAfter(DateTime.now())) return; // مفيش مستقبل
    _day = DateTime(next.year, next.month, next.day);
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (d != null) {
      _day = DateTime(d.year, d.month, d.day);
      _load();
    }
  }

  void _randomDay() {
    final now = DateTime.now();
    final back = Random().nextInt(365) + 1; // يوم عشوائى خلال آخر سنة
    _day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: back));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('آلة الزمن', 'Time machine')),
        actions: [
          IconButton(
            tooltip: tr('يوم عشوائى', 'Random day'),
            icon: const Icon(Icons.casino_outlined),
            onPressed: _randomDay,
          ),
          IconButton(
            tooltip: tr('اختر تاريخ', 'Pick a date'),
            icon: const Icon(Icons.event),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            // اليوم اللى قبله (RTL: السهم لليمين = رجوع للأقدم)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _go(-1),
              tooltip: tr('اليوم السابق', 'Previous day'),
            ),
            Expanded(
              child: Text(arFullDate(_day),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: scheme.primary)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _isToday ? null : () => _go(1),
              tooltip: tr('اليوم التالى', 'Next day'),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_events.isEmpty
                  ? EmptyHint(
                      icon: Icons.history_toggle_off,
                      text: tr('مفيش نشاط مسجّل فى اليوم ده.',
                          'No activity logged on this day.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: _events.length,
                      itemBuilder: (_, i) => _eventTile(scheme, _events[i]),
                    )),
        ),
      ]),
    );
  }

  Widget _eventTile(ColorScheme scheme, DayEvent e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(_iconFor(e.kind), color: scheme.primary),
        title: Text(e.text),
        trailing: (e.time != null && e.time!.isNotEmpty)
            ? Text(e.time!, style: TextStyle(color: scheme.onSurfaceVariant))
            : null,
      ),
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'appointment':
        return Icons.event_available_outlined;
      case 'expense':
        return Icons.shopping_bag_outlined;
      case 'income':
        return Icons.savings_outlined;
      case 'meal':
        return Icons.restaurant_outlined;
      case 'med':
        return Icons.medication_outlined;
      case 'habit':
        return Icons.check_circle_outline;
      case 'workout':
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'measurement':
        return Icons.monitor_heart_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'health':
        return Icons.favorite_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}
