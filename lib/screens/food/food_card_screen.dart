import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/egyptian_dishes.dart';
import '../../core/usda_food_db.dart';
import '../../data/meals_repo.dart';
import '../../models/models.dart';

/// دليل الأكل: بحث فى ~٦٠٠٠ صنف بقيمهم الغذائية الكاملة — أرقام USDA حرفياً.
/// (العدد الفعلى بيتقرا من الأصل نفسه وقت التشغيل، مش متكتوب هنا.)
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
  List<EgyptianDish> _dishes = [];
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
        _dishes = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final r = await UsdaDb.search(q);
    if (!mounted) return;
    setState(() {
      _dishes = searchDishes(q);
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
                    : (_results.isEmpty && _dishes.isEmpty)
                        ? Center(
                            child: Text(tr('مفيش نتائج', 'No results'),
                                style: TextStyle(color: scheme.outline)))
                        : ListView(
                            children: [
                              // الأكلات المصرية المحسوبة الأول.
                              if (_dishes.isNotEmpty) ...[
                                _sectionHeader(
                                    tr('أطباق جاهزة (محسوبة من USDA)',
                                        'Prepared dishes (computed from USDA)'),
                                    scheme),
                                for (final d in _dishes) _dishRow(d, scheme),
                              ],
                              for (final f in _results) _row(f, scheme),
                            ],
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

  Widget _sectionHeader(String text, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Icon(Icons.calculate_outlined, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary)),
          ],
        ),
      );

  Widget _dishRow(EgyptianDish d, ColorScheme scheme) {
    return ListTile(
      leading: const Text('🍽', style: TextStyle(fontSize: 22)),
      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: FutureBuilder<UsdaNutrients?>(
        future: dishNutrients(d),
        builder: (_, snap) {
          final n = snap.data;
          if (n == null) {
            return Text(tr('طبق ~${arNum(d.servingGrams.round())} جم',
                'plate ~${arNum(d.servingGrams.round())} g'));
          }
          return Text(
              tr('${arNum(n.kcal.round())} سعرة/طبق · محسوبة من مكوّناتها',
                  '${arNum(n.kcal.round())} kcal/plate · computed from ingredients'));
        },
      ),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => showDishCard(context, d),
    );
  }

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
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.restaurant, size: 18),
            label: Text(tr('سجّلها كوجبة النهاردة', 'Log as a meal today')),
            onPressed: () async {
              final ok = await logAsMeal(context,
                  name: '${_food.name} (${arNum(_grams.round())}${tr('جم', 'g')})',
                  grams: _grams,
                  kcal: n.kcal,
                  protein: n.protein,
                  carbs: n.carbs,
                  fat: n.fat);
              if (ok && context.mounted) Navigator.pop(context);
            },
          ),
        ),
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

/// كارت أكلة مصرية: القيم المحسوبة + تفصيل المكوّنات (كل مكوّن برقم USDA بتاعه)
/// + منزلق «كام طبق» + سطر يوضّح إن السعرات **محسوبة** مش مكتوبة.
Future<void> showDishCard(BuildContext context, EgyptianDish dish) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, sc) => _DishCardBody(dish: dish, scroll: sc),
    ),
  );
}

class _DishCardBody extends StatefulWidget {
  final EgyptianDish dish;
  final ScrollController scroll;
  const _DishCardBody({required this.dish, required this.scroll});

  @override
  State<_DishCardBody> createState() => _DishCardBodyState();
}

