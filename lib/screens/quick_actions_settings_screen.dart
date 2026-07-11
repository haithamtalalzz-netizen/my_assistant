import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// الترتيب/التفعيل الافتراضي لأزرار الإضافة السريعة (مصدر واحد يستخدمه كل حاجة).
const List<String> kDefaultQuickActions = [
  'water', 'dose', 'workout', 'sleep', 'steps', 'habit', 'meal', 'expense',
  'income', 'transfer', 'bill_paid', 'debt', 'measure', 'reminder', 'shopping',
  'doc', 'voice', 'manager', 'appointment', 'calendar', 'pharmacy',
];

/// كتالوج كل الأزرار المتاحة (مفتاح + أيقونة + اسم + لون) — بلا معالجات؛
/// شاشة اليوم بتربط المعالجات بالمفاتيح، والإعدادات/التخصيص بيستخدموه كمان.
List<({String key, IconData icon, String label, Color color})>
    quickActionCatalog() => [
      (key: 'water', icon: Icons.water_drop_outlined, label: tr('مياه', 'Water'), color: Colors.lightBlue),
      (key: 'dose', icon: Icons.medication_outlined, label: tr('جرعة دوا', 'Dose'), color: Colors.pink),
      (key: 'workout', icon: Icons.fitness_center, label: tr('تمرين', 'Workout'), color: Colors.green),
      (key: 'sleep', icon: Icons.bedtime_outlined, label: tr('نوم', 'Sleep'), color: Colors.indigo),
      (key: 'steps', icon: Icons.directions_walk, label: tr('خطوات', 'Steps'), color: Colors.brown),
      (key: 'habit', icon: Icons.task_alt, label: tr('عادة', 'Habit'), color: Colors.lightGreen),
      (key: 'meal', icon: Icons.restaurant_outlined, label: tr('وجبة', 'Meal'), color: Colors.orange),
      (key: 'expense', icon: Icons.account_balance_wallet_outlined, label: tr('مصروف', 'Expense'), color: Colors.redAccent),
      (key: 'income', icon: Icons.south_west, label: tr('دخل', 'Income'), color: Colors.teal),
      (key: 'transfer', icon: Icons.swap_horiz, label: tr('تحويل', 'Transfer'), color: Colors.blueGrey),
      (key: 'bill_paid', icon: Icons.receipt_long_outlined, label: tr('فاتورة اتدفعت', 'Bill paid'), color: Colors.deepOrange),
      (key: 'debt', icon: Icons.handshake_outlined, label: tr('دَين', 'Debt'), color: Color(0xFFFF6F00)),
      (key: 'measure', icon: Icons.monitor_heart_outlined, label: tr('قياس', 'Measure'), color: Colors.red),
      (key: 'reminder', icon: Icons.push_pin_outlined, label: tr('تذكير', 'Reminder'), color: Color(0xFFFF8F00)),
      (key: 'shopping', icon: Icons.add_shopping_cart_outlined, label: tr('مشتريات', 'Shopping'), color: Color(0xFF9E9D24)),
      (key: 'doc', icon: Icons.photo_camera_outlined, label: tr('صورة مستند', 'Doc photo'), color: Color(0xFF455A64)),
      (key: 'voice', icon: Icons.mic_none, label: tr('بصوتك', 'Voice'), color: Colors.blueAccent),
      (key: 'manager', icon: Icons.psychology_outlined, label: tr('اسأل مديرك', 'Manager'), color: Colors.deepPurple),
      (key: 'appointment', icon: Icons.event_available_outlined, label: tr('موعد', 'Appointment'), color: Colors.blue),
      (key: 'calendar', icon: Icons.calendar_month_outlined, label: tr('التقويم', 'Calendar'), color: Colors.cyan),
      (key: 'pharmacy', icon: Icons.local_pharmacy_outlined, label: tr('الصيدلية', 'Pharmacy'), color: Colors.purple),
    ];

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
  late List<_Row> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _build(widget.enabledOrder);
  }

  List<_Row> _build(List<String> order) {
    final byKey = {for (final a in widget.all) a.key: a};
    final rows = <_Row>[];
    final seen = <String>{};
    for (final k in order) {
      final a = byKey[k];
      if (a != null && seen.add(k)) rows.add(_Row(a.key, a.icon, a.label, true));
    }
    for (final a in widget.all) {
      if (seen.add(a.key)) rows.add(_Row(a.key, a.icon, a.label, false));
    }
    return rows;
  }

  void _save() {
    Navigator.pop(context, [for (final r in _rows) if (r.enabled) r.key]);
  }

  void _reset() => setState(() => _rows = _build(kDefaultQuickActions));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('خصّص الأزرار السريعة', 'Customize quick actions')),
        actions: [
          IconButton(
            tooltip: tr('استرجاع الافتراضي', 'Reset to default'),
            icon: const Icon(Icons.restore),
            onPressed: _reset,
          ),
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
