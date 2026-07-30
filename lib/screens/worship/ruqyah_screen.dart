import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/quran_data.dart';

/// الرقية الشرعية — آيات وأذكار (النصوص من المصحف المتحقَّق) + عدّاد تكرار ٣×.
class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
  int _reps = 0;

  void _tapReps() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_reps >= 3) {
        _reps = 1;
      } else {
        _reps++;
        if (_reps == 3) HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('الرقية الشرعية', 'Ruqyah'))),
      body: FutureBuilder<List<QuranSurah>>(
        future: QuranData.surahs(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          String ayah(int s, int a) =>
              all[s - 1].verses.firstWhere((v) => v.id == a).text;
          String surah(int s) => all[s - 1].verses.map((v) => v.text).join(' ');

          final sections = <({String title, String text})>[
            (title: 'سورة الفاتحة', text: surah(1)),
            (title: 'آية الكرسى (البقرة 255)', text: ayah(2, 255)),
            (
              title: 'آخر آيتين من البقرة (285-286)',
              text: '${ayah(2, 285)} ${ayah(2, 286)}'
            ),
            (title: 'سورة الإخلاص', text: surah(112)),
            (title: 'سورة الفلق', text: surah(113)),
            (title: 'سورة الناس', text: surah(114)),
            (
              title: 'من أذكار الرقية',
              text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ '
                  '(ثلاثًا)\n\nبِسْمِ اللَّهِ الَّذِى لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِى '
                  'الْأَرْضِ وَلَا فِى السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ (ثلاثًا)\n\n'
                  'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ'
            ),
          ];

          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr('تُقرأ على النفس أو المريض مع النفث، مع اليقين بأن الشفاء من الله وحده.',
                      'Recited over oneself or the sick, trusting that healing is from Allah alone.'),
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: scheme.primaryContainer.withValues(alpha: .5),
                child: InkWell(
                  onTap: _tapReps,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(Icons.repeat, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            _reps >= 3
                                ? tr('تمّت ٣ مرات ✓ — دوس للبدء من جديد',
                                    'Done 3× ✓ — tap to restart')
                                : tr('عدّاد التكرار (تُقرأ ٣ مرات) — دوس بعد كل مرة',
                                    'Repetition counter (recite 3×) — tap after each'),
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      Text('${arNum(_reps)}/${arNum(3)}',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _reps >= 3 ? Colors.green : scheme.primary)),
                      IconButton(
                        tooltip: tr('تصفير', 'Reset'),
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() => _reps = 0),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final sec in sections)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sec.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary)),
                        const SizedBox(height: 10),
                        Text(sec.text,
                            style: const TextStyle(fontSize: 19, height: 2.1)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
