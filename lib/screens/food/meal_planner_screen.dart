import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/meal_plan_repo.dart';
import '../../data/meals_repo.dart';

/// مخطّط الوجبات الأسبوعى — تكتب وجبة لكل يوم/خانة، وتقدر تضيف الكل لقائمة التسوق.
class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

// الأسبوع بيبدأ سبت فى مصر → ترتيب أيام Dart (السبت=6).
const _weekOrder = [6, 7, 1, 2, 3, 4, 5];
const _weekNames = {
  6: 'السبت',
  7: 'الأحد',
  1: 'الإثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
};
const _weekNamesEn = {
  6: 'Sat',
  7: 'Sun',
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
};

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final _repo = MealPlanRepo();
  bool _loading = true;
  Map<String, String> _plan = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await _repo.weekMap();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('مخطّط الوجبات', 'Meal planner')),
        actions: [
          IconButton(
            tooltip: tr('أضف الكل لقائمة التسوق', 'Add all to shopping list'),
            icon: const Icon(Icons.add_shopping_cart_outlined),
            onPressed: _addAllToShopping,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              children: [
                for (final wd in _weekOrder) _dayCard(wd, scheme),
              ],
            ),
    );
  }

  Widget _dayCard(int weekday, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(_weekNames[weekday]!, _weekNamesEn[weekday]!),
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: scheme.primary)),
            const SizedBox(height: 4),
            for (final slot in kMealSlots)
              InkWell(
                onTap: () => _edit(weekday, slot),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 54,
                          child: Text(mealSlotLabel(slot),
                              style: TextStyle(
                                  fontSize: 12, color: scheme.outline))),
                      Expanded(
                        child: Text(
                            _plan['$weekday|$slot'] ?? '',
                            style: TextStyle(
                                color: (_plan['$weekday|$slot'] ?? '').isEmpty
                                    ? scheme.outlineVariant
                                    : null)),
                      ),
                      Icon(Icons.edit_outlined,
                          size: 15, color: scheme.outlineVariant),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(int weekday, String slot) async {
    final ctrl =
        TextEditingController(text: _plan['$weekday|$slot'] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${tr(_weekNames[weekday]!, _weekNamesEn[weekday]!)} — ${mealSlotLabel(slot)}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('الوجبة…', 'Meal…')),
        ),
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
    if (saved == true) {
      await _repo.setItem(weekday, slot, ctrl.text);
      await _load();
    }
    ctrl.dispose();
  }

  Future<void> _addAllToShopping() async {
    final texts = await _repo.allTexts();
    if (texts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('الخطة فاضية', 'Plan is empty'))));
      }
      return;
    }
    final meals = MealsRepo();
    for (final t in texts) {
      await meals.addShoppingItem(t);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اتضافوا لقائمة التسوق ✓', 'Added to shopping list ✓'))));
    }
  }
}
