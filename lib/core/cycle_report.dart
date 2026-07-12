import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/cycle_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';

/// تقرير الدورة الشهرية: PDF عربي RTL للعرض على الطبيبة —
/// سجل الدورات، المتوسطات والتوقّعات، أنماط الأعراض/المزاج، والتسجيلات اليومية.
class CycleReport {
  static Future<void> generateAndShare() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final settings = SettingsRepo();
    final name = await settings.userName();
    final repo = CycleRepo();
    final pred = await repo.predict();
    final logs = await repo.all(); // الأحدث الأول
    final insights = await repo.phaseInsights();
    final days = await repo.recentDays(limit: 60);

    // تواريخ البداية تصاعديًا (لحساب الفروق).
    final starts = logs
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();

    pw.Widget line(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(t, style: pw.TextStyle(font: font, fontSize: 11)));
    pw.Widget header(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Text(t,
            style: pw.TextStyle(
                font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)));

    doc.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      build: (context) => [
        pw.Text('تقرير الدورة الشهرية',
            style: pw.TextStyle(font: font, fontSize: 18)),
        line('${name.isEmpty ? '' : '$name — '}${arFullDate(now)}'),
        line('اتولد تلقائيًا من تطبيق My Assistant للعرض على الطبيبة.'),
        header('ملخص'),
        line('عدد الدورات المسجّلة: ${arNum(starts.length)}'),
        line('متوسط طول الدورة: ${arNum(pred.avgCycleLength)} يوم'),
        if (pred.lastStart != null)
          line('آخر دورة: ${arShortDate(pred.lastStart!)}'),
        if (pred.nextStart != null)
          line('الدورة الجاية المتوقّعة: ${arShortDate(pred.nextStart!)}'),
        if (pred.ovulation != null)
          line('التبويض المتوقّع: ${arShortDate(pred.ovulation!)}'),
        if (pred.fertileStart != null && pred.fertileEnd != null)
          line('أيام الخصوبة المتوقّعة: '
              '${arShortDate(pred.fertileStart!)} – ${arShortDate(pred.fertileEnd!)}'),
        header('سجل الدورات'),
        if (starts.isEmpty) line('لا يوجد دورات متسجلة.'),
        for (var i = starts.length - 1; i >= 0; i--)
          line('• ${arShortDate(starts[i])}'
              '${i > 0 ? ' — الفارق عن السابقة: ${arNum(starts[i].difference(starts[i - 1]).inDays)} يوم' : ''}'),
        header('أنماط الأعراض والمزاج حسب المرحلة'),
        if (insights.isEmpty)
          line('محتاج تسجيلات يومية أكتر لعرض الأنماط.'),
        for (final ins in insights)
          line('• ${phaseName(ins.phase)} (${arNum(ins.days)} يوم): '
              '${[
            if (ins.topMood != null) 'المزاج الغالب ${moodLabel(ins.topMood!)}',
            if (ins.topSymptoms.isNotEmpty)
              'أكثر الأعراض: ${ins.topSymptoms.map((e) => symptomLabel(e.key)).join('، ')}',
          ].join(' — ')}'),
        header('التسجيلات اليومية (آخر الفترة)'),
        if (days.isEmpty) line('لا يوجد تسجيلات يومية.'),
        for (final d in days)
          line('• ${d.day}: '
              '${[
            if (d.mood.isNotEmpty) moodLabel(d.mood),
            if (d.flow.isNotEmpty) 'نزيف ${flowLabel(d.flow)}',
            if (d.symptomList.isNotEmpty)
              d.symptomList.map(symptomLabel).join('، '),
            if (d.weight != null) '${d.weight} كجم',
            if (d.note.isNotEmpty) d.note,
          ].join(' · ')}'),
      ],
    ));

    final bytes = await doc.save();
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, 'cycle_report_${dayKey(now)}.pdf'));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'تقرير الدورة الشهرية');
  }
}
