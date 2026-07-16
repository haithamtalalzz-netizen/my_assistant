import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/meals_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import 'food_picker_sheet.dart';

/// تسجيل وجبة سريع: نوع الوجبة + وصف سطر واحد + سعرات اختياري.
Future<bool?> showMealSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
      child: const _MealForm(),
    ),
  );
}

class _MealForm extends StatefulWidget {
  const _MealForm();

  @override
  State<_MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<_MealForm> {
  final _description = TextEditingController();
  final _calories = TextEditingController();
  List<String> _slots = kMealSlots;
  String _slot = kMealSlots.first;

  // ماكروز محسوبة من قاعدة الأكل (لو المستخدم اختار صنف).
  double? _protein;
  double? _carbs;
  double? _fat;
  double? _grams;

  @override
  void initState() {
    super.initState();
    _initSlots();
    _loadFrequent();
  }

  List<Meal> _frequent = [];
  Meal? _last;

  Future<void> _loadFrequent() async {
    final f = await MealsRepo().frequentMeals(limit: 6);
    final last = await MealsRepo().lastMeal();
    if (mounted) {
      setState(() {
        _frequent = f;
        _last = last;
      });
    }
  }

  /// بيملى الفورم من وجبة سابقة (مفضّلة أو آخر وجبة) — بقيمها زى ما هى.
  void _fillFrom(Meal m) {
    setState(() {
      _description.text = m.description;
      _calories.text = m.calories == null ? '' : m.calories!.round().toString();
      _protein = m.protein;
      _carbs = m.carbs;
      _fat = m.fat;
      _grams = m.grams;
    });
  }

  Future<void> _initSlots() async {
    final ramadan = await SettingsRepo().ramadanMode();
    if (!mounted) return;
    setState(() {
      _slots = ramadan ? kRamadanMealSlots : kMealSlots;
      _slot = _defaultSlot(ramadan);
    });
  }

  String _defaultSlot(bool ramadan) {
    final h = DateTime.now().hour;
    if (ramadan) return h < 12 ? 'سحور' : 'فطار';
    if (h < 12) return 'فطار';
    if (h < 17) return 'غدا';
    return 'عشا';
  }

  @override
  void dispose() {
    _description.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final desc = _description.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اكتب أكلت إيه الأول', 'Write what you ate first'))));
      return;
    }
    await MealsRepo().add(Meal(
      day: dayKey(DateTime.now()),
      slot: _slot,
      description: desc,
      calories: parseNumber(_calories.text),
      protein: _protein,
      carbs: _carbs,
      fat: _fat,
      grams: _grams,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickFromDb() async {
    final picked = await pickFood(context);
    if (picked == null || !mounted) return;
    setState(() {
      final qty = '${picked.grams.round()}${picked.unit} ';
      _description.text = '$qty${picked.name}';
      _calories.text = picked.n.kcal.round().toString();
      _protein = picked.n.protein;
      _carbs = picked.n.carbs;
      _fat = picked.n.fat;
      _grams = picked.grams;
    });
  }

  void _clearMacros() {
    setState(() {
      _protein = null;
      _carbs = null;
      _fat = null;
      _grams = null;
    });
  }

  Widget _macroChip(String label, double? value, Color color) => Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        label: Text('$label ${(value ?? 0).round()}${tr('جم', 'g')}',
            style: TextStyle(fontSize: 12, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('سجل وجبة', 'Log meal'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final s in _slots)
                ChoiceChip(
                  label: Text(mealSlotLabel(s)),
                  selected: _slot == s,
                  onSelected: (_) => setState(() => _slot = s),
                ),
            ],
          ),
          // المفضّلة: الأكتر تسجيلاً + «سجّل تانى» — بيملّوا الفورم بضغطة.
          if (_frequent.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_last != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        avatar: const Icon(Icons.replay, size: 15),
                        label: Text(tr('سجّل تانى', 'Log again')),
                        onPressed: () => _fillFrom(_last!),
                      ),
                    ),
                  for (final m in _frequent)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        avatar: const Text('⭐', style: TextStyle(fontSize: 12)),
                        label: Text(
                            m.description.length > 22
                                ? '${m.description.substring(0, 22)}…'
                                : m.description,
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () => _fillFrom(m),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromDb,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(tr('اختر من قاعدة الأكل (بالسعرات والماكروز)',
                  'Pick from food database (calories & macros)')),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            autofocus: true,
            decoration: InputDecoration(
                labelText:
                    tr('أكلت إيه؟ (سطر واحد كفاية)', 'What did you eat? (one line)')),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText:
                    tr('سعرات تقريبية (اختياري)', 'Approx. calories (optional)')),
          ),
          if (_protein != null || _carbs != null || _fat != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _macroChip(tr('بروتين', 'P'), _protein, Colors.red),
                      _macroChip(tr('كارب', 'C'), _carbs, Colors.orange),
                      _macroChip(tr('دهون', 'F'), _fat, Colors.blue),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tr('مسح الماكروز', 'Clear macros'),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearMacros,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ),
        ],
      ),
    );
  }
}
