import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_more.dart';
import '../../data/worship_repo.dart';

/// الوِرد اليومى — أذكار بأهداف يومية مع عدّاد يتصفّر كل يوم.
class DailyWirdScreen extends StatefulWidget {
  const DailyWirdScreen({super.key});

  @override
  State<DailyWirdScreen> createState() => _DailyWirdScreenState();
}

class _DailyWirdScreenState extends State<DailyWirdScreen> {
  final _repo = WorshipRepo();
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _repo.wirdCounts(DateTime.now());
    if (!mounted) return;
    setState(() {
      _counts = c;
      _loading = false;
    });
  }

  Future<void> _inc(int idx) async {
    final goal = kWirdPhrases[idx].goal;
    final cur = _counts[idx] ?? 0;
    if (cur >= goal) return;
    HapticFeedback.selectionClick();
    final next = cur + 1;
    setState(() => _counts = {..._counts, idx: next});
    await _repo.setWird(DateTime.now(), idx, next);
    if (next >= goal) HapticFeedback.mediumImpact();
  }

  Future<void> _reset(int idx) async {
    setState(() => _counts = {..._counts, idx: 0});
    await _repo.setWird(DateTime.now(), idx, 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final doneCount =
        kWirdPhrases.asMap().entries.where((e) => (_counts[e.key] ?? 0) >= e.value.goal).length;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الوِرد اليومى', 'Daily wird'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    tr('أكملت ${arNum(doneCount)} من ${arNum(kWirdPhrases.length)} أذكار اليوم',
                        'Completed ${arNum(doneCount)} of ${arNum(kWirdPhrases.length)} today'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: kWirdPhrases.length,
                    itemBuilder: (_, i) {
                      final p = kWirdPhrases[i];
                      final c = _counts[i] ?? 0;
                      final done = c >= p.goal;
                      return Card(
                        color: done
                            ? scheme.primaryContainer.withValues(alpha: 0.4)
                            : null,
                        child: InkWell(
                          onTap: () => _inc(i),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(p.text,
                                          style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              height: 1.8)),
                                    ),
                                    if (done)
                                      const Icon(Icons.check_circle,
                                          color: Color(0xFF2FA36B)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                      value: c / p.goal, minHeight: 8),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('${arNum(c)} / ${arNum(p.goal)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    const Spacer(),
                                    if (c > 0)
                                      TextButton(
                                          onPressed: () => _reset(i),
                                          child: Text(tr('تصفير', 'Reset'))),
                                    Text(tr('اضغط للعدّ', 'tap to count'),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
