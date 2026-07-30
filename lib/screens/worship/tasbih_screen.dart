import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';

/// المسبحة الإلكترونية — دوس عشان تسبّح، بيعدّ فى مجموعات من 33.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _repo = WorshipRepo();
  int _count = 0; // العدّاد الحالى فى المجموعة.
  int _sets = 0; // كام مجموعة (33) خلصت.
  int _phraseIdx = 0;
  int _target = 33;
  int _lifetime = 0;
  List<String> _custom = [];
  static const _kCustom = 'tasbih_custom_phrases';

  List<String> get _phrases => [...kTasbihPhrases, ..._custom];

  @override
  void initState() {
    super.initState();
    _repo.tasbihTotal().then((v) => setState(() => _lifetime = v));
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final raw = await SettingsRepo().get(_kCustom) ?? '';
    if (raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => '$e').toList();
      if (mounted) setState(() => _custom = list);
    } on FormatException {
      // مخزّن تالف — نتجاهله.
    }
  }

  Future<void> _addPhrase() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('صيغة تسبيح مخصّصة', 'Custom phrase')),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('إضافة', 'Add'))),
        ],
      ),
    );
    final text = ctrl.text.trim();
    if (ok == true && text.isNotEmpty && !_phrases.contains(text)) {
      setState(() {
        _custom = [..._custom, text];
        _phraseIdx = _phrases.length - 1;
      });
      await SettingsRepo().set(_kCustom, jsonEncode(_custom));
    }
    ctrl.dispose();
  }

  Future<void> _customTarget() async {
    final ctrl = TextEditingController(text: '$_target');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('هدف مخصّص', 'Custom target')),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    final n = int.tryParse(toEnglishDigits(ctrl.text.trim()));
    if (ok == true && n != null && n > 0) {
      setState(() {
        _target = n;
        _count = 0;
      });
    }
    ctrl.dispose();
  }

  void _tap() {
    HapticFeedback.selectionClick();
    _repo.addTasbih(1);
    setState(() {
      _lifetime++;
      _count++;
      if (_count >= _target) {
        _count = 0;
        _sets++;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _resetCounter() => setState(() {
        _count = 0;
        _sets = 0;
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('المسبحة', 'Tasbih')),
        actions: [
          IconButton(
            tooltip: tr('تصفير العدّاد', 'Reset counter'),
            onPressed: _resetCounter,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // اختيار الذِّكر.
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _phrases.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _phrases.length) {
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(tr('صيغة', 'Phrase')),
                    onPressed: _addPhrase,
                  );
                }
                return ChoiceChip(
                  label: Text(_phrases[i]),
                  selected: i == _phraseIdx,
                  onSelected: (_) => setState(() => _phraseIdx = i),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // اختيار الهدف.
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final t in [33, 99, 100, 500])
                ChoiceChip(
                  label: Text(arNum(t)),
                  selected: _target == t,
                  onSelected: (_) => setState(() => _target = t),
                ),
              ChoiceChip(
                label: Text(([33, 99, 100, 500].contains(_target))
                    ? tr('هدف آخر…', 'Other…')
                    : arNum(_target)),
                selected: ![33, 99, 100, 500].contains(_target),
                onSelected: (_) => _customTarget(),
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: _tap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _phrases[_phraseIdx.clamp(0, _phrases.length - 1)],
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 200,
                      height: 200,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                        border: Border.all(color: scheme.primary, width: 4),
                      ),
                      child: Text(
                        arNum(_count),
                        style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('المجموعات: ${arNum(_sets)}  ·  الإجمالى: ${arNum(_lifetime)}',
                          'Sets: ${arNum(_sets)}  ·  Total: ${arNum(_lifetime)}'),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Text(tr('اضغط فى أى مكان للتسبيح', 'Tap anywhere to count'),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12)),
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
