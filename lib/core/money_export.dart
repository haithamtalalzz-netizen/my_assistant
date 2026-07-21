import 'dart:convert';


import 'file_out.dart';

import '../data/income_repo.dart';
import '../data/money_repo.dart';
import 'l10n.dart';

/// تصدير حركات الشهر (مصروفات + دخل) كملف CSV يفتح فى Excel — محلى ومجانى.
class MoneyExport {
  static Future<void> exportMonthCsv(int year, int month) async {
    final expenses = await MoneyRepo().forMonth(year, month);
    final income = await IncomeRepo().forMonth(year, month);

    final rows = <List<String>>[
      [
        tr('التاريخ', 'Date'),
        tr('النوع', 'Type'),
        tr('الفئة/المصدر', 'Category/Source'),
        tr('المبلغ', 'Amount'),
        tr('ملاحظة', 'Note'),
      ],
    ];
    for (final e in expenses) {
      rows.add([
        e.day,
        tr('مصروف', 'Expense'),
        e.category,
        e.amount.toStringAsFixed(2),
        e.note,
      ]);
    }
    for (final i in income) {
      rows.add([
        i.day,
        tr('دخل', 'Income'),
        i.source,
        i.amount.toStringAsFixed(2),
        i.note,
      ]);
    }

    final csv = rows.map((r) => r.map(_esc).join(',')).join('\r\n');
    // BOM عشان Excel يقرا الـUTF-8 (العربى) صح.
    final bytes = utf8.encode('﻿$csv');
    await deliverFile(
        'money_${year}_${month.toString().padLeft(2, '0')}.csv',
        'text/csv',
        bytes);
  }

  static String _esc(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
