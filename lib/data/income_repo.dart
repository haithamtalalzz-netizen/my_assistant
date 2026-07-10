import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';
import 'money_repo.dart';

const List<String> kIncomeSources = [
  'مرتب',
  'عمل حر',
  'مكافأة',
  'بيع',
  'أخرى',
];

/// عرض مصدر الدخل بالإنجليزي مع إبقاء القيمة المخزّنة عربي.
String incomeSourceLabel(String s) => switch (s) {
      'مرتب' => tr('مرتب', 'Salary'),
      'عمل حر' => tr('عمل حر', 'Freelance'),
      'مكافأة' => tr('مكافأة', 'Bonus'),
      'بيع' => tr('بيع', 'Sale'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => s,
    };

class IncomeRepo {
  // ---- الدخل المتسجّل ----

  Future<int> add(Income e) async {
    final db = await AppDb.instance;
    return db.insert('income', e.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> forMonth(int year, int month) async {
    final db = await AppDb.instance;
    final rows = await db.query('income',
        where: 'day LIKE ?',
        whereArgs: ['${MoneyRepo.monthPrefix(year, month)}%'],
        orderBy: 'day DESC, id DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<double> totalForMonth(int year, int month) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM income WHERE day LIKE ?',
        ['${MoneyRepo.monthPrefix(year, month)}%']);
    return (rows.first['total'] as num).toDouble();
  }

  // ---- الدخل الدوري (المرتب) + تذكير شهري ----

  Future<List<RecurringIncome>> allRecurring() async {
    final db = await AppDb.instance;
    final rows = await db.query('recurring_income', orderBy: 'day_of_month');
    return rows.map(RecurringIncome.fromMap).toList();
  }

  Future<int> saveRecurring(RecurringIncome inc) async {
    final db = await AppDb.instance;
    final int id;
    if (inc.id == null) {
      id = await db.insert('recurring_income', inc.toMap());
    } else {
      id = inc.id!;
      await db.update('recurring_income', inc.toMap(),
          where: 'id = ?', whereArgs: [id]);
    }
    final saved = RecurringIncome(
      id: id,
      source: inc.source,
      amount: inc.amount,
      dayOfMonth: inc.dayOfMonth,
      lastReceivedMonth: inc.lastReceivedMonth,
    );
    await _reschedule(saved);
    return id;
  }

  Future<void> deleteRecurring(int id) async {
    final db = await AppDb.instance;
    await db.delete('recurring_income', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.incomeNotifId(id));
  }

  /// «قبضته» — بيتسجّل دخل فعلي + بيختم الشهر عشان مايفكّرش تاني.
  Future<void> markReceived(RecurringIncome inc, {required DateTime now}) async {
    final monthKey = MoneyRepo.monthPrefix(now.year, now.month);
    await add(Income(
      amount: inc.amount,
      source: inc.source,
      note: tr('دخل دوري', 'Recurring income'),
      day: '$monthKey-${now.day.toString().padLeft(2, '0')}',
    ));
    final db = await AppDb.instance;
    await db.update('recurring_income', {'last_received_month': monthKey},
        where: 'id = ?', whereArgs: [inc.id]);
  }

  Future<List<RecurringIncome>> dueRecurring(DateTime now) async {
    final all = await allRecurring();
    return [for (final i in all) if (i.isDue(now)) i];
  }

  Future<void> rescheduleAll() async {
    for (final inc in await allRecurring()) {
      await _reschedule(inc);
    }
  }

  Future<void> _reschedule(RecurringIncome inc) async {
    await Notifications.cancel(Notifications.incomeNotifId(inc.id!));
    await Notifications.scheduleMonthly(
      id: Notifications.incomeNotifId(inc.id!),
      title: tr('يوم القبض: ${incomeSourceLabel(inc.source)}',
          'Payday: ${incomeSourceLabel(inc.source)}'),
      body: tr('مستنى ${_egpLite(inc.amount)} — سجّله وقسّمه على التزاماتك',
          'Expecting ${_egpLite(inc.amount)} — log it and split it across your obligations'),
      dayOfMonth: inc.dayOfMonth,
      hour: 10,
      minute: 0,
    );
  }

  /// صيغة مبلغ بسيطة للإشعار (من غير locale-awareness عشان وقت الجدولة).
  String _egpLite(double v) {
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    return tr('$s ج.م', '$s EGP');
  }
}
