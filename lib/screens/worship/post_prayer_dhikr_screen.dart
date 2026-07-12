import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';

/// أذكار ما بعد الصلاة — تسلسل موجّه بالضغط.
class PostPrayerDhikrScreen extends StatefulWidget {
  const PostPrayerDhikrScreen({super.key});

  @override
  State<PostPrayerDhikrScreen> createState() => _PostPrayerDhikrScreenState();
}

class _Step {
  final String text;
  final int count;
  const _Step(this.text, this.count);
}

const List<_Step> _seq = [
  _Step('أَسْتَغْفِرُ اللَّهَ', 3),
  _Step('اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ', 1),
  _Step('سُبْحَانَ اللَّهِ', 33),
  _Step('الْحَمْدُ لِلَّهِ', 33),
  _Step('اللَّهُ أَكْبَرُ', 33),
  _Step('لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', 1),
  _Step('آيَةُ الْكُرْسِىّ', 1),
];

class _PostPrayerDhikrScreenState extends State<PostPrayerDhikrScreen> {
  int _step = 0;
  int _left = _seq.first.count;
  bool _done = false;

  void _tap() {
    if (_done) return;
    HapticFeedback.selectionClick();
    setState(() {
      _left--;
      if (_left <= 0) {
        if (_step < _seq.length - 1) {
          _step++;
          _left = _seq[_step].count;
          HapticFeedback.mediumImpact();
        } else {
          _done = true;
          HapticFeedback.heavyImpact();
        }
      }
    });
  }

  void _reset() => setState(() {
        _step = 0;
        _left = _seq.first.count;
        _done = false;
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('أذكار بعد الصلاة', 'Post-prayer adhkar')),
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_step + (_done ? 1 : 0)) / _seq.length,
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(tr('${arNum(_step + 1)} من ${arNum(_seq.length)}',
                  '${arNum(_step + 1)} of ${arNum(_seq.length)}')),
              Expanded(
                child: Center(
                  child: _done
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🤲', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text(tr('تمّت أذكار الصلاة، تقبّل الله',
                                'Adhkar complete — may Allah accept'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_seq[_step].text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 26,
                                    height: 1.9,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 30),
                            Container(
                              width: 150,
                              height: 150,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primaryContainer,
                                border: Border.all(
                                    color: scheme.primary, width: 4),
                              ),
                              child: Text(arNum(_left),
                                  style: TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.onPrimaryContainer)),
                            ),
                          ],
                        ),
                ),
              ),
              if (!_done)
                Text(tr('اضغط فى أى مكان للعدّ', 'Tap anywhere to count'),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
