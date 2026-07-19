import '../core/db.dart';

/// قاعدة يصنعها المستخدم: «لو [metric] [op] [threshold] ← نبّهنى بـ[message]».
class CustomRule {
  final int? id;
  final String metric;
  final String op; // '>' أو '<'
  final double threshold;
  final String message;
  final bool enabled;

  const CustomRule({
    this.id,
    required this.metric,
    required this.op,
    required this.threshold,
    required this.message,
    this.enabled = true,
  });

  factory CustomRule.fromMap(Map<String, Object?> m) => CustomRule(
        id: m['id'] as int?,
        metric: (m['metric'] as String?) ?? '',
        op: (m['op'] as String?) ?? '>',
        threshold: ((m['threshold'] as num?) ?? 0).toDouble(),
        message: (m['message'] as String?) ?? '',
        enabled: ((m['enabled'] as int?) ?? 1) == 1,
      );

  Map<String, Object?> toMap() => {
        'metric': metric,
        'op': op,
        'threshold': threshold,
        'message': message,
        'enabled': enabled ? 1 : 0,
      };
}

class RulesRepo {
  Future<int> add(CustomRule r) async {
    final db = await AppDb.instance;
    final map = r.toMap()..['created_at'] = DateTime.now().toIso8601String();
    return db.insert('custom_rules', map);
  }

  Future<List<CustomRule>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('custom_rules', orderBy: 'id DESC');
    return rows.map(CustomRule.fromMap).toList();
  }

  Future<void> update(CustomRule r) async {
    if (r.id == null) return;
    final db = await AppDb.instance;
    await db.update('custom_rules', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> setEnabled(int id, bool on) async {
    final db = await AppDb.instance;
    await db.update('custom_rules', {'enabled': on ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('custom_rules', where: 'id = ?', whereArgs: [id]);
  }
}
