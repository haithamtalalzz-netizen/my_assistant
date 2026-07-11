import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// شاشة «خصّص الأزرار السريعة» — المستخدم يفعّل/يقفل الأزرار ويرتّبها بالسحب.
/// بترجّع قائمة مفاتيح الأزرار المفعّلة بالترتيب (أو null لو اتلغى).
class QuickActionsSettingsScreen extends StatefulWidget {
  /// كل الأزرار المتاحة (مفتاح + أيقونة + اسم).
  final List<({String key, IconData icon, String label})> all;

  /// المفعّل حاليًا بالترتيب.
  final List<String> enabledOrder;

  const QuickActionsSettingsScreen({
    super.key,
    required this.all,
    required this.enabledOrder,
  });

  @override
  State<QuickActionsSettingsScreen> createState() =>
      _QuickActionsSettingsScreenState();
}

class _Row {
  final String key;
  final IconData icon;
  final String label;
  bool enabled;

  _Row(this.key, this.icon, this.label, this.enabled);
}

class _QuickActionsSettingsScreenState
    extends State<QuickActionsSettingsScreen> {
  late final List<_Row> _rows;

  @override
  void initState() {
    super.initState();
    final byKey = {for (final a in widget.all) a.key: a};
    final rows = <_Row>[];
    final seen = <String>{};
    // المفعّل أول (بالترتيب المحفوظ).
    for (final k in widget.enabledOrder) {
      final a = byKey[k];
      if (a != null && seen.add(k)) rows.add(_Row(a.key, a.icon, a.label, true));
    }
    // الباقي (مقفول) في الآخر.
    for (final a in widget.all) {
      if (seen.add(a.key)) rows.add(_Row(a.key, a.icon, a.label, false));
    }
    _rows = rows;
  }

  void _save() {
    Navigator.pop(context, [for (final r in _rows) if (r.enabled) r.key]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('خصّص الأزرار السريعة', 'Customize quick actions')),
        actions: [
          IconButton(
            tooltip: tr('حفظ', 'Save'),
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              tr('فعّل اللي عايزه واسحب لإعادة الترتيب. اللي فوق بيظهر الأول.',
                  'Toggle what you want and drag to reorder. Top items show first.'),
              style: TextStyle(color: scheme.outline),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
              itemCount: _rows.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final r = _rows.removeAt(oldIndex);
                  _rows.insert(newIndex, r);
                });
              },
              itemBuilder: (context, i) {
                final r = _rows[i];
                return Padding(
                  key: ValueKey(r.key),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: CheckboxListTile(
                    value: r.enabled,
                    onChanged: (v) => setState(() => r.enabled = v ?? false),
                    secondary: Icon(r.icon,
                        color: r.enabled ? scheme.primary : scheme.outline),
                    title: Text(r.label),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
