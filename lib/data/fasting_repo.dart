import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

/// الصيام المتقطّع — نافذة صيام واحدة شغّالة فى المرة + تنبيه انتهاء الهدف.
class FastingRepo {
  /// النافذة الشغّالة دلوقتى (لسه ما اتقفلتش) أو null.
  Future<FastSession?> current() async {
    final db = await AppDb.instance;
    final rows = await db.query('if_fasts',
        where: 'end_at IS NULL', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return FastSession.fromMap(rows.first);
  }

  /// يبدأ صيام (لو فيه واحد شغّال بيقفله الأول).
  Future<int> start({int targetHours = 16}) async {
    final db = await AppDb.instance;
    final now = DateTime.now();
    await _endOngoing(now);
    final id = await db.insert('if_fasts', {
      'start_at': now.toIso8601String(),
      'target_hours': targetHours,
      'created_at': now.toIso8601String(),
    });
    // تنبيه عند اكتمال الهدف.
    final when = now.add(Duration(hours: targetHours));
    await Notifications.scheduleOnce(
      id: Notifications.fastingEndNotifId,
      title: tr('خلص صيامك 🎉', 'Fast complete 🎉'),
      body: tr('عدّى $targetHours ساعة — تقدر تفطر',
          '${targetHours}h done — you can eat now'),
      when: when,
    );
    return id;
  }

  /// ينهى الصيام الشغّال.
  Future<void> stop() async {
    await _endOngoing(DateTime.now());
    await Notifications.cancel(Notifications.fastingEndNotifId);
  }

  /// يعيد جدولة تنبيه انتهاء الصيام الشغّال (بعد إعادة تشغيل التطبيق).
  Future<void> rescheduleCurrent() async {
    final f = await current();
    if (f == null) return;
    final when = f.start.add(Duration(hours: f.targetHours));
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.fastingEndNotifId,
      title: tr('خلص صيامك 🎉', 'Fast complete 🎉'),
      body: tr('عدّى ${f.targetHours} ساعة — تقدر تفطر',
          '${f.targetHours}h done — you can eat now'),
      when: when,
    );
  }

  Future<void> _endOngoing(DateTime at) async {
    final db = await AppDb.instance;
    await db.update('if_fasts', {'end_at': at.toIso8601String()},
        where: 'end_at IS NULL');
  }

  Future<List<FastSession>> recent({int limit = 30}) async {
    final db = await AppDb.instance;
    final rows = await db.query('if_fasts',
        where: 'end_at IS NOT NULL', orderBy: 'id DESC', limit: limit);
    return rows.map(FastSession.fromMap).toList();
  }

  /// عدد الصيامات المكتملة (وصلت الهدف) خلال آخر [days] يوم.
  Future<int> completedLast(int days) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final list = await recent(limit: 100);
    return list
        .where((f) => f.start.isAfter(from) && f.reachedTarget)
        .length;
  }
}
