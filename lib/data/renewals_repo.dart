import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kRenewalTypes = [
  'national_id',
  'passport',
  'license',
  'insurance',
  'other',
];

String renewalTypeLabel(String t) => switch (t) {
      'national_id' => tr('بطاقة', 'National ID'),
      'passport' => tr('جواز سفر', 'Passport'),
      'license' => tr('رخصة', 'License'),
      'insurance' => tr('تأمين', 'Insurance'),
      _ => tr('أخرى', 'Other'),
    };

/// التجديدات — وثائق ليها تاريخ انتهاء + تنبيه قبلها بعدد أيام.
class RenewalsRepo {
  Future<List<Renewal>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('renewals', orderBy: 'expiry');
    return rows.map(Renewal.fromMap).toList();
  }

  /// اللى قرب ينتهى خلال [days] يوم أو انتهى (للرئيسية/التنبيهات).
  Future<List<Renewal>> dueSoon({int days = 45}) async {
    final list = await all();
    return [
      for (final r in list)
        if (r.daysLeft != null && r.daysLeft! <= days) r
    ];
  }

  Future<int> save(Renewal r) async {
    final db = await AppDb.instance;
    final int id;
    if (r.id == null) {
      id = await db.insert('renewals', r.toMap());
    } else {
      id = r.id!;
      await db.update('renewals', r.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, r);
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('renewals', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.renewalNotifId(id));
  }

  Future<void> _reschedule(int id, Renewal r) async {
    await Notifications.cancel(Notifications.renewalNotifId(id));
    final e = r.expiryDate;
    if (e == null) return;
    final when =
        DateTime(e.year, e.month, e.day, 10).subtract(Duration(days: r.remindDays));
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.renewalNotifId(id),
      title: tr('قرب تجديد: ${r.title}', 'Renewal soon: ${r.title}'),
      body: tr('باقى ${r.remindDays} يوم على انتهاء ${renewalTypeLabel(r.type)}',
          '${r.remindDays} days until ${renewalTypeLabel(r.type)} expires'),
      when: when,
    );
  }

  Future<void> rescheduleAll() async {
    for (final r in await all()) {
      if (r.id != null) await _reschedule(r.id!, r);
    }
  }
}
