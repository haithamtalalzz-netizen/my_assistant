import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../data/worship_repo.dart';

/// إحصائية روحية أسبوعية — صلاة/أذكار/سنن/صيام/ختمة خلال آخر 7 أيام.
class SpiritualStatsScreen extends StatefulWidget {
  const SpiritualStatsScreen({super.key});

  @override
  State<SpiritualStatsScreen> createState() => _SpiritualStatsScreenState();
}

class _SpiritualStatsScreenState extends State<SpiritualStatsScreen> {
  final _repo = WorshipRepo();
  SpiritualWeek? _week;
  MonthPrayerStats? _month;
  int _prayerStreak = 0;
  int _dhikrStreak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await _repo.weeklyStats();
    final m = await _repo.monthlyPrayerStats();
    final ps = await _repo.fullDaysStreak();
    final ds = await _repo.dhikrStreak();
    if (!mounted) return;
    setState(() {
      _week = w;
      _month = m;
      _prayerStreak = ps;
      _dhikrStreak = ds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = _week;
    return Scaffold(
      appBar: AppBar(title: Text(tr('إحصائيتك الروحية', 'Your spiritual week'))),
      body: w == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(tr('آخر 7 أيام', 'Last 7 days'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _stat('🕌', tr('صلوات في وقتها', 'Prayers logged'),
                        '${arNum(w.prayers)} / ${arNum(35)}', const Color(0xFF2E7D6B)),
                    _stat('✅', tr('أيام كاملة', 'Full-prayer days'),
                        '${arNum(w.fullPrayerDays)} / ${arNum(7)}', const Color(0xFF3C5A99)),
                    _stat('📿', tr('أيام الأذكار', 'Adhkar days'),
                        '${arNum(w.dhikrDays)} / ${arNum(7)}', const Color(0xFF6A4C93)),
                    _stat('🌙', tr('أيام الصيام', 'Fasting days'),
                        arNum(w.fastingDays), const Color(0xFFCC8A2E)),
                    _stat('🤲', tr('سنن ونوافل', 'Sunnah acts'),
                        arNum(w.sunnahCount), const Color(0xFF2FA36B)),
                    _stat(
                        '📖',
                        tr('تقدّم الختمة', 'Khatma progress'),
                        w.khatmaPercent == null
                            ? '—'
                            : '${arNum(w.khatmaPercent!)}%',
                        const Color(0xFF1E7A5A)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_month != null) _monthCard(context, _month!),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Text('🔥', style: TextStyle(fontSize: 22)),
                        title: Text(tr('سلسلة الصلاة الكاملة', 'Full-prayer streak')),
                        trailing: Text(
                            tr('${arNum(_prayerStreak)} يوم', '${arNum(_prayerStreak)} d'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Text('🔥', style: TextStyle(fontSize: 22)),
                        title: Text(tr('سلسلة الأذكار', 'Adhkar streak')),
                        trailing: Text(
                            tr('${arNum(_dhikrStreak)} يوم', '${arNum(_dhikrStreak)} d'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// كارت الشهر: نسبة الالتزام + عدد مرات كل صلاة على أيام الشهر اللى عدّت.
  Widget _monthCard(BuildContext context, MonthPrayerStats m) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🗓', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      tr('صلاة ${arMonth(DateTime.now())}',
                          'Prayers — ${arMonth(DateTime.now())}'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text('${arNum(m.percent)}٪',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: m.percent >= 80
                            ? Colors.green
                            : scheme.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr('${arNum(m.fullDays)} يوم كامل من ${arNum(m.elapsedDays)}',
                  '${arNum(m.fullDays)} full days of ${arNum(m.elapsedDays)}'),
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 5; i++) ...[
              Row(
                children: [
                  SizedBox(
                      width: 64,
                      child: Text(prayerNameLabel(i),
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.elapsedDays == 0
                            ? 0
                            : (m.perPrayer[i] / m.elapsedDays)
                                .clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${arNum(m.perPrayer[i])}/${arNum(m.elapsedDays)}',
                      style:
                          TextStyle(fontSize: 11.5, color: scheme.outline),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12), maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
