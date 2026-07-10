import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kExpenseCategories = [
  'أكل',
  'مواصلات',
  'فواتير',
  'صحة',
  'تسوق',
  'ترفيه',
  'أخرى',
];

/// عرض فئة المصروف بالإنجليزي مع إبقاء القيمة المخزّنة عربي.
String expenseCategoryLabel(String c) => switch (c) {
      'أكل' => tr('أكل', 'Food'),
      'مواصلات' => tr('مواصلات', 'Transport'),
      'فواتير' => tr('فواتير', 'Bills'),
      'صحة' => tr('صحة', 'Health'),
      'تسوق' => tr('تسوق', 'Shopping'),
      'ترفيه' => tr('ترفيه', 'Fun'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => c,
    };

class MoneyRepo {
  static String monthPrefix(int year, int month) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  Future<int> add(Expense e) async {
    final db = await AppDb.instance;
    return db.insert('expenses', e.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> forMonth(int year, int month) async {
    final db = await AppDb.instance;
    final rows = await db.query('expenses',
        where: 'day LIKE ?',
        whereArgs: ['${monthPrefix(year, month)}%'],
        orderBy: 'day DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<double> totalForMonth(int year, int month) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE day LIKE ?',
        ['${monthPrefix(year, month)}%']);
    return (rows.first['total'] as num).toDouble();
  }

  /// إجمالي كل فئة في الشهر — مرتب تنازليًا.
  Future<Map<String, double>> byCategory(int year, int month) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT category, SUM(amount) AS total FROM expenses '
        'WHERE day LIKE ? GROUP BY category ORDER BY total DESC',
        ['${monthPrefix(year, month)}%']);
    return {
      for (final r in rows) r['category'] as String: (r['total'] as num).toDouble()
    };
  }

  Future<double> totalForDay(String day) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE day = ?',
        [day]);
    return (rows.first['total'] as num).toDouble();
  }
}
