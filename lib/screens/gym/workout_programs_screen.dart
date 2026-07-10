import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../core/workout_programs.dart';
import '../../data/workout_repo.dart';

/// مكتبة برامج التمارين الجاهزة — بيت/جيم، بأجهزة أو من غير.
class WorkoutProgramsScreen extends StatefulWidget {
  const WorkoutProgramsScreen({super.key});

  @override
  State<WorkoutProgramsScreen> createState() =>
      _WorkoutProgramsScreenState();
}

class _WorkoutProgramsScreenState extends State<WorkoutProgramsScreen> {
  String _place = 'all'; // all/home/gym
  String _equip = 'all'; // all/yes/no

  List<WorkoutProgram> get _filtered => kWorkoutPrograms.where((p) {
        if (_place != 'all' && p.place != _place) return false;
        if (_equip == 'yes' && !p.needsEquipment) return false;
        if (_equip == 'no' && p.needsEquipment) return false;
        return true;
      }).toList();

  Future<void> _openProgram(WorkoutProgram p) async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(p.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                '${placeLabel(p.place)} • ${p.needsEquipment ? tr('بأجهزة', 'With equipment') : tr('بدون أجهزة', 'No equipment')} • ${levelLabel(p.level)} • ${p.days.length} ${tr('أيام', 'days')}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 12),
            for (final d in p.days)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_weekdayName(d.weekday)} — ${d.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      for (final ex in d.exercises)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(ex)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check),
              label: Text(tr('طبّق البرنامج على جدولي', 'Apply to my plan')),
            ),
          ],
        ),
      ),
    );
    if (applied == true) {
      await WorkoutRepo().savePlan(p.weeklyPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('اتطبّق «${p.name}» على جدول التمرين',
                'Applied "${p.name}" to your plan'))));
        Navigator.pop(context, true);
      }
    }
  }

  String _weekdayName(int w) => switch (w) {
        6 => tr('السبت', 'Sat'),
        7 => tr('الأحد', 'Sun'),
        1 => tr('الاثنين', 'Mon'),
        2 => tr('الثلاثاء', 'Tue'),
        3 => tr('الأربعاء', 'Wed'),
        4 => tr('الخميس', 'Thu'),
        5 => tr('الجمعة', 'Fri'),
        _ => '$w',
      };

  @override
  Widget build(BuildContext context) {
    final progs = _filtered;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('برامج التمارين', 'Workout programs')),
          actions: [searchAction(context)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(tr('الكل', 'All'), _place == 'all',
                    () => setState(() => _place = 'all')),
                _chip(tr('🏠 البيت', '🏠 Home'), _place == 'home',
                    () => setState(() => _place = 'home')),
                _chip(tr('🏋️ الجيم', '🏋️ Gym'), _place == 'gym',
                    () => setState(() => _place = 'gym')),
                const SizedBox(width: 8),
                _chip(tr('بأجهزة', 'Equipment'), _equip == 'yes',
                    () => setState(() => _equip = _equip == 'yes' ? 'all' : 'yes')),
                _chip(tr('بدون أجهزة', 'No equipment'), _equip == 'no',
                    () => setState(() => _equip = _equip == 'no' ? 'all' : 'no')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              children: [
                for (final p in progs)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (p.place == 'home'
                                ? Colors.teal
                                : Colors.deepPurple)
                            .withValues(alpha: 0.15),
                        child: Icon(
                            p.place == 'home'
                                ? Icons.home_outlined
                                : Icons.fitness_center,
                            color: p.place == 'home'
                                ? Colors.teal
                                : Colors.deepPurple),
                      ),
                      title: Text(p.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${p.needsEquipment ? tr('بأجهزة', 'Equipment') : tr('بدون أجهزة', 'No equipment')} • ${levelLabel(p.level)} • ${p.days.length} ${tr('أيام', 'days')}'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _openProgram(p),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}
