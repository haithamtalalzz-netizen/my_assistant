import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';
import 'money_repo.dart';

class GameyaRepo {
  Future<List<Gameya>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('gameya', orderBy: 'id DESC');
    return rows.map(Gameya.fromMap).toList();
  }

  Future<int> save(Gameya g) async {
    final db = await AppDb.instance;
    final int id;
    if (g.id == null) {
      id = await db.insert('gameya', g.toMap());
    } else {
      id = g.id!;
      await db.update('gameya', g.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(Gameya(
      id: id,
      name: g.name,
      amount: g.amount,
      dayOfMonth: g.dayOfMonth,
      totalMonths: g.totalMonths,
      myTurn: g.myTurn,
      startMonth: g.startMonth,
    ));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('gameya', where: 'id = ?', whereArgs: [id]);
    await db.delete('gameya_payments', where: 'gameya_id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.gameyaNotifId(id));
  }

  /// الشهور اللي دفعتها في جمعية (مفاتيح YYYY-MM).
  Future<Set<String>> paidMonths(int gameyaId) async {
    final db = await AppDb.instance;
    final rows = await db.query('gameya_payments',
        where: 'gameya_id = ?', whereArgs: [gameyaId]);
    return rows.map((r) => r['month_key'] as String).toSet();
  }

  Future<void> setPaid(int gameyaId, String monthKey, bool paid,
      {double? amount}) async {
    final db = await AppDb.instance;
    if (paid) {
      await db.insert('gameya_payments',
          {'gameya_id': gameyaId, 'month_key': monthKey},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      if (amount != null) {
        // قسط الجمعية بيتسجل مصروف كمان.
        await MoneyRepo().add(Expense(
          amount: amount,
          category: 'أخرى',
          note: 'قسط جمعية',
          day: '$monthKey-${DateTime.now().day.toString().padLeft(2, '0')}',
        ));
      }
    } else {
      await db.delete('gameya_payments',
          where: 'gameya_id = ? AND month_key = ?',
          whereArgs: [gameyaId, monthKey]);
    }
  }

  Future<void> rescheduleAll() async {
    for (final g in await all()) {
      await _reschedule(g);
    }
  }

  Future<void> _reschedule(Gameya g) async {
    await Notifications.cancel(Notifications.gameyaNotifId(g.id!));
    final now = DateTime.now();
    if (!g.isActive(now) && g.monthIndex(now) < 1) {
      // لسه ماابتدتش — نجدول من غير شرط الوقت الحالي.
    } else if (!g.isActive(now)) {
      return; // خلصت
    }
    final turnMonths = g.monthsUntilMyTurn(now);
    final body = turnMonths == 0
        ? tr('قسط ${egp(g.amount)} — والشهر ده دورك تقبض ${egp(g.payout)}!',
            'Installment ${egp(g.amount)} — and this month it\'s your turn to collect ${egp(g.payout)}!')
        : turnMonths > 0
            ? tr('قسط ${egp(g.amount)} — فاضل ${arNum(turnMonths)} شهور على دورك',
                'Installment ${egp(g.amount)} — ${arNum(turnMonths)} months until your turn')
            : tr('قسط ${egp(g.amount)}', 'Installment ${egp(g.amount)}');
    await Notifications.scheduleMonthly(
      id: Notifications.gameyaNotifId(g.id!),
      title: tr('قسط جمعية: ${g.name}', 'Gam\'iya installment: ${g.name}'),
      body: body,
      dayOfMonth: g.dayOfMonth,
      hour: 11,
      minute: 0,
    );
  }
}
