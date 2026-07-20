import 'package:flutter/material.dart';

import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/occasions_repo.dart';
import '../data/tasks_repo.dart';
import 'ar.dart';
import 'l10n.dart';

/// عنصر فى نظرة الأسبوع.
class WeekItem {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String text;
  const WeekItem(this.date, this.icon, this.color, this.text);
}

/// يجمّع كل اللى جاى فى الـ٧ أيام الجاية (مواعيد/مهام/فواتير/تجديدات/مناسبات).
Future<List<WeekItem>> collectWeekOverview() async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final end = today.add(const Duration(days: 7));
  bool inWin(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(today) && day.isBefore(end);
  }

  final items = <WeekItem>[];

  // المواعيد (غير المنتهية).
  for (final a in await AppointmentsRepo().all()) {
    if (!a.done && inWin(a.when)) {
      items.add(WeekItem(a.when, Icons.event, Colors.blue, a.title));
    }
  }

  // المهام المفتوحة اللى ليها موعد.
  for (final t in await TasksRepo().tasks(openOnly: true)) {
    final d = t.due;
    if (d != null && inWin(d)) {
      items.add(WeekItem(d, Icons.checklist_rtl, Colors.deepPurple, t.title));
    }
  }

  // المناسبات.
  for (final o in await OccasionsRepo().all()) {
    final d = o.nextOccurrence(now);
    if (inWin(d)) {
      items.add(WeekItem(d, Icons.celebration_outlined, Colors.pink, o.title));
    }
  }

  // الفواتير الدورية (يوم الاستحقاق الجاى).
  final monthKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
  for (final b in await BillsRepo().all()) {
    final d = _nextMonthDay(today, b.dayOfMonth);
    // ما نعرضش لو اتدفعت الشهر ده والموعد لسه فى نفس الشهر.
    final paidThisMonth = b.lastPaidMonth == monthKey;
    if (inWin(d) && !(paidThisMonth && d.month == now.month)) {
      items.add(WeekItem(d, Icons.receipt_long_outlined, Colors.teal,
          tr('فاتورة ${b.name} — ${egp(b.amount)}',
              '${b.name} bill — ${egp(b.amount)}')));
    }
  }

  items.sort((a, b) => a.date.compareTo(b.date));
  return items;
}

/// أقرب تاريخ ليوم [dayOfMonth] فى الشهر (من [from] أو الشهر اللى بعده).
DateTime _nextMonthDay(DateTime from, int dayOfMonth) {
  final thisMonth = DateTime(from.year, from.month, dayOfMonth);
  if (!thisMonth.isBefore(from)) return thisMonth;
  return DateTime(from.year, from.month + 1, dayOfMonth);
}
