import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/search_action.dart';
import '../data/challenges_repo.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _repo = ChallengesRepo();
  bool _loading = true;
  List<Challenge> _items = [];
  final Map<int, int> _done = {};
  final Map<int, bool> _todayDone = {};

  static const _presets = [
    ('شهر بلا سكر', 30),
    ('مشي يومي', 30),
    ('ورد قرآن يومي', 30),
    ('من غير سوشيال', 21),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    _done.clear();
    _todayDone.clear();
    final today = _repo.todayKey();
    for (final c in items) {
      _done[c.id!] = await _repo.doneCount(c.id!);
      _todayDone[c.id!] = await _repo.isDoneOn(c.id!, today);
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final name = TextEditingController();
    var days = 30;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('تحدّي جديد', 'New challenge')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration:
                    InputDecoration(labelText: tr('التحدّي', 'Challenge')),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final p in _presets)
                    ActionChip(
                      label: Text(p.$1),
                      onPressed: () => setD(() {
                        name.text = p.$1;
                        days = p.$2;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(tr('المدة', 'Duration'))),
                  DropdownButton<int>(
                    value: days,
                    items: [
                      for (final d in [7, 21, 30, 60, 90])
                        DropdownMenuItem(
                            value: d,
                            child: Text(tr('${arNum(d)} يوم', '${arNum(d)} days'))),
                    ],
                    onChanged: (v) => setD(() => days = v ?? days),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('ابدأ', 'Start'))),
          ],
        ),
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.add(Challenge(
        name: name.text.trim(),
        startDate: dayKey(DateTime.now()),
        days: days,
      ));
      if (mounted) await _load();
    }
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التحديات', 'Challenges')),
          actions: [searchAction(context)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.flag_outlined,
                  text: tr('ابدأ تحدّي (شهر بلا سكر، مشي يومي...) وعلّم كل يوم تنجح فيه',
                      'Start a challenge (no sugar, daily walk...) and check off each day'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final c = _items[i];
                    final dayNo = c.dayNumber(now).clamp(1, c.days);
                    final done = _done[c.id!] ?? 0;
                    final todayDone = _todayDone[c.id!] ?? false;
                    final finished = dayNo >= c.days;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () async {
                                    if (!await confirmDelete(context,
                                        tr('«${c.name}»', '"${c.name}"'))) {
                                      return;
                                    }
                                    await _repo.delete(c.id!);
                                    if (mounted) await _load();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: done / c.days,
                                minHeight: 8,
                                color: finished ? Colors.green : scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                tr('اليوم ${arNum(dayNo)} من ${arNum(c.days)} — نجحت ${arNum(done)} يوم',
                                    'Day ${arNum(dayNo)} of ${arNum(c.days)} — ${arNum(done)} days done'),
                                style: TextStyle(
                                    fontSize: 13, color: scheme.outline)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: todayDone
                                  ? OutlinedButton.icon(
                                      onPressed: () async {
                                        await _repo.setDone(
                                            c.id!, _repo.todayKey(), false);
                                        if (mounted) await _load();
                                      },
                                      icon: const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      label: Text(tr('نجحت النهارده ✓',
                                          'Done today ✓')),
                                    )
                                  : FilledButton.tonal(
                                      onPressed: () async {
                                        await _repo.setDone(
                                            c.id!, _repo.todayKey(), true);
                                        if (mounted) await _load();
                                      },
                                      child: Text(tr('علّم النهارده',
                                          'Mark today')),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenge_fab',
        onPressed: _add,
        tooltip: tr('تحدّي جديد', 'New challenge'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
