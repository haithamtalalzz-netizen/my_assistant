import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/habits_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class HabitsScreen extends StatefulWidget {
  final Widget? drawer;

  const HabitsScreen({super.key, this.drawer});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = HabitsRepo();
  bool _loading = true;
  List<Habit> _habits = [];
  Map<int, Set<String>> _days = {};
  Map<int, int> _streaks = {};

  String get _today => dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await _repo.active();
    final days = <int, Set<String>>{};
    final streaks = <int, int>{};
    final now = DateTime.now();
    for (final h in habits) {
      final d = await _repo.daysFor(h.id!);
      days[h.id!] = d;
      streaks[h.id!] = computeStreak(d, now);
    }
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _days = days;
      _streaks = streaks;
      _loading = false;
    });
  }

  Future<void> _toggleDay(Habit h, String day) async {
    await _repo.toggle(h.id!, day);
    final d = await _repo.daysFor(h.id!);
    if (!mounted) return;
    setState(() {
      _days[h.id!] = d;
      _streaks[h.id!] = computeStreak(d, DateTime.now());
    });
  }

  List<String> get _suggestions => [
        tr('أذكار الصباح', 'Morning adhkar'),
        tr('أذكار المساء', 'Evening adhkar'),
        tr('ورد قرآن', 'Quran portion'),
        tr('قراءة ١٠ صفحات', 'Read 10 pages'),
        tr('مشي نص ساعة', 'Walk 30 minutes'),
      ];

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          scrollable: true,
        title: Text(tr('عادة جديدة', 'New habit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: tr('اسم العادة (مثلًا: قراءة ١٠ صفحات)',
                      'Habit name (e.g. read 10 pages)')),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in _suggestions)
                  if (!_habits.any((h) => h.name == s))
                    ActionChip(
                      label: Text(s),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        controller.text = s;
                        Navigator.pop(ctx, true);
                      },
                    ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('إضافة', 'Add'))),
        ],
      ),
    );
    final name = controller.text.trim();
    if (saved == true && name.isNotEmpty) {
      await _repo.add(name);
      if (mounted) await _load();
    }
    controller.dispose();
  }

  Future<void> _archive(Habit h) async {
    await _repo.archive(h.id!);
    if (mounted) await _load();
  }

  Future<void> _delete(Habit h) async {
    if (!await confirmDelete(
        context, tr('العادة "${h.name}" وكل سجلها', 'habit "${h.name}" and its log'))) {
      return;
    }
    await _repo.delete(h.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(title: Text(tr('العادات', 'Habits'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _habits.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.task_alt,
                          text:
                              tr('لسه مفيش عادات — ابدأ بعادة واحدة بسيطة\nالسلسلة فيها يوم رحمة كل أسبوع، فمتقلقش من يوم فايت',
                                  'No habits yet — start with one simple habit\nEach week has a mercy day, so one miss is fine')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        for (final h in _habits) _habitCard(context, h),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: _addHabit,
        tooltip: tr('عادة جديدة', 'New habit'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _habitCard(BuildContext context, Habit h) {
    final streak = _streaks[h.id] ?? 0;
    final doneToday = (_days[h.id] ?? const {}).contains(_today);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(h.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.local_fire_department,
                    size: 20,
                    color: streak > 0
                        ? Colors.deepOrange
                        : Theme.of(context).colorScheme.outline),
                const SizedBox(width: 2),
                Text(arNum(streak),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'archive':
                        await _archive(h);
                      case 'delete':
                        await _delete(h);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'archive', child: Text(tr('أرشفة', 'Archive'))),
                    PopupMenuItem(
                        value: 'delete', child: Text(tr('حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _weekStrip(context, h)),
                FilledButton.tonal(
                  onPressed: () => _toggleDay(h, _today),
                  child: Text(doneToday
                      ? tr('اتعملت ✓', 'Done ✓')
                      : tr('تم النهارده؟', 'Done today?')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// آخر ٧ أيام — النهارده في الآخر (أقصى الشمال في RTL).
  Widget _weekStrip(BuildContext context, Habit h) {
    final scheme = Theme.of(context).colorScheme;
    final days = _days[h.id] ?? const <String>{};
    final today = dateOnly(DateTime.now());
    return Row(
      children: [
        for (var i = 6; i >= 0; i--)
          Builder(builder: (context) {
            final d = today.subtract(Duration(days: i));
            final done = days.contains(dayKey(d));
            final isToday = i == 0;
            return Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? scheme.primary : scheme.surfaceContainerHighest,
                border: isToday
                    ? Border.all(color: scheme.primary, width: 2)
                    : null,
              ),
              child: Text(
                arNum(d.day),
                style: TextStyle(
                  fontSize: 11,
                  color: done ? scheme.onPrimary : scheme.outline,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          }),
      ],
    );
  }
}
