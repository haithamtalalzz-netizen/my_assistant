import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kAssetTypes = [
  'gold',
  'property',
  'investment',
  'certificate',
  'cash',
  'other',
];

String assetTypeLabel(String t) => switch (t) {
      'gold' => tr('دهب', 'Gold'),
      'property' => tr('عقار', 'Property'),
      'investment' => tr('استثمار', 'Investment'),
      'certificate' => tr('شهادة', 'Certificate'),
      'cash' => tr('فلوس برّه', 'Cash elsewhere'),
      'other' => tr('أخرى', 'Other'),
      _ => t,
    };

String assetTypeEmoji(String t) => switch (t) {
      'gold' => '🥇',
      'property' => '🏠',
      'investment' => '📈',
      'certificate' => '📜',
      'cash' => '💵',
      _ => '💼',
    };

class AssetsRepo {
  Future<int> save(Asset a) async {
    final db = await AppDb.instance;
    if (a.id == null) return db.insert('assets', a.toMap());
    await db.update('assets', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
    return a.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Asset>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('assets', orderBy: 'value DESC, id DESC');
    return rows.map(Asset.fromMap).toList();
  }

  Future<double> totalValue() async {
    final db = await AppDb.instance;
    final r =
        await db.rawQuery('SELECT COALESCE(SUM(value), 0) AS s FROM assets');
    return (r.first['s'] as num).toDouble();
  }
}
