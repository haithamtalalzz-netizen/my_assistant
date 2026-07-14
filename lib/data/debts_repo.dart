import '../core/db.dart';
import '../models/models.dart';

class DebtsRepo {
  Future<List<Debt>> all({bool includeSettled = false}) async {
    final db = await AppDb.instance;
    final rows = await db.query('debts',
        where: includeSettled ? null : 'settled = 0',
        orderBy: 'settled, id DESC');
    return rows.map(Debt.fromMap).toList();
  }

  Future<int> add(Debt debt) async {
    final db = await AppDb.instance;
    return db.insert('debts', debt.toMap());
  }

  Future<void> setSettled(int id, bool settled) async {
    final db = await AppDb.instance;
    await db.update('debts', {'settled': settled ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  /// خطة سداد بطريقة «كرة الثلج»: الديون اللى عليك (direction='عليا') مرتّبة
  /// من الأصغر للأكبر — تقفل الصغيّر الأول عشان تكسب دفعة معنوية وتقلّل العدد.
  Future<List<Debt>> payoffPlan() async {
    final list = await all();
    final iOwe = [for (final d in list) if (d.direction == 'عليا') d];
    iOwe.sort((a, b) => a.amount.compareTo(b.amount));
    return iOwe;
  }

  /// صافي الوضع: (اللي ليك) − (اللي عليك) من الديون المفتوحة.
  Future<(double owedToMe, double iOwe)> totals() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT direction, COALESCE(SUM(amount), 0) AS total '
        'FROM debts WHERE settled = 0 GROUP BY direction');
    var owedToMe = 0.0, iOwe = 0.0;
    for (final r in rows) {
      final v = (r['total'] as num).toDouble();
      if (r['direction'] == 'لى') {
        owedToMe = v;
      } else {
        iOwe = v;
      }
    }
    return (owedToMe, iOwe);
  }
}
