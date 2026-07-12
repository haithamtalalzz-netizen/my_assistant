import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';

/// المناسبات الإسلامية — عدّ تنازلى لأقرب حدث بالتقويم الهجرى.
class IslamicOccasionsScreen extends StatelessWidget {
  const IslamicOccasionsScreen({super.key});

  static const List<({int m, int d, String ar, String en, String emoji})> _events = [
    (m: 1, d: 1, ar: 'رأس السنة الهجرية', en: 'Hijri New Year', emoji: '🌙'),
    (m: 1, d: 10, ar: 'عاشوراء', en: 'Ashura', emoji: '🕌'),
    (m: 3, d: 12, ar: 'المولد النبوى', en: 'Mawlid', emoji: '🕋'),
    (m: 7, d: 27, ar: 'الإسراء والمعراج', en: 'Isra & Miraj', emoji: '✨'),
    (m: 8, d: 15, ar: 'النصف من شعبان', en: 'Mid-Sha\'ban', emoji: '🌛'),
    (m: 9, d: 1, ar: 'أول رمضان', en: 'Ramadan begins', emoji: '🌙'),
    (m: 9, d: 27, ar: 'ليلة القدر (تحرّى)', en: 'Laylat al-Qadr', emoji: '⭐'),
    (m: 10, d: 1, ar: 'عيد الفطر', en: 'Eid al-Fitr', emoji: '🎉'),
    (m: 12, d: 9, ar: 'يوم عرفة', en: 'Day of Arafah', emoji: '🏔'),
    (m: 12, d: 10, ar: 'عيد الأضحى', en: 'Eid al-Adha', emoji: '🐑'),
  ];

  DateTime _nextFor(int m, int d, DateTime today) {
    final hc = HijriCalendar.now();
    for (final y in [hc.hYear, hc.hYear + 1, hc.hYear + 2]) {
      try {
        final g = dateOnly(HijriCalendar().hijriToGregorian(y, m, d));
        if (!g.isBefore(today)) return g;
      } catch (_) {}
    }
    return today;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final items = _events
        .map((e) => (e: e, date: _nextFor(e.m, e.d, today)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: Text(tr('المناسبات الإسلامية', 'Islamic occasions'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          final days = it.date.difference(today).inDays;
          final soon = days <= 14;
          return Card(
            color: soon ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
            child: ListTile(
              leading: Text(it.e.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(AppState.isEnglish ? it.e.en : it.e.ar,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(arShortDate(it.date)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    days == 0
                        ? tr('اليوم', 'Today')
                        : tr('بعد ${arNum(days)} يوم', 'in ${arNum(days)}d'),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: soon ? scheme.primary : scheme.onSurface),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
