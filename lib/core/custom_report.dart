import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'file_out.dart';

import '../data/day_log_repo.dart';
import 'ar.dart';

/// البنود المتاحة في التقرير المخصّص (نفس أنواع تقويم النتيجة).
const Map<String, String> kReportSections = {
  'appointment': 'المواعيد',
  'med': 'الأدوية',
  'expense': 'المصروفات',
  'income': 'الدخل',
  'meal': 'الوجبات',
  'measurement': 'القياسات',
  'medical': 'السجل الطبي',
  'habit': 'العادات',
  'workout': 'التمرين',
  'gym': 'الجيم',
  'health': 'الصحة العامة',
};

/// تقرير PDF مخصّص: يختار المستخدم البنود ومدى التاريخ، وفيه بانر كحلي + شعار.
class CustomReport {
  static const _navy = 0xFF0B1C3D;
  static const _accent = 0xFF2FDE9B;

  static Future<void> generateAndShare({
    required Set<String> kinds,
    required DateTime from,
    required DateTime to,
  }) async {
    final repo = DayLogRepo();
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    // نجمّع الأحداث حسب النوع في المدى المطلوب.
    final byKind = <String, List<(String day, DayEvent e)>>{};
    var d = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    var guard = 0;
    while (!d.isAfter(end) && guard < 800) {
      final key = dayKey(d);
      for (final e in await repo.forDay(key)) {
        if (kinds.contains(e.kind)) {
          (byKind[e.kind] ??= []).add((key, e));
        }
      }
      d = d.add(const Duration(days: 1));
      guard++;
    }

    final doc = pw.Document();

    pw.Widget banner() => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(_navy)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // شعار: هلال أخضر (دائرتين).
              pw.Stack(
                children: [
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(_accent),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Positioned(
                    right: 0,
                    top: -2,
                    child: pw.Container(
                      width: 28,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(_navy),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('مساعدي',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 20,
                            color: const PdfColor.fromInt(0xFFFFFFFF))),
                    pw.Text('تقرير — من ${arShortDate(from)} إلى ${arShortDate(to)}',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: const PdfColor.fromInt(0xFFB9C4D6))),
                  ],
                ),
              ),
            ],
          ),
        );

    pw.Widget sectionHeader(String text) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14, bottom: 4),
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFEFF4F2),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  color: const PdfColor.fromInt(0xFF0E7A5F))),
        );

    final selected =
        kReportSections.keys.where((k) => kinds.contains(k)).toList();

    doc.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      margin: const pw.EdgeInsets.all(0),
      build: (context) => [
        banner(),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final k in selected) ...[
                sectionHeader(
                    '${kReportSections[k]} (${arNum((byKind[k] ?? const []).length)})'),
                if ((byKind[k] ?? const []).isEmpty)
                  pw.Text('لا يوجد',
                      style: pw.TextStyle(font: font, fontSize: 10))
                else
                  for (final row in byKind[k]!)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                      child: pw.Text(
                          '• ${arShortDate(DateTime.parse(row.$1))}${row.$2.time == null ? '' : ' ${row.$2.time}'} — ${row.$2.text}',
                          style: pw.TextStyle(font: font, fontSize: 11)),
                    ),
              ],
            ],
          ),
        ),
      ],
    ));

    final bytes = await doc.save();
    await deliverFile('report.pdf', 'application/pdf', bytes);
  }

  /// نفس الاختيارات لكن كملف CSV يفتح في Excel (بـ BOM عشان العربي يظهر صح).
  static Future<void> generateCsvAndShare({
    required Set<String> kinds,
    required DateTime from,
    required DateTime to,
  }) async {
    final repo = DayLogRepo();
    final rows = <List<String>>[
      ['القسم', 'التاريخ', 'الوقت', 'التفاصيل'],
    ];
    var d = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    var guard = 0;
    while (!d.isAfter(end) && guard < 800) {
      final key = dayKey(d);
      for (final e in await repo.forDay(key)) {
        if (kinds.contains(e.kind)) {
          rows.add([
            kReportSections[e.kind] ?? e.kind,
            key,
            e.time ?? '',
            e.text,
          ]);
        }
      }
      d = d.add(const Duration(days: 1));
      guard++;
    }

    String cell(String s) => '"${s.replaceAll('"', '""')}"';
    final csv = rows.map((r) => r.map(cell).join(',')).join('\r\n');
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, 'report.csv'));
    // ﻿ = BOM عشان Excel يقرا UTF-8 عربي صح.
    await file.writeAsString('﻿$csv');
    await Share.shareXFiles([XFile(file.path)], text: 'تقرير مساعدي (Excel)');
  }
}
