import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/gym_repo.dart';
import '../../data/workout_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';
import 'exercise_library_screen.dart';
import 'rest_timer.dart';
import 'gym_session_form.dart';
import 'progress_screen.dart';
import 'walk_tracker_screen.dart';
import 'workout_programs_screen.dart';

class GymScreen extends StatefulWidget {
  final Widget? drawer;

  const GymScreen({super.key, this.drawer});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  final _repo = GymRepo();
  bool _loading = true;
  String _program = '';
  Map<int, String> _plan = {};
  List<GymSession> _sessions = [];
  Map<int, int> _setCounts = {};
  List<({String exercise, double weight, int reps})> _prs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final program = await _repo.currentProgram();
    final plan = await WorkoutRepo().plan();
    final sessions = await _repo.recentSessions();
    final setCounts = <int, int>{};
    for (final s in sessions) {
      setCounts[s.id!] = (await _repo.setsFor(s.id!)).length;
    }
    final prs = await _repo.personalRecords();
    if (!mounted) return;
    setState(() {
      _program = program;
      _plan = plan;
      _sessions = sessions;
      _setCounts = setCounts;
      _prs = prs;
      _loading = false;
    });
  }

  Future<void> _logWorkout() async {
    final todayFocus = _plan[DateTime.now().weekday] ?? '';
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => GymSessionForm(suggestedProgram: todayFocus)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _pickProgram() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('اختار وضع التمرين', 'Choose a training split'),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            for (final key in kGymPrograms.keys)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(gymProgramLabel(key)),
                subtitle: Text(_daysSummary(key)),
                onTap: () => Navigator.pop(ctx, key),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await _repo.setProgram(chosen);
      if (mounted) await _load();
    }
  }

  String _daysSummary(String key) {
    final preset = kGymPrograms[key]!;
    final count = preset.length;
    return tr('${arNum(count)} أيام في الأسبوع', '${arNum(count)} days/week');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('الجيم', 'Gym')),
        actions: [
          IconButton(
            tooltip: tr('مؤقّت الراحة', 'Rest timer'),
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => showRestTimer(context),
          ),
          IconButton(
            tooltip: tr('تتبّع المشي/الجري', 'Walk / run tracker'),
            icon: const Icon(Icons.directions_run),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalkTrackerScreen())),
          ),
          IconButton(
            tooltip: tr('مكتبة التمارين', 'Exercise library'),
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
          ),
          IconButton(
            tooltip: tr('برامج جاهزة', 'Workout programs'),
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WorkoutProgramsScreen()));
              if (mounted) await _load();
            },
          ),
          IconButton(
            tooltip: tr('التقدّم والمقاسات', 'Progress & measurements'),
            icon: const Icon(Icons.straighten),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProgressScreen())),
          ),
          searchAction(context),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  _programCard(context),
                  if (_prs.isNotEmpty) ...[
                    SectionHeader(tr('أرقامك القياسية (PR)', 'Personal records')),
                    _prCard(context),
                  ],
                  SectionHeader(tr('آخر التمارين', 'Recent workouts')),
                  if (_sessions.isEmpty)
                    EmptyHint(
                        icon: Icons.fitness_center,
                        text: tr('سجّل أول تمرين — تمارينك وأوزانك هتتحفظ وتتابع تقدّمك',
                            'Log your first workout — your exercises & weights are saved to track progress'))
                  else
                    ..._sessions.map((s) => _sessionTile(context, s)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'gym_fab',
        onPressed: _logWorkout,
        icon: const Icon(Icons.add),
        label: Text(tr('سجّل تمرين', 'Log workout')),
      ),
    );
  }

  Widget _programCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final todayFocus = _plan[DateTime.now().weekday];
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      _program.isEmpty
                          ? tr('مفيش وضع مختار', 'No split selected')
                          : gymProgramLabel(_program),
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                TextButton(
                    onPressed: _pickProgram,
                    child: Text(tr('غيّر', 'Change'))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                todayFocus == null
                    ? tr('النهارده راحة', 'Rest day today')
                    : tr('النهارده: $todayFocus', 'Today: $todayFocus'),
                style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(_weekStatsText(),
                style: TextStyle(
                    color: scheme.onPrimaryContainer, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  /// «N تمارين الأسبوع • آخر تمرين من X يوم» — من آخر الجلسات.
  String _weekStatsText() {
    final now = DateTime.now();
    var week = 0;
    int? sinceLast;
    for (final s in _sessions) {
      final d = DateTime.tryParse(s.day);
      if (d == null) continue;
      final diff = now.difference(d).inDays;
      if (diff < 7) week++;
      sinceLast = sinceLast == null ? diff : (diff < sinceLast ? diff : sinceLast);
    }
    final last = sinceLast == null
        ? tr('لسه مفيش تمارين', 'no workouts yet')
        : sinceLast == 0
            ? tr('آخر تمرين: النهارده', 'last: today')
            : tr('آخر تمرين من ${arNum(sinceLast)} يوم',
                'last: ${arNum(sinceLast)}d ago');
    return tr('${arNum(week)} تمارين الأسبوع • $last',
        '${arNum(week)} workouts this week • $last');
  }

  Widget _prCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final pr in _prs.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pr.exercise)),
                    Text(
                        tr('${arNum(pr.weight % 1 == 0 ? pr.weight.toInt() : pr.weight)} كجم × ${arNum(pr.reps)}',
                            '${arNum(pr.weight % 1 == 0 ? pr.weight.toInt() : pr.weight)} kg × ${arNum(pr.reps)}'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sessionTile(BuildContext context, GymSession s) {
    final count = _setCounts[s.id!] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(s.program.isEmpty ? tr('تمرين', 'Workout') : s.program),
        subtitle: Text([
          arShortDate(DateTime.parse(s.day)),
          tr('${arNum(count)} مجموعة', '${arNum(count)} sets'),
          if (s.durationMin > 0)
            tr('${arNum(s.durationMin)} دقيقة', '${arNum(s.durationMin)} min'),
        ].join(' • ')),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: tr('حذف', 'Delete'),
          onPressed: () async {
            if (!await confirmDelete(
                context, tr('التمرين ده', 'this workout'))) {
              return;
            }
            await _repo.deleteSession(s.id!);
            if (mounted) await _load();
          },
        ),
        onTap: () => _showSessionDetail(s),
      ),
    );
  }

  Future<void> _showSessionDetail(GymSession s) async {
    final sets = await _repo.setsFor(s.id!);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${s.program.isEmpty ? tr('تمرين', 'Workout') : s.program} — ${arShortDate(DateTime.parse(s.day))}',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (sets.isEmpty)
                Text(tr('مفيش مجموعات متسجلة', 'No sets logged'))
              else
                for (final st in sets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                        '${st.exercise}: ${arNum(st.reps)} × ${arNum(st.weight % 1 == 0 ? st.weight.toInt() : st.weight)} '
                        '${tr('كجم', 'kg')}'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
