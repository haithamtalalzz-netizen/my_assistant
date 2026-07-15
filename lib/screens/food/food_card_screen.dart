import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/usda_food_db.dart';

/// دليل الأكل: بحث فى ٦٨٧٦ صنف بقيمهم الغذائية الكاملة — أرقام USDA حرفياً.
class FoodCardScreen extends StatefulWidget {
  const FoodCardScreen({super.key});

  @override
  State<FoodCardScreen> createState() => _FoodCardScreenState();
}

class _FoodCardScreenState extends State<FoodCardScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<UsdaFood> _results = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    // بنسخّن القاعدة بدرى عشان أول بحث يبقى سريع.
    UsdaDb.all().then((l) {
      if (mounted) setState(() => _total = l.length);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final r = await UsdaDb.search(q);
    if (!mounted) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('دليل الأكل', 'Food guide'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('دوّر: فراخ، رز، بطاطس، تفاح...',
                    'Search: chicken, rice, potato...'),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctrl.clear();
                          _run('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _ctrl.text.trim().length < 2
                    ? _intro(scheme)
                    : _results.isEmpty
                        ? Center(
                            child: Text(tr('مفيش نتائج', 'No results'),
                                style: TextStyle(color: scheme.outline)))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (_, i) => _row(_results[i], scheme),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _intro(ColorScheme scheme) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.restaurant_menu, size: 64, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            _total == 0
                ? tr('بحمّل قاعدة الأكل...', 'Loading food database...')
                : tr('${arNum(_total)} صنف أكل وشرب',
                    '${arNum(_total)} foods & drinks'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
                'كل الأرقام من قاعدة USDA الأمريكية الرسمية — سعرات وبروتين وكارب ودهون وألياف وسكر وصوديوم وكوليسترول وكالسيوم وحديد وبوتاسيوم.\n\nوكل صنف بطرق طهيه: نيّئ / مسلوق / مشوى / مقلى — والأرقام بتختلف فعلاً.',
                'All numbers from the official USDA database — calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol, calcium, iron & potassium.\n\nEach food by cooking method: raw / boiled / grilled / fried — the numbers really differ.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
          ),
        ],
      );

  Widget _row(UsdaFood f, ColorScheme scheme) {
    final p = prepLabel(f.prep);
    return ListTile(
      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        f.cat,
        if (p.isNotEmpty) p,
      ].where((s) => s.isNotEmpty).join('  •  ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(arNum(f.kcal.round()),
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: scheme.primary)),
          Text(tr('سعرة/١٠٠جم', 'kcal/100g'),
              style: const TextStyle(fontSize: 10)),
        ],
      ),
      onTap: () => showFoodCard(context, f),
    );
  }
}

/// **الكارت**: كل بيانات الصنف + طرق طهيه التانية + حاسبة الكمية.
Future<void> showFoodCard(BuildContext context, UsdaFood food) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, sc) => _FoodCardBody(food: food, scroll: sc),
    ),
  );
}

class _FoodCardBody extends StatefulWidget {
  final UsdaFood food;
  final ScrollController scroll;
  const _FoodCardBody({required this.food, required this.scroll});

  @override
  State<_FoodCardBody> createState() => _FoodCardBodyState();
}

class _FoodCardBodyState extends State<_FoodCardBody> {
  late UsdaFood _food;
  late double _grams;
  List<UsdaFood> _variants = [];

  @override
  void initState() {
    super.initState();
    _food = widget.food;
    _grams = _food.defaultGrams.toDouble();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final v = await UsdaDb.variants(_food);
    if (mounted) setState(() => _variants = v);
  }

