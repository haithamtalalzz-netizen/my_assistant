import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';

/// تتبّع الصيام — صيام اليوم + الأيام المستحبّة (اثنين/خميس/الأيام البيض)
/// + تذكير السحور والإفطار.
class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  final _repo = WorshipRepo();
  final _settings = SettingsRepo();
  bool _todayFasted = false;
  int _monthCount = 0;
  bool _reminders = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fasted = await _repo.fastedOn(DateTime.now());
    final count = await _repo.fastCountLast(30);
    final rem = await _settings.fastingRemindersEnabled();
    if (!mounted) return;
    setState(() {
      _todayFasted = fasted;
      _monthCount = count;
      _reminders = rem;
      _loading = false;
    });
  }

  Future<void> _toggleToday(bool v) async {
    await _repo.setFasted(DateTime.now(), v);
    await _load();
  }

  /// الأيام المستحبّة القادمة (خلال ~6 أسابيع): اثنين/خميس + البيض 13-15.
  List<({DateTime date, String label})> _recommended() {
    final out = <({DateTime date, String label})>[];
    final today = dateOnly(DateTime.now());
    // اثنين وخميس خلال أسبوعين.
    for (var i = 0; i <= 14; i++) {
      final d = today.add(Duration(days: i));
      if (d.weekday == DateTime.monday) {
        out.add((date: d, label: tr('الاثنين', 'Monday')));
      } else if (d.weekday == DateTime.thursday) {
        out.add((date: d, label: tr('الخميس', 'Thursday')));
      }
    }
    // الأيام البيض (13/14/15) للشهر الهجرى الحالى والجاى.
    final hc = HijriCalendar.now();
    for (final off in [0, 1]) {
      var y = hc.hYear;
      var m = hc.hMonth + off;
      if (m > 12) {
        m -= 12;
        y += 1;
      }
      for (final day in [13, 14, 15]) {
        try {
          final g = dateOnly(HijriCalendar().hijriToGregorian(y, m, day));
          if (!g.isBefore(today) && g.difference(today).inDays <= 42) {
            out.add((date: g, label: tr('الأيام البيض', 'White days')));
          }
        } catch (_) {}
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الصيام', 'Fasting'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.6)
                    ]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('صيامك آخر 30 يوم', 'Fasting — last 30 days'),
                                style: TextStyle(
                                    color: scheme.onPrimary
                                        .withValues(alpha: 0.9))),
                            Text('${arNum(_monthCount)} ${tr('يوم', 'days')}',
                                style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const Text('🌙', style: TextStyle(fontSize: 40)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.wb_twilight),
                    title: Text(tr('صمت اليوم', 'I fasted today')),
                    value: _todayFasted,
                    onChanged: _toggleToday,
                  ),
                ),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: Text(tr('تذكير السحور والإفطار',
                        'Suhoor & iftar reminders')),
                    subtitle: Text(
                        tr('السحور قبل الفجر بـ40 دقيقة، والإفطار عند المغرب',
                            'Suhoor 40 min before Fajr, iftar at Maghrib'),
                        style: const TextStyle(fontSize: 12)),
                    value: _reminders,
                    onChanged: (v) async {
                      setState(() => _reminders = v);
                      await _settings.setFastingReminders(v);
                      await PrayerScheduler.ensureScheduled();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr('أيام مستحبّة قادمة', 'Recommended upcoming days'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final r in _recommended())
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.event_available),
                    title: Text(r.label),
                    trailing: Text(arShortDate(r.date),
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
              ],
            ),
    );
  }
}
