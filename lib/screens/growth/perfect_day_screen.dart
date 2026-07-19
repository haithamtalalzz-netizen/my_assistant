import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/perfect_day.dart';

/// «اليوم المثالي» — الصلاة + العادات + المياه كلهم خُضر = يوم مثالي، مع عدّاد شهري.
class PerfectDayScreen extends StatefulWidget {
  const PerfectDayScreen({super.key});

  @override
  State<PerfectDayScreen> createState() => _PerfectDayScreenState();
}

class _PerfectDayScreenState extends State<PerfectDayScreen> {
  DaySystems? _today;
  int _month = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await systemsForDay(DateTime.now());
    final month = await perfectDaysThisMonth();
    final streak = await perfectStreak();
    if (!mounted) return;
    setState(() {
      _today = today;
      _month = month;
      _streak = streak;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('اليوم المثالي', 'Perfect day'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _banner(scheme),
                const SizedBox(height: 16),
                Text(tr('أنظمة النهاردة', "Today's systems"),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
                const SizedBox(height: 8),
                _systemTile('🕌', tr('الصلاة', 'Prayers'),
                    '${arNum(_today!.prayers)}/5', _today!.prayersOk),
                if (_today!.habitsTotal > 0)
                  _systemTile(
                      '🔥',
                      tr('العادات', 'Habits'),
                      '${arNum(_today!.habitsDone)}/${arNum(_today!.habitsTotal)}',
                      _today!.habitsOk),
                _systemTile(
                    '💧',
                    tr('المياه', 'Water'),
                    '${arNum(_today!.waterMl)}/${arNum(_today!.waterGoalMl)} ${tr('مل', 'ml')}',
                    _today!.waterOk),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                      child: _statCard(
                          scheme,
                          '📅',
                          tr('أيام مثالية الشهر ده', 'Perfect days this month'),
                          arNum(_month))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _statCard(scheme, '🔥',
                          tr('سلسلة متتالية', 'Current streak'),
                          '${arNum(_streak)} ${tr('يوم', 'd')}')),
                ]),
              ],
            ),
    );
  }

  Widget _banner(ColorScheme scheme) {
    final perfect = _today!.isPerfect;
    final green = const Color(0xFF16A34A);
    final bg = perfect ? green.withValues(alpha: .14) : scheme.surfaceContainerHighest;
    final greens =
        [_today!.prayersOk, _today!.habitsOk, _today!.waterOk].where((x) => x).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: perfect ? green : scheme.outlineVariant, width: 1.4),
      ),
      child: Column(children: [
        Text(perfect ? '✨' : '🎯', style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          perfect
              ? tr('النهاردة يوم مثالي!', 'Today is a perfect day!')
              : tr('خلّي نهاردك مثالي', 'Make today perfect'),
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: perfect ? green : scheme.onSurface),
          textAlign: TextAlign.center,
        ),
        if (!perfect) ...[
          const SizedBox(height: 4),
          Text(
            tr('$greens من ٣ أنظمة خضرا — كمّل الباقي',
                '$greens of 3 systems green — finish the rest'),
            style: TextStyle(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ]),
    );
  }

  Widget _systemTile(String emoji, String label, String value, bool ok) {
    final green = const Color(0xFF16A34A);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
        title: Text(label),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ok ? green : null)),
          const SizedBox(width: 8),
          Icon(ok ? Icons.check_circle : Icons.circle_outlined,
              color: ok ? green : Theme.of(context).colorScheme.outline),
        ]),
      ),
    );
  }

  Widget _statCard(ColorScheme scheme, String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
