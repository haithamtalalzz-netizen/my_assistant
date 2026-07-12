import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/mawarith.dart';

/// حاسبة المواريث — الحالات الشائعة.
class MawarithScreen extends StatefulWidget {
  const MawarithScreen({super.key});

  @override
  State<MawarithScreen> createState() => _MawarithScreenState();
}

class _MawarithScreenState extends State<MawarithScreen> {
  final _estate = TextEditingController();
  String _spouse = 'none';
  int _wives = 1, _sons = 0, _daughters = 0, _brothers = 0, _sisters = 0;
  bool _father = false, _mother = false;

  @override
  void dispose() {
    _estate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estate = parseNumber(_estate.text) ?? 0;
    final res = computeMawarith(MawarithInput(
      estate: estate,
      spouse: _spouse,
      wives: _wives,
      sons: _sons,
      daughters: _daughters,
      father: _father,
      mother: _mother,
      fullBrothers: _brothers,
      fullSisters: _sisters,
    ));

    return Scaffold(
      appBar: AppBar(title: Text(tr('حاسبة المواريث', 'Inheritance'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _estate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: tr('قيمة التركة', 'Estate value'), filled: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(tr('الزوجية', 'Spouse'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: [
              _choice(tr('لا يوجد', 'None'), 'none'),
              _choice(tr('زوج', 'Husband'), 'husband'),
              _choice(tr('زوجة', 'Wife'), 'wife'),
            ],
          ),
          if (_spouse == 'wife')
            _stepper(tr('عدد الزوجات', 'Wives'), _wives, 1, 4,
                (v) => setState(() => _wives = v)),
          const Divider(height: 24),
          _stepper(tr('الأبناء (ذكور)', 'Sons'), _sons, 0, 20,
              (v) => setState(() => _sons = v)),
          _stepper(tr('البنات', 'Daughters'), _daughters, 0, 20,
              (v) => setState(() => _daughters = v)),
          SwitchListTile(
            title: Text(tr('الأب', 'Father')),
            value: _father,
            onChanged: (v) => setState(() => _father = v),
          ),
          SwitchListTile(
            title: Text(tr('الأم', 'Mother')),
            value: _mother,
            onChanged: (v) => setState(() => _mother = v),
          ),
          _stepper(tr('إخوة أشقّاء', 'Full brothers'), _brothers, 0, 20,
              (v) => setState(() => _brothers = v)),
          _stepper(tr('أخوات شقيقات', 'Full sisters'), _sisters, 0, 20,
              (v) => setState(() => _sisters = v)),
          const SizedBox(height: 16),
          if (res.shares.isEmpty)
            Text(tr('أدخل التركة والورثة لعرض الأنصبة.',
                'Enter the estate and heirs to see shares.'))
          else ...[
            Text(tr('الأنصبة', 'Shares'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final h in res.shares)
              Card(
                child: ListTile(
                  title: Text(h.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${(h.fraction * 100).toStringAsFixed(1)}%'),
                  trailing: Text(egp(h.amount),
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: scheme.primary)),
                ),
              ),
            for (final n in res.notes)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $n',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr('تنبيه: تقدير مبدئى للحالات الشائعة فقط. المسائل المركّبة '
                  '(الجدّ/الجدّة/الحجب/الوصايا) تحتاج مختصًّا في الفرائض.',
                  'Note: an estimate for common cases only. Complex cases need a specialist.'),
              style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, String val) => ChoiceChip(
        label: Text(label),
        selected: _spouse == val,
        onSelected: (_) => setState(() => _spouse = val),
      );

  Widget _stepper(String label, int value, int min, int max,
          ValueChanged<int> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton.outlined(
              onPressed:
                  value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 18),
            ),
            SizedBox(
              width: 34,
              child: Text(arNum(value),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton.outlined(
              onPressed:
                  value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      );
}
