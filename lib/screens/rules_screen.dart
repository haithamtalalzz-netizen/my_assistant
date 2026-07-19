import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/custom_rules.dart';
import '../core/l10n.dart';
import '../data/rules_repo.dart';
import '../widgets/common.dart';

/// «قواعدى» — قواعد يصنعها المستخدم («لو مصاريف الأسبوع عدّت X نبّهنى»)،
/// وبتبيّن أنهى قاعدة بتتحقق دلوقتى من بياناتك الحالية.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final _repo = RulesRepo();
  bool _loading = true;
  List<CustomRule> _rules = [];
  Map<String, double> _values = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _rules = await _repo.all();
    _values = await metricValues();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool _firing(CustomRule r) =>
      r.enabled && ruleFires(r.op, _values[r.metric] ?? 0, r.threshold);

  Future<void> _edit([CustomRule? rule]) async {
    var metric = rule?.metric ?? kRuleMetricKeys.first;
    var op = rule?.op ?? '>';
    final thrC = TextEditingController(
        text: rule != null ? rule.threshold.toStringAsFixed(0) : '');
    final msgC = TextEditingController(text: rule?.message ?? '');
    final result = await showDialog<CustomRule>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(rule == null ? tr('قاعدة جديدة', 'New rule') : tr('تعديل', 'Edit')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: metric,
                decoration: InputDecoration(labelText: tr('لو', 'When')),
                items: [
                  for (final k in kRuleMetricKeys)
                    DropdownMenuItem(value: k, child: Text(ruleMetricLabel(k))),
                ],
                onChanged: (v) => setD(() => metric = v ?? metric),
              ),
              const SizedBox(height: 10),
              Row(children: [
                ChoiceChip(
                  label: Text(tr('أكبر من', 'Above')),
                  selected: op == '>',
                  onSelected: (_) => setD(() => op = '>'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(tr('أصغر من', 'Below')),
                  selected: op == '<',
                  onSelected: (_) => setD(() => op = '<'),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: thrC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: tr('الحد', 'Threshold'),
                    suffixText: ruleMetricUnit(metric)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: msgC,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: tr('رسالة التنبيه', 'Alert message')),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
              onPressed: () {
                final thr =
                    double.tryParse(toEnglishDigits(thrC.text.trim())) ?? 0;
                Navigator.pop(
                    ctx,
                    CustomRule(
                        id: rule?.id,
                        metric: metric,
                        op: op,
                        threshold: thr,
                        message: msgC.text.trim(),
                        enabled: rule?.enabled ?? true));
              },
              child: Text(tr('حفظ', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      if (result.id == null) {
        await _repo.add(result);
      } else {
        await _repo.update(result);
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firing = _rules.where(_firing).length;
    return Scaffold(
      appBar: AppBar(title: Text(tr('قواعدى', 'My rules'))),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: Text(tr('قاعدة جديدة', 'New rule')),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_rules.isEmpty
              ? EmptyHint(
                  icon: Icons.rule_folder_outlined,
                  text: tr(
                      'اصنع قواعدك بنفسك — زى «لو مصاريف الأسبوع عدّت ٥٠٠ نبّهنى» — وهنبيّنلك اللى بتتحقق دلوقتى.',
                      'Make your own rules — like "if weekly spend tops 500, alert me" — and we\'ll flag which are active now.'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  children: [
                    if (firing > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC2E2E).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⚠ ${tr('$firing قاعدة بتتحقق دلوقتى', '$firing rule(s) active now')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB00020)),
                        ),
                      ),
                    for (final r in _rules) _ruleCard(scheme, r),
                  ],
                )),
    );
  }

  Widget _ruleCard(ColorScheme scheme, CustomRule r) {
    final fires = _firing(r);
    final val = _values[r.metric] ?? 0;
    final opTxt = r.op == '<' ? tr('أصغر من', 'below') : tr('أكبر من', 'above');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: fires
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFB00020), width: 1.2))
          : null,
      child: ListTile(
        leading: Icon(fires ? Icons.warning_amber : Icons.rule,
            color: fires ? const Color(0xFFB00020) : scheme.primary),
        title: Text(
            '${ruleMetricLabel(r.metric)} $opTxt ${arNum(r.threshold.round())} ${ruleMetricUnit(r.metric)}'),
        subtitle: Text([
          if (r.message.isNotEmpty) r.message,
          '${tr('الحالى', 'Now')}: ${arNum(val.round())}',
        ].join(' • ')),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Switch(
            value: r.enabled,
            onChanged: (v) async {
              if (r.id != null) await _repo.setEnabled(r.id!, v);
              await _load();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (s) async {
              if (s == 'edit') {
                await _edit(r);
              } else if (s == 'del' && r.id != null) {
                await _repo.delete(r.id!);
                await _load();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
              PopupMenuItem(value: 'del', child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ]),
      ),
    );
  }
}
