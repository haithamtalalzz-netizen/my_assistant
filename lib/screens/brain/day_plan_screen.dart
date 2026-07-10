import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/day_planner.dart';
import '../../core/l10n.dart';
import '../../core/notifications.dart';
import '../../core/prayers.dart';
import '../../data/appointments_repo.dart';
import '../../data/habits_repo.dart';
import '../../data/settings_repo.dart';
import '../../data/workout_repo.dart';
import '../../widgets/common.dart';

class DayPlanScreen extends StatefulWidget {
  const DayPlanScreen({super.key});

  @override
  State<DayPlanScreen> createState() => _DayPlanScreenState();
}

class _DayPlanScreenState extends State<DayPlanScreen> {
  bool _loading = true;
  List<PlanItem> _plan = [];
  bool _remindersSet = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final now = DateTime.now();
    final apptsRepo = AppointmentsRepo();
    final todayAppts = await apptsRepo.forDay(now);
    final all = await apptsRepo.all();
    final startOfToday = dateOnly(now);
    final overdue = all
        .where((a) => !a.done && a.when.isBefore(startOfToday))
        .map((a) => a.title)
        .toList();

    final settings = SettingsRepo();
    final gov = governorateByName(await settings.governorateName());
    final prayerDay = prayerTimesFor(now, gov);
    final prayers = <(DateTime, String)>[
      for (var i = 0; i < kPrayerNames.length; i++)
        (prayerDay.times[i], kPrayerNames[i]),
    ];

    final workoutRepo = WorkoutRepo();
    final plan = await workoutRepo.plan();
    final workoutTitle = plan[now.weekday];
    (DateTime, String)? workout;
    if (workoutTitle != null && !await workoutRepo.doneOn(dayKey(now))) {
      final time = await settings.get('workout_time') ?? '18:00';
      final parts = time.split(':');
      workout = (
        DateTime(now.year, now.month, now.day,
            int.tryParse(parts[0]) ?? 18, int.tryParse(parts[1]) ?? 0),
        workoutTitle,
      );
    }

    final habitsRepo = HabitsRepo();
    final habits = await habitsRepo.active();
    final doneToday = await habitsRepo.doneOn(dayKey(now));
    final pending = [
      for (final h in habits)
        if (!doneToday.contains(h.id)) h.name
    ];

    final result = buildDayPlan(PlanInput(
      now: now,
      dayEnd: DateTime(now.year, now.month, now.day, 22, 30),
      appointments: [for (final a in todayAppts) (a.when, a.title)],
      prayers: prayers,
      workout: workout,
      overdue: overdue,
      pendingHabits: pending,
    ));
    if (!mounted) return;
    setState(() {
      _plan = result;
      _loading = false;
    });
  }

  /// إشعار عند بداية كل بند مقترح (مش الثوابت) — بتتلغي وتتعمل من جديد
  /// مع كل توليد خطة.
  Future<void> _setReminders() async {
    for (var i = 0; i < 30; i++) {
      await Notifications.cancel(Notifications.planNotifId(i));
    }
    var idx = 0;
    for (final item in _plan) {
      if (item.kind == PlanKind.overdue || item.kind == PlanKind.habit) {
        await Notifications.scheduleOnce(
          id: Notifications.planNotifId(idx++),
          title: tr('حسب خطة يومك', 'From your day plan'),
          body: tr('${item.title} — دلوقتي', '${item.title} — now'),
          when: item.start,
        );
      }
    }
    if (!mounted) return;
    setState(() => _remindersSet = true);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('تمام — هفكرك ببنود الخطة في مواعيدها',
            "Done — I'll remind you of plan items on time"))));
  }

  (IconData, Color) _style(BuildContext context, PlanKind kind) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      PlanKind.appointment => (Icons.event, scheme.primary),
      PlanKind.prayer => (Icons.mosque_outlined, scheme.tertiary),
      PlanKind.workout => (Icons.fitness_center, scheme.secondary),
      PlanKind.overdue => (Icons.assignment_late_outlined, scheme.error),
      PlanKind.habit => (Icons.task_alt, scheme.secondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('خطة باقي اليوم', 'Rest of day plan'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan.isEmpty
              ? Center(
                  child: EmptyHint(
                      icon: Icons.beach_access_outlined,
                      text: tr('مفيش حاجة متبقية النهارده — استمتع بوقتك!',
                          'Nothing left today — enjoy your time!')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(
                      tr('اقتراح لترتيب باقي يومك حوالين ثوابتك — مش إلزام.',
                          'A suggested order for the rest of your day — not binding.'),
                      style:
                          TextStyle(color: scheme.outline, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    for (final item in _plan)
                      Builder(builder: (context) {
                        final (icon, color) = _style(context, item.kind);
                        final suggested = item.kind == PlanKind.overdue ||
                            item.kind == PlanKind.habit;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            dense: true,
                            leading: SizedBox(
                              width: 64,
                              child: Text(arTime(item.start),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ),
                            title: Text(item.title),
                            subtitle: suggested
                                ? Text(tr('مقترح — ينفع يتحرك', 'Suggested — movable'))
                                : null,
                            trailing: Icon(icon, color: color, size: 20),
                          ),
                        );
                      }),
                  ],
                ),
      floatingActionButton: _plan.any((i) =>
              i.kind == PlanKind.overdue || i.kind == PlanKind.habit)
          ? FloatingActionButton.extended(
              heroTag: 'plan_fab',
              onPressed: _remindersSet ? null : _setReminders,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(_remindersSet
                  ? tr('اتفعلت ✓', 'Set ✓')
                  : tr('فكرني بالبنود', 'Remind me of items')),
            )
          : null,
    );
  }
}
