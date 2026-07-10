import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/settings_repo.dart';
import '../../data/workout_repo.dart';

const List<String> kWeekdayNames = [
  'الإثنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الحد'
];

const List<String> _kWeekdayNamesEn = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
];

/// اسم اليوم (1=الإثنين .. 7=الأحد) باللغة الحالية.
String weekdayName(int weekday1to7) =>
    tr(kWeekdayNames[weekday1to7 - 1], _kWeekdayNamesEn[weekday1to7 - 1]);

/// خطة التمرين الأسبوعية: نص حر لكل يوم (فاضي = راحة) + وقت التذكير.
class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  final _repo = WorkoutRepo();
  final Map<int, TextEditingController> _controllers = {
    for (var d = 1; d <= 7; d++) d: TextEditingController(),
  };
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await _repo.plan();
    final time = await SettingsRepo().get('workout_time') ?? '18:00';
    final parts = time.split(':');
    if (!mounted) return;
    setState(() {
      for (final e in plan.entries) {
        _controllers[e.key]?.text = e.value;
      }
      _reminderTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 18,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      );
      _loading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    await SettingsRepo().set('workout_time',
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}');
    await _repo.savePlan({
      for (final e in _controllers.entries) e.key: e.value.text,
    });
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('خطة التمرين', 'Workout plan'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(tr('سيب اليوم فاضي لو راحة', 'Leave a day empty for rest'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: 8),
                for (var d = 1; d <= 7; d++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 72, child: Text(weekdayName(d))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controllers[d],
                            decoration: InputDecoration(
                                hintText: tr('مثلًا: صدر وتراي / جري / سكوات',
                                    'e.g. chest & tri / run / squats')),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration:
                        InputDecoration(labelText: tr('وقت التذكير', 'Reminder time')),
                    child: Text(arTime(DateTime(
                        2000, 1, 1, _reminderTime.hour, _reminderTime.minute))),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _save, child: Text(tr('حفظ', 'Save'))),
              ],
            ),
    );
  }
}
