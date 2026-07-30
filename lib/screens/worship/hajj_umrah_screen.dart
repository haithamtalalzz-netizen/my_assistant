import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_more.dart';
import '../../data/settings_repo.dart';

/// دليل العمرة والحج — خطوات مرتّبة قابلة للتعليم + عدّاد أشواط الطواف/السعى.
class HajjUmrahScreen extends StatefulWidget {
  const HajjUmrahScreen({super.key});

  @override
  State<HajjUmrahScreen> createState() => _HajjUmrahScreenState();
}

class _HajjUmrahScreenState extends State<HajjUmrahScreen> {
  Set<int> _umrahDone = {};
  Set<int> _hajjDone = {};
  static const _kUmrah = 'umrah_steps_done';
  static const _kHajj = 'hajj_steps_done';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _umrahDone = await _read(_kUmrah);
    _hajjDone = await _read(_kHajj);
    if (mounted) setState(() {});
  }

  Future<Set<int>> _read(String key) async {
    final raw = await SettingsRepo().get(key) ?? '';
    if (raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e as int).toSet();
    } on FormatException {
      return {};
    }
  }

  Future<void> _toggle(String key, Set<int> set, int i) async {
    setState(() => set.contains(i) ? set.remove(i) : set.add(i));
    await SettingsRepo().set(key, jsonEncode(set.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('العمرة والحج', 'Umrah & Hajj')),
          bottom: TabBar(tabs: [
            Tab(text: tr('العمرة', 'Umrah')),
            Tab(text: tr('الحج', 'Hajj')),
          ]),
        ),
        body: TabBarView(
          children: [
            _tab(kUmrahSteps, _kUmrah, _umrahDone),
            _tab(kHajjSteps, _kHajj, _hajjDone),
          ],
        ),
      ),
    );
  }

  Widget _tab(List<String> steps, String key, Set<int> done) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _LapCounter(),
        const SizedBox(height: 4),
        Text(tr('علّم كل خطوة بعد ما تخلّصها',
            'Tick each rite as you complete it'),
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Card(
            child: InkWell(
              onTap: () => _toggle(key, done, i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      done.contains(i)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: done.contains(i)
                          ? Colors.green
                          : scheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(steps[i],
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.9,
                            color: done.contains(i) ? scheme.outline : null,
                            decoration: done.contains(i)
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// عدّاد أشواط الطواف/السعى (٧) — دوس تزوّد، ويهتزّ عند اكتمال السبعة.
class _LapCounter extends StatefulWidget {
  const _LapCounter();

  @override
  State<_LapCounter> createState() => _LapCounterState();
}

class _LapCounterState extends State<_LapCounter> {
  int _laps = 0;

  void _tap() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_laps >= 7) {
        _laps = 1;
      } else {
        _laps++;
        if (_laps == 7) HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = _laps >= 7;
    return Card(
      color: scheme.primaryContainer.withValues(alpha: .4),
      child: InkWell(
        onTap: _tap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.threesixty, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('عدّاد الأشواط (طواف/سعى)', 'Lap counter (tawaf/sa‘i)'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      full
                          ? tr('اكتملت ٧ أشواط ✓ — دوس للبدء من جديد',
                              '7 laps done ✓ — tap to restart')
                          : tr('دوس بعد كل شوط', 'Tap after each lap'),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text('${arNum(_laps)}/${arNum(7)}',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: full ? Colors.green : scheme.primary)),
            IconButton(
              tooltip: tr('تصفير', 'Reset'),
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _laps = 0),
            ),
          ]),
        ),
      ),
    );
  }
}
