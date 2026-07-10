import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/day_log_repo.dart';
import 'ar.dart';

/// تصدير كل نشاط شهر معيّن كـ PDF (عربي RTL) — للمراجعة أو الأرشفة.
class MonthReport {
  static Future<void> generateAndShare(int year, int month) async {
    final repo = DayLogRepo();
    final active = (await repo.daysWithActivity(year, month)).toList()..sort();

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();
    final monthDate = DateTime(year, month);

    pw.Widget dayHeader(String text) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12, bottom: 4),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 13,
                  color: PdfColor.fromInt(0xFF0E7A5F))),
        );
    pw.Widget line(String text) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Text('• $text',
              style: pw.TextStyle(font: font, fontSize: 11)),
        );

    // نجمّع أحداث كل يوم قبل بناء الصفحة.
    final byDay = <String, List<DayEvent>>{};
    for (final day in active) {
      byDay[day] = await repo.forDay(day);
    }

    doc.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      build: (context) => [
        pw.Text('سجل ${arMonth(monthDate)}',
            style: pw.TextStyle(font: font, fontSize: 18)),
        pw.Text('اتولد تلقائيًا من تطبيق My Assistant.',
            style: pw.TextStyle(font: font, fontSize: 10)),
        if (active.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 16),
            child: pw.Text('مفيش نشاط متسجل الشهر ده.',
                style: pw.TextStyle(font: font, fontSize: 12)),
          ),
        for (final day in active) ...[
          dayHeader(arFullDate(DateTime.parse(day))),
          for (final e in byDay[day]!)
            line('${e.time == null ? '' : '${e.time} — '}${e.text}'),
        ],
      ],
    ));

    final bytes = await doc.save();
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path,
        'month_${year}_${month.toString().padLeft(2, '0')}.pdf'));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'سجل ${arMonth(monthDate)}');
  }
}
