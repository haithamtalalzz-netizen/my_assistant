import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/meals_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';

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

  @override
  void initState() {
    super.initState();
    _initSlots();
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
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

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
