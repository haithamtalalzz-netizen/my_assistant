import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class QuranRepo {
  /// جدول التكرار المتباعد (بالأيام) حسب عدد المراجعات الناجحة.
  static const List<int> _intervals = [1, 3, 7, 14, 30, 60];

  Future<int> add(String portion) async {
    final db = await AppDb.instance;
    return db.insert('quran_reviews',
        QuranReview(portion: portion).toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('quran_reviews', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuranReview>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('quran_reviews', orderBy: 'last_reviewed');
    return rows.map(QuranReview.fromMap).toList();
  }

  Future<List<QuranReview>> due(DateTime now) async {
    final all = await this.all();
    return [for (final r in all) if (r.isDue(now)) r];
  }

  /// «راجعت كويس» — بيباعد المراجعة الجاية أكتر.
  Future<void> markReviewed(QuranReview r, {required DateTime now}) async {
    final reps = r.reps + 1;
    final interval = _intervals[reps.clamp(0, _intervals.length - 1)];
    await _update(r.id!, dayKey(now), interval, reps);
  }

  /// «محتاجة مراجعة أكتر» — بترجّع المدة لأقصر.
  Future<void> markForgot(QuranReview r, {required DateTime now}) async {
    await _update(r.id!, dayKey(now), 1, 0);
  }

  Future<void> _update(int id, String day, int interval, int reps) async {
    final db = await AppDb.instance;
    await db.update(
        'quran_reviews',
        {'last_reviewed': day, 'interval_days': interval, 'reps': reps},
        where: 'id = ?',
        whereArgs: [id]);
  }

  /// تذكير مراجعة (٨م) لو فيه أوراد مستحقة النهارده.
  Future<void> ensureReminder() async {
    await Notifications.cancel(Notifications.quranNotifId);
    final now = DateTime.now();
    final dueList = await due(now);
    if (dueList.isEmpty) return;
    final when = DateTime(now.year, now.month, now.day, 20);
    if (when.isBefore(now)) return;
    await Notifications.scheduleOnce(
      id: Notifications.quranNotifId,
      title: tr('مراجعة قرآن', 'Quran review'),
      body: dueList.length == 1
          ? tr('«${dueList.first.portion}» مستحقة المراجعة النهارده',
              '"${dueList.first.portion}" is due for review today')
          : tr('${arNum(dueList.length)} أوراد مستحقة المراجعة النهارده',
              '${arNum(dueList.length)} portions due for review today'),
      when: when,
    );
  }
}
