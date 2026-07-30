import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';
import '../../core/worship_program.dart';
import '../../data/memorization_repo.dart';
import '../../data/worship_extras_repo.dart';
import '../../data/worship_repo.dart';
import 'adhkar_screen.dart';
import 'khatma_screen.dart';
import 'memorization_screen.dart';
import 'prayer_screen.dart';
import 'sadaqah_screen.dart';

/// «برنامجى الدينى» — خطة اليوم الموجّهة: بتجمع الصلوات والأذكار وورد القرآن
/// والسنن والحفظ والقيام والصدقة فى مسار واحد بنسبة إنجاز وسلسلة ومستوى.
class WorshipProgramScreen extends StatefulWidget {
  const WorshipProgramScreen({super.key});

  @override
  State<WorshipProgramScreen> createState() => _WorshipProgramScreenState();
}

class _WorshipProgramScreenState extends State<WorshipProgramScreen> {
  final _repo = WorshipRepo();
  final _extras = WorshipExtrasRepo();
  ProgramDay? _day;
  int _streak = 0;
  int _weekAvg = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final prayed = await _repo.prayedToday();
    final dhikr = await _repo.dhikrDoneOn(now);
    final sunnah = await _repo.sunnahDoneOn(now);
    final khatma = await _repo.activeKhatma();
    final pages = await _repo.todayKhatmaPages();
    final memDue = await MemorizationRepo().dueCount();
    final qiyam = await _extras.qiyamOn(now);
    final sadaqah = await _extras.sadaqahToday();
    final streak = await _repo.fullDaysStreak();
    final week = await _repo.weeklyStats();

    final target = khatma?.dailyTarget ?? 4;
    final tasks = <ProgramTask>[
      ProgramTask(
        id: 'prayers',
        title: tr('الصلوات الخمس', 'The five prayers'),
        emoji: '🕌',
        done: prayed.length,
        target: 5,
        weight: 5,
      ),
      ProgramTask(
        id: 'quran',
        title: tr('ورد القرآن', 'Quran portion'),
        emoji: '📖',
        done: pages,
        target: target,
        weight: 3,
      ),
      ProgramTask(
        id: 'adhkar',
        title: tr('أذكار الصباح والمساء', 'Morning & evening adhkar'),
        emoji: '📿',
        done: dhikr.length,
        target: 2,
        weight: 3,
      ),
      ProgramTask(
        id: 'sunnah',
        title: tr('سنّة أو نافلة', 'A sunnah or nafl'),
        emoji: '🤲',
        done: sunnah.length.clamp(0, 1),
        target: 1,
        weight: 2,
      ),
      ProgramTask(
        id: 'memorize',
        title: tr('مراجعة الحفظ', 'Memorization review'),
        emoji: '🧠',
        done: memDue == 0 ? 1 : 0,
        target: 1,
        weight: 1,
      ),
      ProgramTask(
        id: 'qiyam',
        title: tr('قيام الليل', 'Night prayer'),
        emoji: '🌙',
        done: qiyam ? 1 : 0,
        target: 1,
        weight: 1,
      ),
      ProgramTask(
        id: 'sadaqah',
        title: tr('صدقة اليوم', "Today's charity"),
        emoji: '💚',
        done: sadaqah ? 1 : 0,
        target: 1,
        weight: 1,
      ),
    ];

    // متوسط الأسبوع التقريبى: نسبة الصلوات + أيام الأذكار (مؤشّر كافٍ للمستوى).
    final avg = (((week.prayers / 35) + (week.dhikrDays / 7)) / 2 * 100)
        .round()
        .clamp(0, 100);

