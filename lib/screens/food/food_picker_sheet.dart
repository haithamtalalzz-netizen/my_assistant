import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/food_db.dart';
import '../../core/l10n.dart';
import '../../core/usda_food_db.dart';
import 'barcode_scan_screen.dart';

/// نتيجة اختيار صنف من قاعدة الأكل: الاسم + الكمية + القيم الغذائية المحسوبة.
class PickedFood {
  final String name;
  final double grams;
  final String unit;
  final Nutrients n;
  const PickedFood(this.name, this.grams, this.unit, this.n);
}

/// شاشة بحث في قاعدة الأكل (مدمجة + إنترنت) → تختار صنف وتحدد الكمية.
Future<PickedFood?> pickFood(BuildContext context) {
  return showModalBottomSheet<PickedFood>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _FoodPickerSheet(),
  );
}

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet();

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;

  /// نتايج USDA — أرقام مرجعية (دى الأساس).
  List<FoodItem> _usda = [];
  bool _loadingUsda = false;

  /// الأكلات المصرية المدمجة — أرقام تقديرية (USDA ماعندهاش كشرى/طعمية).
  List<FoodItem> _offline = kFoods;
  List<FoodItem> _online = [];
  bool _loadingOnline = false;

  @override
  void initState() {
    super.initState();
    // نسخّن قاعدة USDA بدرى عشان أول بحث يطلع فورى.
    UsdaDb.all();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() {
      _offline = searchFoods(q);
      _online = [];
      if (q.trim().length < 2) _usda = [];
    });
    _debounce?.cancel();
    if (q.trim().length < 2) return;
    _searchUsda(q);
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchOnline(q));
  }

  Future<void> _searchUsda(String q) async {
    setState(() => _loadingUsda = true);
    final r = await UsdaDb.search(q, limit: 40);
    if (!mounted) return;
    setState(() {
      _usda = [for (final f in r) f.toFoodItem()];
      _loadingUsda = false;
    });
  }

  Future<void> _fetchOnline(String q) async {
    setState(() => _loadingOnline = true);
    final results = await searchOpenFoodFacts(q);
    if (!mounted) return;
    setState(() {
      _online = results;
      _loadingOnline = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: tr('امسح باركود', 'Scan barcode'),
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
                hintText: tr('دوّر على أكلة أو مشروب…', 'Search a food or drink…'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // نجمّع المدمج حسب التصنيف لو مفيش بحث، وإلا نعرض النتائج مسطّحة.
    final query = _search.text.trim();
    final showGrouped = query.length < 2;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ١) USDA الأول — دى الأرقام المرجعية.
        if (_loadingUsda)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        if (_usda.isNotEmpty) ...[
          _header(tr('أرقام رسمية (USDA)', 'Official (USDA)'), verified: true),
          for (final f in _usda) _foodTile(f),
        ],
        // ٢) الأكلات المصرية المدمجة — أرقامها تقديرية، وبنقول كده بصراحة.
        if (showGrouped)
          for (final g in kFoodGroups) ...[
            _header(g),
            for (final f in kFoods.where((x) => x.group == g)) _foodTile(f),
          ]
        else if (_offline.isNotEmpty) ...[
          _header(tr('أكلات مصرية (أرقام تقديرية)',
              'Egyptian dishes (estimated)')),
          for (final f in _offline) _foodTile(f),
        ],
        // ٣) الإنترنت (منتجات معلّبة بالباركود).
        if (_online.isNotEmpty) ...[
          _header(tr('منتجات من الإنترنت', 'Online products')),
          for (final f in _online) _foodTile(f),
        ],
        if (_loadingOnline)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
        if (!showGrouped &&
            _usda.isEmpty &&
            _offline.isEmpty &&
            _online.isEmpty &&
            !_loadingOnline &&
            !_loadingUsda)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                tr('مفيش نتيجة — جرّب اسم تاني أو سجّلها يدوي',
                    'No match — try another name or log it manually'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(String text, {bool verified = false}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(
          children: [
            if (verified) ...[
              Icon(Icons.verified,
                  size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      );

  Widget _foodTile(FoodItem f) {
    return ListTile(
      dense: true,
      title: Text(f.name),
      subtitle: Text(
        '${f.kcal.round()} ${tr('سعرة', 'kcal')} · '
        '${tr('بروتين', 'P')} ${f.protein.round()} · '
        '${tr('كارب', 'C')} ${f.carbs.round()} · '
        '${tr('دهون', 'F')} ${f.fat.round()}  '
        '(${tr('لكل', 'per')} 100${f.unit})',
        style: const TextStyle(fontSize: 11.5),
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => _pickQuantity(f),
    );
  }

  Future<void> _scanBarcode() async {
    final item = await scanBarcodeForFood(context);
    if (item != null && mounted) await _pickQuantity(item);
  }

  Future<void> _pickQuantity(FoodItem f) async {
    final picked = await showModalBottomSheet<PickedFood>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _QuantitySheet(f),
      ),
    );
    if (picked != null && mounted) Navigator.pop(context, picked);
  }
}

/// اختيار الكمية + معاينة القيم لحظيًا.
class _QuantitySheet extends StatefulWidget {
  final FoodItem food;
  const _QuantitySheet(this.food);

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final TextEditingController _qty =
      TextEditingController(text: widget.food.portion.round().toString());

  double get _grams => parseNumber(_qty.text) ?? 0;
  Nutrients get _n => widget.food.forQty(_grams);

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: tr('الكمية', 'Quantity'),
                    suffixText: f.unit,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              for (final preset in _presets(f))
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ActionChip(
                    label: Text('${preset.round()}'),
                    onPressed: () => setState(
                        () => _qty.text = preset.round().toString()),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macro(tr('سعرات', 'kcal'), _n.kcal.round().toString(), scheme.primary),
                _macro(tr('بروتين', 'Protein'), '${_n.protein.round()}${tr('جم', 'g')}', Colors.red),
                _macro(tr('كارب', 'Carbs'), '${_n.carbs.round()}${tr('جم', 'g')}', Colors.orange),
                _macro(tr('دهون', 'Fat'), '${_n.fat.round()}${tr('جم', 'g')}', Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _grams <= 0
                  ? null
                  : () => Navigator.pop(
                      context, PickedFood(f.name, _grams, f.unit, _n)),
              icon: const Icon(Icons.check),
              label: Text(tr('إضافة', 'Add')),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _presets(FoodItem f) {
    final base = f.portion;
    return [base * 0.5, base, base * 2].map((e) => e.roundToDouble()).toList();
  }

  Widget _macro(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: color)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}
