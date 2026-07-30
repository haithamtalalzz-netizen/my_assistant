import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';
import '../../data/settings_repo.dart';

/// أسماء الله الحسنى — شبكة الـ99 + المعنى عند الضغط + وضع الحفظ.
class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  bool _memorize = false; // يخفى الاسم ويكشفه عند الضغط.
  Set<int> _done = {}; // فهارس الأسماء المحفوظة.
  static const _kDone = 'names_memorized';

  @override
  void initState() {
    super.initState();
    _loadDone();
  }

  Future<void> _loadDone() async {
    final raw = await SettingsRepo().get(_kDone) ?? '';
    if (raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => e as int).toSet();
      if (mounted) setState(() => _done = list);
    } on FormatException {
      // مخزّن تالف — نتجاهله.
    }
  }

  Future<void> _toggleDone(int i) async {
    setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i));
    await SettingsRepo().set(_kDone, jsonEncode(_done.toList()));
  }

  void _open(int i) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(arNum(i + 1),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(kNames99[i],
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: scheme.primary)),
              const SizedBox(height: 14),
              Text(kNames99Meaning[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, height: 1.9)),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await _toggleDone(i);
                  setSheet(() {});
                },
                icon: Icon(_done.contains(i)
                    ? Icons.check_circle
                    : Icons.check_circle_outline),
                label: Text(_done.contains(i)
                    ? tr('حفظته ✓', 'Memorized ✓')
                    : tr('علّمه محفوظ', 'Mark memorized')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('أسماء الله الحسنى', 'Names of Allah')),
        actions: [
          IconButton(
            tooltip: tr('وضع الحفظ', 'Memorize mode'),
            isSelected: _memorize,
            icon: const Icon(Icons.visibility_off_outlined),
            selectedIcon: const Icon(Icons.visibility),
            onPressed: () => setState(() => _memorize = !_memorize),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 16),
              const SizedBox(width: 6),
              Text(
                  tr('حفظت ${arNum(_done.length)} من ٩٩',
                      'Memorized ${arNum(_done.length)}/99'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.primary)),
            ]),
          ),
          if (_memorize)
            Container(
              width: double.infinity,
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(8),
              child: Text(
                tr('وضع الحفظ: الاسم مخفى — اضغط للكشف عنه ومعناه',
                    'Memorize mode: names hidden — tap to reveal + meaning'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kNames99.length,
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _open(i),
                child: Stack(
                  children: [
                    if (_done.contains(i))
                      const PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                      ),
                    Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.7),
                        scheme.primaryContainer.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _memorize ? '﴾ ؟ ﴿' : kNames99[i],
                        style: TextStyle(
                            fontSize: _memorize ? 16 : 20,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(arNum(i + 1),
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimaryContainer
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
