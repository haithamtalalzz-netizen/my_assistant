import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/settings_repo.dart';
import 'ar.dart';

/// تقرير PDF عام لأى قسم — جدول عربى RTL بخط القاهرة + ترويسة (اسم المستخدم
/// والتاريخ) + تذييل. محلى بالكامل (بيتبنى على الجهاز ويتشارك كملف، مفيش سيرفر).
class SectionPdf {
  /// [title] عنوان التقرير · [headers] رؤوس الأعمدة · [rows] الصفوف.
  static Future<void> share({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final name = await SettingsRepo().get('name') ?? '';
    final now = DateTime.now();

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18)),
            pw.Text(
              '${name.isEmpty ? '' : '$name — '}${arFullDate(now)}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(
          'My Assistant — ${arNum(context.pageNumber)}/${arNum(context.pagesCount)}',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        if (rows.isEmpty)
          pw.Text('لا توجد بيانات.',
              style: pw.TextStyle(font: font, fontSize: 12))
        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
                font: font, fontSize: 11, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: pw.TextStyle(font: font, fontSize: 10),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        pw.SizedBox(height: 10),
        pw.Text('عدد السجلات: ${arNum(rows.length)}',
            style: pw.TextStyle(
                font: font, fontSize: 10, color: PdfColors.grey700)),
      ],
    ));

    final bytes = await doc.save();
    final temp = await getTemporaryDirectory();
    final safe = title.replaceAll(RegExp(r'[^\w؀-ۿ]+'), '_');
    final file = File(p.join(temp.path, '${safe}_${dayKey(now)}.pdf'));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }
}
