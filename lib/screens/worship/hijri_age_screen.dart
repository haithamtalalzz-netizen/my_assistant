import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/app_state.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';

/// حاسبة العمر بالهجرى + عدد الرمضانات التى عشتها.
class HijriAgeScreen extends StatefulWidget {
  const HijriAgeScreen({super.key});

  @override
  State<HijriAgeScreen> createState() => _HijriAgeScreenState();
}

class _HijriAgeScreenState extends State<HijriAgeScreen> {
  DateTime? _birth;

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _birth = d);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    HijriCalendar.setLocal(AppState.isEnglish ? 'en' : 'ar');
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    int ageYears = 0, ageMonths = 0, ramadans = 0;
    if (_birth != null) {
      final b = HijriCalendar.fromDate(_birth!);
      final n = HijriCalendar.now();
      ageYears = n.hYear - b.hYear;
      ageMonths = n.hMonth - b.hMonth;
      if (n.hDay < b.hDay) ageMonths--;
      if (ageMonths < 0) {
        ageYears--;
        ageMonths += 12;
      }
      for (var y = b.hYear; y <= n.hYear; y++) {
        try {
          final r = HijriCalendar().hijriToGregorian(y, 9, 1);
          final rd = DateTime(r.year, r.month, r.day);
          if (!rd.isBefore(_birth!) && !rd.isAfter(today)) ramadans++;
        } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('عمرك بالهجرى', 'Your Hijri age'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.tonalIcon(
            onPressed: _pick,
            icon: const Icon(Icons.cake_outlined),
            label: Text(_birth == null
                ? tr('اختر تاريخ ميلادك', 'Pick your birth date')
                : tr('تاريخ الميلاد: ${arShortDate(_birth!)}',
                    'Birth date: ${arShortDate(_birth!)}')),
          ),
          const SizedBox(height: 20),
          if (_birth != null) ...[
            _card(
              scheme,
              '🎂',
              tr('عمرك بالتقويم الهجرى', 'Your Hijri age'),
              tr('${arNum(ageYears)} سنة و${arNum(ageMonths)} شهر',
                  '${arNum(ageYears)} y, ${arNum(ageMonths)} m'),
            ),
            const SizedBox(height: 12),
            _card(
              scheme,
              '🌙',
              tr('عدد الرمضانات التى عشتها', 'Ramadans you have lived'),
              tr('${arNum(ramadans)} رمضان', '${arNum(ramadans)} Ramadans'),
            ),
            const SizedBox(height: 16),
            Text(
              tr('«اغتنم خمسًا قبل خمس: شبابك قبل هرمك…»',
                  'Seize five before five: your youth before old age…'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(ColorScheme scheme, String emoji, String label, String value) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );
}