    if (!mounted) return;
    setState(() {
      _day = ProgramDay(tasks);
      _streak = streak;
      _weekAvg = avg;
      _loading = false;
    });
  }

  Future<void> _openTask(ProgramTask t) async {
    Widget? screen;
    switch (t.id) {
      case 'prayers':
      case 'sunnah':
        screen = const PrayerScreen();
      case 'quran':
        screen = const KhatmaScreen();
      case 'adhkar':
        screen = const AdhkarScreen(morning: true);
      case 'memorize':
        screen = const MemorizationScreen();
      case 'sadaqah':
        screen = const SadaqahScreen();
      case 'qiyam':
        await _toggleQiyam();
        return;
    }
    final target = screen;
    if (target == null || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    if (mounted) await _load();
  }

  Future<void> _toggleQiyam() async {
    final now = DateTime.now();
    final cur = await _extras.qiyamOn(now);
    await _extras.setQiyam(now, !cur);
    HapticFeedback.selectionClick();
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = _day;
    return Scaffold(
      appBar: AppBar(title: Text(tr('برنامجى الدينى', 'My worship program'))),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerCard(d, scheme),
                  const SizedBox(height: 16),
                  if (d.nextUp != null) ...[
                    _nextUpCard(d.nextUp!, scheme),
                    const SizedBox(height: 16),
                  ],
                  Text(tr('خطة اليوم', "Today's plan"),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final t in d.tasks) _taskTile(t, scheme),
                  const SizedBox(height: 12),
                  _duaCard(scheme),
                ],
              ),
            ),
    );
  }

  Widget _headerCard(ProgramDay d, ColorScheme scheme) {
    final pct = d.percent;
    final level = levelFor(_weekAvg);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E7A5A), Color(0xFF16543F), Color(0xFF0C2A20)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tr('إنجاز اليوم', "Today's progress"),
                    style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                      tr(levelLabelAr(level), levelLabelEn(level)),
                      style: const TextStyle(
                          color: Color(0xFFF3D06E),
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${arNum(pct)}٪',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                Text(
                    tr('${arNum(d.completedCount)} من ${arNum(d.tasks.length)} بنود',
                        '${arNum(d.completedCount)}/${arNum(d.tasks.length)} done'),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                color: const Color(0xFF2FDE9B),
              ),
            ),
            const SizedBox(height: 10),
            Text(tr(programMessageAr(pct), programMessageEn(pct)),
                style: const TextStyle(color: Colors.white, height: 1.5)),
            if (_streak > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                    tr('${arNum(_streak)} يوم صلاة كاملة متتالية',
                        '${arNum(_streak)}-day full-prayer streak'),
                    style: const TextStyle(
                        color: Color(0xFFF3D06E),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nextUpCard(ProgramTask t, ColorScheme scheme) => Card(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        child: ListTile(
          leading: Text(t.emoji, style: const TextStyle(fontSize: 28)),
          title: Text(tr('التالى: ${t.title}', 'Next: ${t.title}'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
              t.target > 1
                  ? tr('${arNum(t.done)} من ${arNum(t.target)}',
                      '${arNum(t.done)} of ${arNum(t.target)}')
                  : tr('لسه ماتمّش', 'Not done yet'),
              style: TextStyle(color: scheme.onSurfaceVariant)),
          trailing: FilledButton(
            onPressed: () => _openTask(t),
            child: Text(tr('يلا بينا', 'Go')),
          ),
        ),
      );

  Widget _taskTile(ProgramTask t, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        onTap: () => _openTask(t),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: t.ratio,
                strokeWidth: 3.5,
                backgroundColor: scheme.surfaceContainerHighest,
                color: t.complete ? const Color(0xFF2FA36B) : scheme.primary,
              ),
            ),
            Text(t.emoji, style: const TextStyle(fontSize: 16)),
          ],
        ),
        title: Text(t.title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: t.complete ? scheme.onSurfaceVariant : null)),
        subtitle: Text(
          t.target > 1
              ? '${arNum(t.done)} / ${arNum(t.target)}'
              : (t.complete ? tr('تمّ ✓', 'Done ✓') : tr('لسه', 'Pending')),
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        trailing: t.complete
            ? const Icon(Icons.check_circle, color: Color(0xFF2FA36B))
            : const Icon(Icons.chevron_left),
      ),
    );
  }

  Widget _duaCard(ColorScheme scheme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(tr('دعاء اليوم', "Today's du'a"),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text(duaOfDay(DateTime.now()),
                style: const TextStyle(fontSize: 16, height: 1.9)),
          ],
        ),
      );
}
