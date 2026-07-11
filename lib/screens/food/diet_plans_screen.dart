import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/diet_plans.dart';
import '../../core/l10n.dart';
import '../../data/measurements_repo.dart';
import '../../data/settings_repo.dart';
import '../../widgets/search_action.dart';

/// شاشة الأنظمة الغذائية — يختار المستخدم نظام يتفعّل ويظبط هدف السعرات والماكروز.
class DietPlansScreen extends StatefulWidget {
  const DietPlansScreen({super.key});

  @override
  State<DietPlansScreen> createState() => _DietPlansScreenState();
}

class _DietPlansScreenState extends State<DietPlansScreen> {
  final _settings = SettingsRepo();
  double? _weight;
  String _active = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await _settings.activeDietPlan();
    final weights = await MeasurementsRepo().recent(type: 'وزن', limit: 1);
    if (!mounted) return;
    setState(() {
      _active = active;
      _weight = weights.isNotEmpty ? weights.first.value : null;
      _loading = false;
    });
  }

  Future<void> _activate(DietPlan p, int calories) async {
    final macros = p.targetMacros(calories);
    await _settings.setActiveDietPlan(p.id);
    await _settings.setCalorieGoal(calories);
    await _settings.setMacroTargets(
        macros.protein.round(), macros.carbs.round(), macros.fat.round());
    if (!mounted) return;
    setState(() => _active = p.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتفعّل نظام «${p.name}» — هدف ${arNum(calories)} سعرة',
            'Activated "${p.name}" — ${arNum(calories)} kcal goal'))));
    Navigator.pop(context, true);
  }

  Future<void> _deactivate() async {
    await _settings.setActiveDietPlan('');
    await _settings.setMacroTargets(0, 0, 0);
    if (!mounted) return;
    setState(() => _active = '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('اتلغى النظام الغذائي', 'Diet plan cleared'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('الأنظمة الغذائية', 'Diet plans')),
        actions: [searchAction(context)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                if (_active.isNotEmpty)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle),
                      title: Text(tr('نظامك الحالي', 'Your current plan')),
                      subtitle: Text(dietPlanById(_active)?.name ?? _active),
                      trailing: TextButton(
                          onPressed: _deactivate,
                          child: Text(tr('إلغاء', 'Clear'))),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                  child: Text(
                      _weight != null
                          ? tr('محسوبة على وزنك ${arNum(_weight!.round())} كجم',
                              'Based on your weight ${arNum(_weight!.round())} kg')
                          : tr('سجّل وزنك في «التقدم البدني» عشان الحساب يبقى أدق',
                              'Log your weight in Body progress for a more accurate estimate'),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline)),
                ),
                for (final p in kDietPlans) _planCard(p),
              ],
            ),
    );
  }

  Widget _planCard(DietPlan p) {
    final scheme = Theme.of(context).colorScheme;
    final cals = p.targetCalories(_weight);
    final isActive = _active == p.id;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(p, cals),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(dietGoalEmoji(p.goal), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  Text('${arNum(cals)} ${tr('سعرة', 'kcal')}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(p.desc,
                  style: TextStyle(fontSize: 12.5, color: scheme.outline)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _macroPill(tr('بروتين', 'P'), p.proteinPct, Colors.red),
                  _macroPill(tr('كارب', 'C'), p.carbsPct, Colors.orange),
                  _macroPill(tr('دهون', 'F'), p.fatPct, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroPill(String label, int pct, Color color) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('$label $pct%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );

  void _showDetail(DietPlan p, int cals) {
    final macros = p.targetMacros(cals);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Text(dietGoalEmoji(p.goal), style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${dietGoalLabel(p.goal)} • ${arNum(cals)} ${tr('سعرة/يوم', 'kcal/day')}',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 12),
            Text(p.desc, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            Text(tr('الماكروز المستهدفة', 'Target macros'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroBox(tr('بروتين', 'Protein'),
                    '${macros.protein.round()}${tr('جم', 'g')}', Colors.red),
                _macroBox(tr('كارب', 'Carbs'),
                    '${macros.carbs.round()}${tr('جم', 'g')}', Colors.orange),
                _macroBox(tr('دهون', 'Fat'),
                    '${macros.fat.round()}${tr('جم', 'g')}', Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('نموذج يوم', 'Sample day'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (final line in p.sampleDay)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            if (p.fasting) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        tr('نافذة أكل ٨ ساعات + صيام ١٦ ساعة',
                            '8-hour eating window + 16-hour fast'),
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _activate(p, cals),
              icon: const Icon(Icons.check),
              label: Text(_active == p.id
                  ? tr('النظام مفعّل — تحديث الأهداف', 'Active — update targets')
                  : tr('فعّل النظام ده', 'Activate this plan')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroBox(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
