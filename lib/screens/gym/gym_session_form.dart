import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/gym_repo.dart';
import '../../data/workout_repo.dart';
import '../../models/models.dart';
import 'rest_timer.dart';

class _SetEntry {
  final exercise = TextEditingController();
  final reps = TextEditingController();
  final weight = TextEditingController();
}

class GymSessionForm extends StatefulWidget {
  /// اسم الوضع/اليوم المقترح (من الخطة).
  final String suggestedProgram;

  const GymSessionForm({super.key, this.suggestedProgram = ''});

  @override
  State<GymSessionForm> createState() => _GymSessionFormState();
}

class _GymSessionFormState extends State<GymSessionForm> {
  final _repo = GymRepo();
  final _program = TextEditingController();
  final _duration = TextEditingController();
  final List<_SetEntry> _sets = [];

  @override
  void initState() {
    super.initState();
    _program.text = widget.suggestedProgram;
    _addRow();
  }

  @override
  void dispose() {
    _program.dispose();
    _duration.dispose();
    for (final s in _sets) {
      s.exercise.dispose();
      s.reps.dispose();
      s.weight.dispose();
    }
    super.dispose();
  }

  void _addRow({String? exercise}) {
    final e = _SetEntry();
    if (exercise != null) e.exercise.text = exercise;
    // لو الصف الأخير عليه تمرين، نكمّل بنفس التمرين (set جديد).
    setState(() => _sets.add(e));
  }

  Future<void> _save() async {
    final day = dayKey(DateTime.now());
    final session = GymSession(
      day: day,
      program: _program.text.trim(),
      durationMin: (parseNumber(_duration.text) ?? 0).round(),
    );
    final sessionId = await _repo.addSession(session);
    // ترقيم الـ set لكل تمرين حسب ترتيب ظهوره.
    final counters = <String, int>{};
    for (final s in _sets) {
      final ex = s.exercise.text.trim();
      final reps = (parseNumber(s.reps.text) ?? 0).round();
      final weight = parseNumber(s.weight.text) ?? 0;
      if (ex.isEmpty || (reps == 0 && weight == 0)) continue;
      final idx = (counters[ex] ?? 0) + 1;
      counters[ex] = idx;
      await _repo.addSet(GymSet(
        sessionId: sessionId,
        exercise: ex,
        reps: reps,
        weight: weight,
        setIndex: idx,
      ));
    }
    // نعلّم تمرين النهارده «اتعمل».
    await WorkoutRepo()
        .setDone(day, true, title: _program.text.trim());
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('تسجيل تمرين', 'Log workout')),
        actions: [
          IconButton(
            tooltip: tr('مؤقّت الراحة', 'Rest timer'),
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => showRestTimer(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _program,
                  decoration: InputDecoration(
                      labelText: tr('الوضع/اليوم (مثلًا: دفع)',
                          'Program/day (e.g. Push)')),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: tr('دقايق', 'Minutes')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tr('اختيار سريع لتمرين', 'Quick-pick an exercise'),
              style: TextStyle(color: scheme.outline, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final entry in kGymExercises.entries)
                for (final ex in entry.value)
                  ActionChip(
                    label: Text(ex),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _addRow(exercise: ex),
                  ),
            ],
          ),
          const Divider(height: 24),
          Text(tr('المجموعات (تمرين • تكرارات • وزن)',
              'Sets (exercise • reps • weight)'),
              style: TextStyle(color: scheme.outline, fontSize: 13)),
          const SizedBox(height: 8),
          for (var i = 0; i < _sets.length; i++) _setRow(context, i),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addRow(),
            icon: const Icon(Icons.add),
            label: Text(tr('ضيف مجموعة', 'Add set')),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(tr('حفظ التمرين', 'Save workout'))),
        ],
      ),
    );
  }

  Widget _setRow(BuildContext context, int i) {
    final s = _sets[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: s.exercise,
              decoration: InputDecoration(
                  isDense: true, hintText: tr('التمرين', 'Exercise')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: s.reps,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  isDense: true, hintText: tr('تكرار', 'Reps')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: s.weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  isDense: true, hintText: tr('كجم', 'kg')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _sets.length == 1
                ? null
                : () => setState(() => _sets.removeAt(i)),
          ),
        ],
      ),
    );
  }
}