class _DishCardBodyState extends State<_DishCardBody> {
  double _plates = 1;
  UsdaNutrients? _n;
  List<({String name, double grams})> _parts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await dishNutrients(widget.dish);
    final all = await UsdaDb.all();
    final byId = {for (final f in all) f.id: f};
    final parts = <({String name, double grams})>[];
    for (final p in widget.dish.parts) {
      final f = byId[p.fdcId];
      if (f != null) parts.add((name: f.name, grams: p.grams));
    }
    if (!mounted) return;
    setState(() {
      _n = n;
      _parts = parts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final n = _n;
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('🍽 ${widget.dish.name}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        // كام طبق
        Row(children: [
          Text(tr('الكمية: ${arNum(_plates.toStringAsFixed(_plates == _plates.roundToDouble() ? 0 : 1))} طبق',
              'Amount: ${arNum(_plates.toStringAsFixed(_plates == _plates.roundToDouble() ? 0 : 1))} plate')),
          Expanded(
            child: Slider(
              value: _plates,
              min: 0.5,
              max: 4,
              divisions: 7,
              label: _plates.toStringAsFixed(1),
              onChanged: (v) => setState(() => _plates = v),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        if (n != null) _bigRow(scheme, n, _plates),
        const SizedBox(height: 12),
        if (n != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.restaurant, size: 18),
              label: Text(tr('سجّلها كوجبة النهاردة', 'Log as a meal today')),
              onPressed: () async {
                final ok = await logAsMeal(context,
                    name: widget.dish.name,
                    grams: widget.dish.servingGrams * _plates,
                    kcal: n.kcal * _plates,
                    protein: n.protein * _plates,
                    carbs: n.carbs * _plates,
                    fat: n.fat * _plates);
                if (ok && context.mounted) Navigator.pop(context);
              },
            ),
          ),
        const SizedBox(height: 18),
        Text(tr('المكوّنات (لطبق واحد)', 'Ingredients (one plate)'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final p in _parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text(p.name)),
                Text('${arNum(p.grams.round())} ${tr('جم', 'g')}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.info_outline, size: 14, color: scheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tr('السعرات **محسوبة** بجمع مكوّنات الطبق بأرقام USDA — مش مكتوبة بالإيد. الأوزان تقديرية لطبق نموذجى وممكن تختلف حسب طريقة تحضيرك.',
                  'Calories are **computed** by summing the plate ingredients using USDA numbers — not hand-typed. Weights are estimates for a typical plate and vary by your recipe.'),
              style: TextStyle(fontSize: 10.5, color: scheme.outline),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _bigRow(ColorScheme scheme, UsdaNutrients n, double m) => Row(
        children: [
          _box(scheme, tr('سعرات', 'Calories'), n.kcal * m, '', scheme.primary),
          _box(scheme, tr('بروتين', 'Protein'), n.protein * m, tr('جم', 'g'),
              Colors.blue),
          _box(scheme, tr('كارب', 'Carbs'), n.carbs * m, tr('جم', 'g'),
              Colors.orange),
          _box(scheme, tr('دهون', 'Fat'), n.fat * m, tr('جم', 'g'),
              Colors.redAccent),
        ],
      );

  Widget _box(ColorScheme scheme, String label, double v, String unit, Color c) =>
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
}

/// يسجّل الأكلة كوجبة النهاردة — بيسأل عن الوجبة (فطار/غدا/عشا/سناك) وبيحفظ
/// القيم المحسوبة. مشترك بين كارت الصنف وكارت الطبق.
Future<bool> logAsMeal(
  BuildContext context, {
  required String name,
  required double grams,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
}) async {
  final slot = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(tr('سجّلها فى أنهى وجبة؟', 'Log to which meal?'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          for (final s in kMealSlots)
            ListTile(
              leading: Text(
                switch (s) {
                  'فطار' => '🌅',
                  'غدا' => '🍽',
                  'عشا' => '🌙',
                  _ => '🍎',
                },
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(mealSlotLabel(s)),
              onTap: () => Navigator.pop(ctx, s),
            ),
        ],
      ),
    ),
  );
  if (slot == null) return false;
  await MealsRepo().add(Meal(
    day: dayKey(DateTime.now()),
    slot: slot,
    description: name,
    calories: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    grams: grams,
  ));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتسجّلت فى ${mealSlotLabel(slot)} ✓',
            'Logged to ${mealSlotLabel(slot)} ✓'))));
  }
  return true;
}
