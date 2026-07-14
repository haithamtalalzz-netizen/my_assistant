import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/habits_repo.dart';
import '../../widgets/common.dart';

/// تحليلات العادات — أى عادة أقوى، أطول سلسلة، أكتر يوم بتلتزم فيه.
class HabitAnalyticsScreen extends StatefulWidget {
  const HabitAnalyticsScreen({super.key});

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

const _weekdayAr = {
  1: 'الإثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
  6: 'السبت',
  7: 'الأحد',
};
const _weekdayEn = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  final _repo = HabitsRepo();
  bool _loading = true;
  List<HabitStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repo.analytics();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('تحليلات العادات', 'Habit analytics'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? EmptyHint(
                  icon: Icons.insights_outlined,
                  text: tr('ضيف عادات وعلّمها كام يوم — وهوريك تحليلاتك',
                      'Add habits & check them off — analytics will show here'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    Text(tr('آخر ٣٠ يوم — مرتّبة بالأعلى التزامًا',
                        'Last 30 days — sorted by adherence'),
                        style: TextStyle(fontSize: 12, color: scheme.outline)),
                    const SizedBox(height: 6),
                    for (final s in _stats) _card(s, scheme),
                  ],
                ),
    );
  }

  Widget _card(HabitStat s, ColorScheme scheme) {
    final pct = (s.rate * 100).round();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.habit.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                if (s.streak > 0)
                  Text('🔥 ${arNum(s.streak)}',
                      style: TextStyle(
                          color: scheme.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: s.rate, minHeight: 7),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(tr('الالتزام: ٪${arNum(pct)}', 'Adherence: ${arNum(pct)}%'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                Text(
                    tr('اتعملت ${arNum(s.recentDone)} مرة',
                        '${arNum(s.recentDone)} times'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                if (s.bestWeekday != null)
                  Text(
                      tr('أكتر يوم: ${_weekdayAr[s.bestWeekday]}',
                          'Best day: ${_weekdayEn[s.bestWeekday]}'),
                      style: TextStyle(fontSize: 12, color: scheme.outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
