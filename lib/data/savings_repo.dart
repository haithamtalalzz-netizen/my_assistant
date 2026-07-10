import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

class SavingsRepo {
  Future<int> addGoal(SavingsGoal g) async {
    final db = await AppDb.instance;
    return db.insert('savings_goals', g.toMap());
  }

  Future<void> updateGoal(SavingsGoal g) async {
    final db = await AppDb.instance;
    await db.update('savings_goals', g.toMap(),
        where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await AppDb.instance;
    await db
        .delete('savings_contributions', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addContribution(int goalId, double amount) async {
    final db = await AppDb.instance;
    await db.insert('savings_contributions', {
      'goal_id': goalId,
      'amount': amount,
      'day': dayKey(DateTime.now()),
    });
  }

  /// كل الأهداف مع المدفوع محسوب (LEFT JOIN على المساهمات).
  Future<List<SavingsGoal>> all() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery('''
      SELECT g.*, COALESCE(
        (SELECT SUM(amount) FROM savings_contributions c WHERE c.goal_id = g.id), 0
      ) AS saved
      FROM savings_goals g
      ORDER BY g.id DESC
    ''');
    return rows.map(SavingsGoal.fromMap).toList();
  }

  /// متوسط الادخار الشهري لهدف — من مساهماته (0 لو مفيش كفاية).
  Future<double> monthlyRate(int goalId) async {
    final db = await AppDb.instance;
    final rows = await db.query('savings_contributions',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'day');
    if (rows.isEmpty) return 0;
    var total = 0.0;
    for (final r in rows) {
      total += (r['amount'] as num).toDouble();
    }
    final first = DateTime.tryParse(rows.first['day'] as String);
    if (first == null) return 0;
    final months = (DateTime.now().difference(first).inDays / 30).ceil();
    return months < 1 ? total : total / months;
  }

  /// عدد الشهور المتوقعة للوصول للهدف بالمعدل الحالي (null لو مش محسوب).
  Future<int?> monthsToGoal(SavingsGoal g) async {
    if (g.remaining <= 0) return 0;
    final rate = await monthlyRate(g.id!);
    if (rate <= 0) return null;
    return (g.remaining / rate).ceil();
  }
}
