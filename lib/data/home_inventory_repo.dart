import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kInventoryCategories = [
  'أجهزة',
  'أثاث',
  'إلكترونيات',
  'مجوهرات',
  'أخرى',
];

String inventoryCategoryLabel(String c) => switch (c) {
      'أجهزة' => tr('أجهزة', 'Appliances'),
      'أثاث' => tr('أثاث', 'Furniture'),
      'إلكترونيات' => tr('إلكترونيات', 'Electronics'),
      'مجوهرات' => tr('مجوهرات', 'Jewelry'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => c,
    };

/// جرد ممتلكات البيت — قائمة بالأشياء وقيمتها للتأمين/الطوارئ.
class HomeInventoryRepo {
  Future<List<HomeInventoryItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('home_inventory', orderBy: 'category, id DESC');
    return rows.map(HomeInventoryItem.fromMap).toList();
  }

  Future<double> totalValue() async {
    final db = await AppDb.instance;
    final r = await db
        .rawQuery('SELECT COALESCE(SUM(value),0) t FROM home_inventory');
    return (r.first['t'] as num).toDouble();
  }

  Future<int> save(HomeInventoryItem item) async {
    final db = await AppDb.instance;
    if (item.id == null) return db.insert('home_inventory', item.toMap());
    await db.update('home_inventory', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
    return item.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('home_inventory', where: 'id = ?', whereArgs: [id]);
  }
}