  void _switchTo(UsdaFood f) {
    setState(() {
      _food = f;
      _grams = f.defaultGrams.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = _food.forGrams(_grams);
    final p = prepLabel(_food.prep);

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(_food.name,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(_food.en,
            style: TextStyle(fontSize: 11, color: scheme.outline)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (_food.cat.isNotEmpty) _chip(_food.cat, scheme),
          if (p.isNotEmpty) _chip(p, scheme, strong: true),
        ]),
        const SizedBox(height: 16),

        // ————— الكمية —————
        Text(tr('الكمية', 'Amount'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Slider(
              value: _grams.clamp(5, 500),
              min: 5,
              max: 500,
              divisions: 99,
              label: '${arNum(_grams.round())} ${tr('جم', 'g')}',
              onChanged: (v) => setState(() => _grams = v),
            ),
          ),
          Text('${arNum(_grams.round())} ${tr('جم', 'g')}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        Wrap(spacing: 6, children: [
          if (_food.portionGrams != null)
            ActionChip(
              avatar: const Icon(Icons.restaurant, size: 14),
              label: Text(
                  '${_food.portionLabel} (${arNum(_food.portionGrams!)} ${tr('جم', 'g')})'),
              onPressed: () =>
                  setState(() => _grams = _food.portionGrams!.toDouble()),
            ),
          for (final g in const [50, 100, 150, 200])
            ActionChip(
              label: Text('${arNum(g)} ${tr('جم', 'g')}'),
              onPressed: () => setState(() => _grams = g.toDouble()),
            ),
        ]),
        const SizedBox(height: 18),

        // ————— القيم الغذائية —————
        Text(
            tr('القيم الغذائية لـ${arNum(_grams.round())} جم',
                'Nutrition for ${arNum(_grams.round())} g'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _bigRow(scheme, n),
        const SizedBox(height: 8),
        _macroBar(scheme, n),
        const SizedBox(height: 12),
        _nutRow(tr('ألياف', 'Fiber'), n.fiber, 'جم', 'g'),
        _nutRow(tr('سكريات', 'Sugars'), n.sugar, 'جم', 'g'),
        _nutRow(tr('دهون مشبعة', 'Saturated fat'), n.sat, 'جم', 'g'),
        _nutRow(tr('كوليسترول', 'Cholesterol'), n.chol, 'مجم', 'mg'),
        _nutRow(tr('صوديوم', 'Sodium'), n.sodium, 'مجم', 'mg'),
        _nutRow(tr('كالسيوم', 'Calcium'), n.calcium, 'مجم', 'mg'),
        _nutRow(tr('حديد', 'Iron'), n.iron, 'مجم', 'mg'),
        _nutRow(tr('بوتاسيوم', 'Potassium'), n.potassium, 'مجم', 'mg'),

        // ————— طرق الطهى التانية —————
        if (_variants.length > 1) ...[
          const SizedBox(height: 20),
          Text(tr('نفس الصنف بطرق طهى تانية', 'Same food, other cooking methods'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
              tr('الأرقام لكل ١٠٠ جم — دوس على أى طريقة تشوف تفاصيلها',
                  'Per 100 g — tap any method to see its details'),
              style: TextStyle(fontSize: 11, color: scheme.outline)),
          const SizedBox(height: 8),
          for (final v in _variants) _variantRow(v, scheme),
        ],

        const SizedBox(height: 20),
        Row(children: [
          Icon(Icons.verified_outlined, size: 14, color: scheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tr('المصدر: USDA FoodData Central (SR Legacy) — ملكية عامة. الأرقام منقولة زى ما هى.',
                  'Source: USDA FoodData Central (SR Legacy) — public domain. Values copied as-is.'),
              style: TextStyle(fontSize: 10, color: scheme.outline),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _chip(String t, ColorScheme scheme, {bool strong = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: strong
              ? scheme.primary.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                color: strong ? scheme.primary : null)),
      );

  /// السعرات + الماكروز الكبار.
  Widget _bigRow(ColorScheme scheme, UsdaNutrients n) => Row(
        children: [
          _bigBox(scheme, tr('سعرات', 'Calories'), n.kcal, '', scheme.primary),
          _bigBox(scheme, tr('بروتين', 'Protein'), n.protein,
              tr('جم', 'g'), Colors.blue),
          _bigBox(scheme, tr('كارب', 'Carbs'), n.carbs, tr('جم', 'g'),
              Colors.orange),
          _bigBox(scheme, tr('دهون', 'Fat'), n.fat, tr('جم', 'g'),
              Colors.redAccent),
        ],
      );

  Widget _bigBox(
          ColorScheme scheme, String label, double v, String unit, Color c) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(arNum(v < 10 ? v.toStringAsFixed(1) : v.round().toString()),
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900, color: c)),
              Text(unit.isEmpty ? label : '$label ($unit)',
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );

  /// شريط نِسب الماكروز (بالسعرات: بروتين ٤ / كارب ٤ / دهون ٩).
  Widget _macroBar(ColorScheme scheme, UsdaNutrients n) {
    final pc = n.protein * 4, cc = n.carbs * 4, fc = n.fat * 9;
    final tot = pc + cc + fc;
    if (tot <= 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(children: [
          Expanded(flex: (pc / tot * 1000).round(), child: Container(color: Colors.blue)),
          Expanded(flex: (cc / tot * 1000).round(), child: Container(color: Colors.orange)),
          Expanded(flex: (fc / tot * 1000).round(), child: Container(color: Colors.redAccent)),
        ]),
      ),
    );
  }

  /// سطر عنصر غذائى — بيتخفى لو USDA ماعندهاش القيمة (مش بنخترع صفر).
  Widget _nutRow(String label, double? v, String arUnit, String enUnit) {
    if (v == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${arNum(v < 10 ? v.toStringAsFixed(1) : v.round().toString())} ${tr(arUnit, enUnit)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _variantRow(UsdaFood v, ColorScheme scheme) {
    final sel = v.id == _food.id;
    final diff = v.kcal - widget.food.kcal;
    return InkWell(
      onTap: () => _switchTo(v),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? scheme.primary.withValues(alpha: 0.10) : null,
          border: Border.all(
              color: sel ? scheme.primary : scheme.outlineVariant, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16, color: sel ? scheme.primary : scheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prepLabel(v.prep).isEmpty ? v.name : prepLabel(v.prep),
                style: TextStyle(
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w500),
              ),
            ),
            if (diff.abs() >= 1 && v.id != widget.food.id)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Text(
                  '${diff > 0 ? '+' : '−'}${arNum(diff.abs().round())}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: diff > 0 ? Colors.redAccent : Colors.green),
                ),
              ),
            Text('${arNum(v.kcal.round())} ${tr('سعرة', 'kcal')}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
