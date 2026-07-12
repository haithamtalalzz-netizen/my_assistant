import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';

/// حاسبة زكاة المال — نصاب الذهب 85 جم، والزكاة 2.5% لو بلغ المال النصاب وحال عليه الحول.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _cash = TextEditingController();
  final _gold = TextEditingController();
  final _silver = TextEditingController();
  final _trade = TextEditingController();
  final _debts = TextEditingController();
  final _goldGram = TextEditingController();

  double _n(TextEditingController c) => parseNumber(c.text) ?? 0;

  @override
  void dispose() {
    for (final c in [_cash, _gold, _silver, _trade, _debts, _goldGram]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _n(_cash) + _n(_gold) + _n(_silver) + _n(_trade) - _n(_debts);
    final gramPrice = _n(_goldGram);
    final nisab = gramPrice > 0 ? gramPrice * 85 : 0;
    final due = nisab > 0 && total >= nisab;
    final zakat = due ? total * 0.025 : 0;

    return Scaffold(
      appBar: AppBar(title: Text(tr('حاسبة الزكاة', 'Zakat calculator'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_cash, tr('النقود (كاش + بنك)', 'Cash (+ bank)')),
          _field(_gold, tr('قيمة الذهب', 'Gold value')),
          _field(_silver, tr('قيمة الفضة', 'Silver value')),
          _field(_trade, tr('عروض التجارة', 'Trade goods value')),
          _field(_debts, tr('يُطرح: ديون عليك', 'Minus: debts you owe')),
          const Divider(height: 28),
          _field(_goldGram, tr('سعر جرام الذهب (للنصاب)', 'Gold gram price (for nisab)')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (due ? scheme.primary : scheme.surfaceContainerHighest)
                  .withValues(alpha: due ? 1 : 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('إجمالى المال الزكوى', 'Zakatable wealth'),
                  style: TextStyle(
                      color: due
                          ? scheme.onPrimary.withValues(alpha: 0.9)
                          : scheme.onSurfaceVariant),
                ),
                Text(egp(total),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: due ? scheme.onPrimary : scheme.onSurface)),
                const SizedBox(height: 10),
                if (nisab > 0)
                  Text(
                    tr('النصاب (85 جم ذهب): ${egp(nisab.toDouble())}',
                        'Nisab (85g gold): ${egp(nisab.toDouble())}'),
                    style: TextStyle(
                        color: due
                            ? scheme.onPrimary.withValues(alpha: 0.9)
                            : scheme.onSurfaceVariant,
                        fontSize: 12),
                  ),
                const SizedBox(height: 12),
                Text(
                  due
                      ? tr('الزكاة المستحقة (2.5%)', 'Zakat due (2.5%)')
                      : tr('لم يبلغ النصاب — لا زكاة', 'Below nisab — no zakat'),
                  style: TextStyle(
                      color: due
                          ? scheme.onPrimary.withValues(alpha: 0.9)
                          : scheme.onSurfaceVariant),
                ),
                if (due)
                  Text(egp(zakat.toDouble()),
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: scheme.onPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('* الزكاة تجب بعد بلوغ النصاب وحولان الحول (مرور سنة هجرية).',
                '* Zakat is due after reaching nisab and a full lunar year passes.'),
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, filled: true),
          onChanged: (_) => setState(() {}),
        ),
      );
}
