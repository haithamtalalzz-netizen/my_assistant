import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../core/religion_data.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';
import 'adhkar_screen.dart';
import 'names_screen.dart';
import 'qibla_screen.dart';
import 'tasbih_screen.dart';

/// صفحة الصلاة والأذكار — مواعيد الصلاة + تتبّعها + بوصلة القبلة + أدوات دينية.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _repo = WorshipRepo();
  PrayerDay? _prayers;
  PrayerDay? _tomorrow;
  String _place = '';
  Set<int> _prayed = {};
  int _streak = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final gov = await resolvePlace(SettingsRepo());
    final now = DateTime.now();
    final prayed = await _repo.prayedToday();
    final streak = await _repo.fullDaysStreak();
    if (!mounted) return;
    setState(() {
      _place = gov.name;
      _prayers = prayerTimesFor(now, gov);
      _tomorrow = prayerTimesFor(now.add(const Duration(days: 1)), gov);
      _prayed = prayed;
      _streak = streak;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _togglePrayed(int i) async {
    final has = _prayed.contains(i);
    await _repo.togglePrayer(DateTime.now(), i, !has);
    final streak = await _repo.fullDaysStreak();
    if (!mounted) return;
    setState(() {
      has ? _prayed.remove(i) : _prayed.add(i);
      _streak = streak;
    });
  }

  String _hijri(DateTime now) {
    HijriCalendar.setLocal(AppState.isEnglish ? 'en' : 'ar');
    final h = HijriCalendar.fromDate(now);
    return tr('${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)}هـ',
        '${arNum(h.hDay)} ${h.longMonthName} ${arNum(h.hYear)} AH');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('الصلاة والأذكار', 'Prayer & Adhkar')),
        actions: [
          IconButton(
            tooltip: tr('اتجاه القبلة', 'Qibla'),
            icon: const Icon(Icons.explore),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
        ],
      ),
      body: _prayers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _timesCard(now),
                const SizedBox(height: 16),
                _duaCard(now),
                const SizedBox(height: 16),
                Text(tr('أدوات دينية', 'Islamic tools'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _toolsGrid(),
              ],
            ),
    );
  }

  Widget _timesCard(DateTime now) {
    final p = _prayers!;
    var idx = p.nextIndex(now);
    var target = idx == null ? _tomorrow!.times[0] : p.times[idx];
    final isTomorrow = idx == null;
    idx ??= 0;
    final remain = target.difference(now);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C4677), Color(0xFF1A2942), Color(0xFF0C1423)],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text(_place, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text(_hijri(now),
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isTomorrow
                  ? tr('صلاة ${prayerNameLabel(idx)} (بكرة)',
                      '${prayerNameLabel(idx)} (tomorrow)')
                  : tr('المتبقى على ${prayerNameLabel(idx)}',
                      'Time until ${prayerNameLabel(idx)}'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _fmtDur(remain),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            // الصلوات الخمس — كل واحدة معاها زر «صلّيت».
            for (var i = 0; i < kPrayerNames.length; i++) _prayerRow(i, idx),
            const SizedBox(height: 8),
            if (_streak > 0)
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    tr('${arNum(_streak)} يوم متتالى صلاة كاملة',
                        '${arNum(_streak)}-day full-prayer streak'),
                    style: const TextStyle(
                        color: Color(0xFFF3D06E), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _prayerRow(int i, int nextIdx) {
    final prayed = _prayed.contains(i);
    final isNext = i == nextIdx;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(prayerNameLabel(i),
                style: TextStyle(
                    color: isNext ? const Color(0xFF2FDE9B) : Colors.white,
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 15)),
          ),
          Text(arTime(_prayers!.times[i]),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w400)),
          const Spacer(),
          // زر «صلّيت».
          InkWell(
            onTap: () => _togglePrayed(i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: prayed
                    ? const Color(0xFF2FA36B)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(prayed ? Icons.check_circle : Icons.circle_outlined,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(prayed ? tr('صلّيت', 'Prayed') : tr('صلّيت؟', 'Pray?'),
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _duaCard(DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(tr('دعاء اليوم', "Today's du'a"),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(duaOfDay(now),
              style: const TextStyle(fontSize: 18, height: 1.9)),
        ],
      ),
    );
  }

  Widget _toolsGrid() {
    final tools = [
      _Tool(Icons.explore, tr('بوصلة القبلة', 'Qibla'), const Color(0xFF2E7D6B),
          () => const QiblaScreen()),
      _Tool(Icons.radio_button_checked, tr('المسبحة', 'Tasbih'),
          const Color(0xFF6A4C93), () => const TasbihScreen()),
      _Tool(Icons.wb_sunny, tr('أذكار الصباح', 'Morning adhkar'),
          const Color(0xFFCC8A2E), () => const AdhkarScreen(morning: true)),
      _Tool(Icons.nightlight_round, tr('أذكار المساء', 'Evening adhkar'),
          const Color(0xFF3C5A99), () => const AdhkarScreen(morning: false)),
      _Tool(Icons.star, tr('أسماء الله الحسنى', 'Names of Allah'),
          const Color(0xFF2FA36B), () => const NamesScreen()),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) {
        final t = tools[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => t.build())),
          child: Container(
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.icon, size: 38, color: t.color),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(t.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDur(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return arNum('${two(h)}:${two(m)}:${two(s)}');
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final Color color;
  final Widget Function() build;
  _Tool(this.icon, this.label, this.color, this.build);
}
