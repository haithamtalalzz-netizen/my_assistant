import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kSocialTypes = ['naqoot', 'ozooma', 'eidiya', 'other'];
const List<String> kSocialDirections = ['received', 'given'];

String socialTypeLabel(String t) => switch (t) {
      'naqoot' => tr('نقوط', 'Gift money'),
      'ozooma' => tr('عزومة', 'Meal invite'),
      'eidiya' => tr('عيدية', 'Eidiya'),
      'other' => tr('أخرى', 'Other'),
      _ => t,
    };

String socialDirectionLabel(String d) => switch (d) {
      'received' => tr('اتقدملي', 'I received'),
      'given' => tr('قدّمت', 'I gave'),
      _ => d,
    };

class SocialRepo {
  Future<int> save(SocialObligation o) async {
    final db = await AppDb.instance;
    if (o.id == null) return db.insert('social_obligations', o.toMap());
    await db.update('social_obligations', o.toMap(),
        where: 'id = ?', whereArgs: [o.id]);
    return o.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('social_obligations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setReciprocated(int id, bool value) async {
    final db = await AppDb.instance;
    await db.update('social_obligations', {'reciprocated': value ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SocialObligation>> all({String? direction}) async {
    final db = await AppDb.instance;
    final rows = await db.query('social_obligations',
        where: direction == null ? null : 'direction = ?',
        whereArgs: direction == null ? null : [direction],
        orderBy: 'day DESC, id DESC');
    return rows.map(SocialObligation.fromMap).toList();
  }

  /// صافي كل شخص للمبالغ: (اتقدملي) − (قدّمت). موجب = إداك أكتر → مدين له.
  Future<List<({String person, double net})>> perPersonBalance() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery('''
      SELECT person,
        SUM(CASE WHEN direction = 'received' THEN COALESCE(amount,0)
                 ELSE -COALESCE(amount,0) END) AS net
      FROM social_obligations
      GROUP BY person
      HAVING net != 0
      ORDER BY net DESC
    ''');
    return [
      for (final r in rows)
        (person: r['person'] as String, net: (r['net'] as num).toDouble())
    ];
  }
}
