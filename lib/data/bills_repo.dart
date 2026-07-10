import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';
import 'money_repo.dart';

class BillsRepo {
  Future<List<RecurringBill>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('recurring_bills', orderBy: 'day_of_month');
    return rows.map(RecurringBill.fromMap).toList();
  }

  Future<List<RecurringBill>> due(DateTime now) async =>
      [for (final b in await all()) if (b.isDue(now)) b];

  Future<int> save(RecurringBill bill) async {
    final db = await AppDb.instance;
    final int id;
    if (bill.id == null) {
      id = await db.insert('recurring_bills', bill.toMap());
    } else {
      id = bill.id!;
      await db.update('recurring_bills', bill.toMap(),
          where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(RecurringBill(
      id: id,
      name: bill.name,
      amount: bill.amount,
      dayOfMonth: bill.dayOfMonth,
      category: bill.category,
      lastPaidMonth: bill.lastPaidMonth,
    ));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('recurring_bills', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.billNotifId(id));
  }

  /// دفع الفاتورة = مصروف متسجل + ختم الشهر الحالي.
  Future<void> markPaid(int id, {DateTime? now}) async {
    final current = now ?? DateTime.now();
    final db = await AppDb.instance;
    final rows = await db
        .query('recurring_bills', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final bill = RecurringBill.fromMap(rows.first);
    final monthKey = MoneyRepo.monthPrefix(current.year, current.month);
    if (bill.lastPaidMonth == monthKey) return; // اتدفعت خلاص
    await MoneyRepo().add(Expense(
      amount: bill.amount,
      category: bill.category,
      note: bill.name,
      day: dayKey(current),
    ));
    await db.update('recurring_bills', {'last_paid_month': monthKey},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> rescheduleAll() async {
    for (final b in await all()) {
      await _reschedule(b);
    }
  }

  Future<void> _reschedule(RecurringBill bill) async {
    await Notifications.cancel(Notifications.billNotifId(bill.id!));
    await Notifications.scheduleMonthly(
      id: Notifications.billNotifId(bill.id!),
      title: tr('فاتورة مستحقة: ${bill.name}', 'Bill due: ${bill.name}'),
      body: tr('${egp(bill.amount)} تقريبًا — دوس «اتدفعت» بعد ما تدفعها',
          'About ${egp(bill.amount)} — tap "Paid" once you\'ve paid it'),
      dayOfMonth: bill.dayOfMonth,
      hour: 10,
      minute: 0,
      payload: 'bill|${bill.id}',
      actions: [
        AndroidNotificationAction('bill_paid', tr('اتدفعت ✓', 'Paid ✓'),
            showsUserInterface: false, cancelNotification: true),
      ],
    );
  }
}
