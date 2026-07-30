import 'dart:convert';
import 'dart:math';

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
            tooltip: tr('اختبار الأسماء', 'Names quiz'),
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const _NamesQuizPage())),
          ),
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

/// اختبار أسماء الله الحسنى — يُعرض المعنى وتختار الاسم الصحيح من ٤ (١٠ أسئلة).
class _NamesQuizPage extends StatefulWidget {
  const _NamesQuizPage();

  @override
  State<_NamesQuizPage> createState() => _NamesQuizPageState();
}

class _NamesQuizPageState extends State<_NamesQuizPage> {
  static const _total = 10;
  final _rnd = Random();
  late List<int> _order; // فهارس الأسئلة
  int _q = 0;
  int _score = 0;
  int? _picked; // الفهرس المختار للسؤال الحالى
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _order = List.generate(kNames99.length, (i) => i)..shuffle(_rnd);
    _order = _order.take(_total).toList();
    _buildOptions();
  }

  void _buildOptions() {
    final answer = _order[_q];
    final opts = <int>{answer};
    while (opts.length < 4) {
      opts.add(_rnd.nextInt(kNames99.length));
    }
    _options = opts.toList()..shuffle(_rnd);
    _picked = null;
  }

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (i == _order[_q]) _score++;
    });
  }

  void _next() {
    if (_q >= _total - 1) {
      setState(() => _q = _total); // شاشة النتيجة
      return;
    }
    setState(() {
      _q++;
      _buildOptions();
    });
  }

  void _restart() {
    setState(() {
      _order = (List.generate(kNames99.length, (i) => i)..shuffle(_rnd))
          .take(_total)
          .toList();
      _q = 0;
      _score = 0;
      _buildOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('اختبار الأسماء', 'Names quiz'))),
      body: _q >= _total ? _result(scheme) : _question(scheme),
    );
  }

  Widget _result(ColorScheme scheme) {
    final pct = (_score / _total * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pct >= 70 ? '🎉' : '📿', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              tr('نتيجتك: ${arNum(_score)} من ${arNum(_total)}',
                  'Score: ${arNum(_score)} / ${arNum(_total)}'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text('${arNum(pct)}٪',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: pct >= 70 ? Colors.green : scheme.primary)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh),
              label: Text(tr('اختبار جديد', 'New quiz')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _question(ColorScheme scheme) {
    final answer = _order[_q];
    return Column(
      children: [
        LinearProgressIndicator(value: _q / _total, minHeight: 6),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text(tr('سؤال ${arNum(_q + 1)} من ${arNum(_total)}',
                  'Q ${arNum(_q + 1)} of ${arNum(_total)}')),
              const Spacer(),
              Text(tr('النتيجة: ${arNum(_score)}', 'Score: ${arNum(_score)}'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(tr('ما الاسم الذى معناه؟', 'Which name means?'),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                Text(kNames99Meaning[answer],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19, height: 1.9, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              for (final opt in _options) _optionTile(opt, answer, scheme),
            ],
          ),
        ),
        if (_picked != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: FilledButton(
              onPressed: _next,
              child: Text(_q >= _total - 1
                  ? tr('النتيجة', 'Result')
                  : tr('التالى', 'Next')),
            ),
          ),
      ],
    );
  }

  Widget _optionTile(int opt, int answer, ColorScheme scheme) {
    Color? bg;
    if (_picked != null) {
      if (opt == answer) {
        bg = Colors.green.withValues(alpha: 0.2);
      } else if (opt == _picked) {
        bg = scheme.error.withValues(alpha: 0.15);
      }
    }
    return Card(
      color: bg,
      child: ListTile(
        onTap: () => _pick(opt),
        title: Text(kNames99[opt],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        trailing: _picked == null
            ? null
            : opt == answer
                ? const Icon(Icons.check_circle, color: Colors.green)
                : opt == _picked
                    ? Icon(Icons.cancel, color: scheme.error)
                    : null,
      ),
    );
  }
}
