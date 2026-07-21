
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'file_out.dart';

import '../data/appointments_repo.dart';
import '../data/insights_repo.dart';
import '../data/lab_results_repo.dart';
import '../data/measurements_repo.dart';
import '../data/medical_repo.dart';
import '../data/symptoms_repo.dart';
import '../data/meds_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'db.dart';

/// تقرير الدكتور: PDF عربي RTL بآخر ٣٠ يوم — أدوية والتزام، نوم، مياه،
/// خطوات، قياسات، ومواعيد صحية. بيتبني محليًا ويتشارك كملف.
class DoctorReport {
  static Future<void> generateAndShare() async {
    final now = DateTime.now();
    final from = dateOnly(now).subtract(const Duration(days: 29));
    final fromKey = dayKey(from);

    final settings = SettingsRepo();
    final name = await settings.userName();

    // الأدوية + نسبة الالتزام (الجرعات المتسجلة ÷ المفروضة).
    final meds = await MedsRepo().all(activeOnly: true);
    final db = await AppDb.instance;
    final takenRows = await db.rawQuery(
        'SELECT med_id, COUNT(*) AS c FROM med_logs WHERE day >= ? GROUP BY med_id',
        [fromKey]);
    final takenBy = {
      for (final r in takenRows) r['med_id'] as int: r['c'] as int
    };

    // متوسطات النوم والمياه والخطوات.
    final data = await InsightsRepo().assemble(now: now);
    final last30 = data.days.length > 30
        ? data.days.sublist(data.days.length - 30)
        : data.days;
    final sleepVals = [
      for (final d in last30)
        if (d.sleep != null) d.sleep!
    ];
    final waterVals = [for (final d in last30) d.water.toDouble()];
    final stepVals = [
      for (final d in last30)
        if (d.steps != null) d.steps!.toDouble()
    ];
    final calorieVals = [
      for (final d in last30)
        if (d.calories != null) d.calories!.toDouble()
    ];
    final distanceVals = [
      for (final d in last30)
        if (d.distanceKm != null) d.distanceKm!
    ];
    double? avg(List<double> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    final measurements = await MeasurementsRepo().since(fromKey);
    final labResults = await LabResultsRepo().latestPerName();
    final medicalRecords = await MedicalRepo().since(fromKey);
    final symptoms = await SymptomsRepo().since(fromKey);
    final appts = await AppointmentsRepo().all();
    final healthAppts = [
      for (final a in appts)
        if (a.category == 'صحة' &&
            a.when.isAfter(from) &&
            a.when.isBefore(now.add(const Duration(days: 30))))
          a
    ];

    final fontData =
        await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();

    pw.Widget header(String text) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(text,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  color: PdfColor.fromInt(0xFF0E7A5F))),
        );
    pw.Widget line(String text) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(text,
              style: pw.TextStyle(font: font, fontSize: 11)),
        );
    // التقرير عربي دايمًا — نوع السجل بالعربي بغض النظر عن لغة التطبيق.
    String medType(String t) => switch (t) {
          'visit' => 'زيارة',
          'lab' => 'تحاليل',
          'imaging' => 'أشعة',
          'procedure' => 'إجراء',
          _ => t,
        };

    doc.addPage(pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font),
      build: (context) => [
        pw.Text('تقرير صحي — آخر ٣٠ يوم',
            style: pw.TextStyle(font: font, fontSize: 18)),
        line('${name.isEmpty ? '' : '$name — '}${arFullDate(now)}'),
        line('اتولد تلقائيًا من تطبيق My Assistant للعرض على الطبيب.'),
        header('الأدوية الحالية والالتزام'),
        if (meds.isEmpty) line('لا يوجد أدوية متسجلة.'),
        for (final m in meds)
          line('• ${m.name}${m.dosage.isEmpty ? '' : ' — ${m.dosage}'} '
              '(${arNum(m.times.length)} جرعات/يوم) — التزام آخر ٣٠ يوم: '
              '٪${arNum(((takenBy[m.id] ?? 0) * 100 / (m.times.length * 30)).clamp(0, 100).round())}'),
        header('مؤشرات عامة'),
        if (avg(sleepVals) != null)
          line('متوسط النوم: ${arNum(avg(sleepVals)!.toStringAsFixed(1))} ساعة/ليلة '
              '(${arNum(sleepVals.length)} ليلة متسجلة)'),
        line('متوسط المياه: ${arNum(avg(waterVals)?.toStringAsFixed(1) ?? '0')} كوباية/يوم'),
        if (avg(stepVals) != null)
          line('متوسط الخطوات: ${arNum(avg(stepVals)!.round())} خطوة/يوم'),
        if (avg(calorieVals) != null)
          line('متوسط السعرات المحروقة: ${arNum(avg(calorieVals)!.round())} سعرة/يوم '
              '(${arNum(calorieVals.length)} يوم متسجل)'),
        if (avg(distanceVals) != null)
          line('متوسط المسافة: ${arNum(avg(distanceVals)!.toStringAsFixed(1))} كم/يوم'),
        header('القياسات المتسجلة'),
        if (measurements.isEmpty) line('لا يوجد قياسات متسجلة في الفترة دي.'),
        for (final m in measurements)
          line('• ${m.day} — ${m.type}: ${m.display()}'),
        header('مؤشرات التحاليل (آخر نتيجة لكل تحليل)'),
        if (labResults.isEmpty) line('لا يوجد تحاليل متسجلة.'),
        for (final r in labResults)
          line('• ${r.name}: ${arNum(r.value == r.value.roundToDouble() ? r.value.round().toString() : r.value.toStringAsFixed(1))}'
              '${r.unit.isEmpty ? '' : ' ${r.unit}'}'
              '${r.date.isEmpty ? '' : ' (${r.date})'}'
              '${r.outOfRange ? (r.status > 0 ? ' — فوق الطبيعى ⚠' : ' — تحت الطبيعى ⚠') : ''}'),
        header('السجل الطبي (زيارات / تحاليل / أشعة / إجراءات)'),
        if (medicalRecords.isEmpty)
          line('لا يوجد سجلات طبية في الفترة دي.'),
        for (final r in medicalRecords)
          line('• ${r.day} — ${medType(r.type)}: ${r.title}'
              '${r.provider.isEmpty ? '' : ' (${r.provider})'}'
              '${r.result.isEmpty ? '' : ' — ${r.result}'}'),
        header('الأعراض المسجلة'),
        if (symptoms.isEmpty) line('لا يوجد أعراض مسجلة في الفترة دي.'),
        for (final s in symptoms)
          line('• ${s.day} — ${s.symptom} (شدّة ${arNum(s.severity)}/٥)'
              '${s.note.isEmpty ? '' : ' — ${s.note}'}'),
        header('مواعيد صحية (سابقة وقادمة)'),
        if (healthAppts.isEmpty) line('لا يوجد.'),
        for (final a in healthAppts)
          line('• ${a.title} — ${arShortDate(a.when)}${a.done ? ' (تمت)' : ''}'),
      ],
    ));

    final bytes = await doc.save();
    await deliverFile(
        'health_report_${dayKey(now)}.pdf', 'application/pdf', bytes);
  }
}
