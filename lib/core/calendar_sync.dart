import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/models.dart';
import 'ar.dart';
import 'l10n.dart';

/// ربط أحداث التطبيق بتقويم الموبايل (أندرويد/آبل).
/// بيفتح شاشة «إضافة حدث» في تطبيق التقويم بالبيانات جاهزة — المستخدم يأكّد الحفظ.
///
/// مفيش مفتاح ولا حساب ولا إنترنت: الحزمة بتبعت نيّة (intent) لتطبيق
/// التقويم المتسطّب على الجهاز، فالتكلفة صفر والخصوصية محفوظة.
class CalendarSync {
  static Future<bool> addEvent({
    required String title,
    String description = '',
    String location = '',
    required DateTime start,
    DateTime? end,
    bool allDay = false,
    a2c.Recurrence? recurrence,
  }) async {
    if (kIsWeb) return false;
    final event = a2c.Event(
      title: title,
      description: description,
      location: location,
      startDate: start,
      endDate: end ?? start.add(const Duration(hours: 1)),
      allDay: allDay,
      recurrence: recurrence,
    );
    return a2c.Add2Calendar.addEvent2Cal(event);
  }

  // ————————————————————————————————————————————————————————————
  // حساب المواعيد — **دوال نقية** مفصولة عن نداء الإضافة، عشان تتجرّب.
  // (النداء نفسه بيفتح تطبيق التقويم فمينفعش يتجرّب فى الاختبارات.)
  // ————————————————————————————————————————————————————————————

  /// بدايات جرعات الدوا: ميعاد لكل وقت فى [m.times]، واللى عدّى النهاردة
  /// بيروح لبكرة. مرتّبة زى ترتيب المواعيد فى الدوا.
  static List<DateTime> doseStarts(Medication m, DateTime from) {
    final out = <DateTime>[];
    for (final t in m.times) {
      final parts = t.split(':');
      final h = int.tryParse(parts.first) ?? 8;
      final min = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      var start = DateTime(from.year, from.month, from.day, h, min);
      if (start.isBefore(from)) start = start.add(const Duration(days: 1));
      out.add(start);
    }
    return out;
  }

  /// أقرب استحقاق جاى لفاتورة شهرية: الشهر ده لو لسه ماعدّاش، وإلا الشهر
  /// الجاى. اليوم بيتحصر فى ١..٢٨ عشان فبراير مايضيّعش الفاتورة.
  static DateTime nextBillDue(int dayOfMonth, DateTime from) {
    final day = dayOfMonth.clamp(1, 28);
    final due = DateTime(from.year, from.month, day);
    return due.isBefore(DateTime(from.year, from.month, from.day))
        ? DateTime(from.year, from.month + 1, day)
        : due;
  }

  // ————————————————————————————————————————————————————————————
  // اختصارات لكل نوع — كل واحد بيحوّل بيانات التطبيق لحدث مفهوم.
  // ————————————————————————————————————————————————————————————

  /// **دوا**: حدث **يومى متكرّر** لكل ميعاد جرعة. لو الكورس له نهاية،
  /// التكرار بيقف عندها؛ ولو مفتوح بيفضل مستمر.
  ///
  /// بيرجّع عدد المواعيد اللى اتبعتت — الجرعات المتعددة بتفتح شاشة إضافة
  /// لكل ميعاد، فالمستخدم بيأكّد كل واحدة.
  static Future<int> addMedication(Medication m, {DateTime? from}) async {
    if (kIsWeb || m.times.isEmpty) return 0;
    final base = from ?? DateTime.now();
    final end = m.endDate == null ? null : DateTime.tryParse(m.endDate!);
    var sent = 0;
    for (final start in doseStarts(m, base)) {
      final ok = await addEvent(
        title: tr('دوا: ${m.name}', 'Medicine: ${m.name}'),
        description: [
          if (m.dosage.isNotEmpty) m.dosage,
          if (m.notes.isNotEmpty) m.notes,
        ].join(' — '),
        start: start,
        end: start.add(const Duration(minutes: 15)),
        recurrence: a2c.Recurrence(
          frequency: a2c.Frequency.daily,
          endDate: end,
        ),
      );
      if (ok) sent++;
    }
    return sent;
  }

  /// **فاتورة دورية**: حدث **شهرى** فى يوم الاستحقاق، طول اليوم.
  static Future<bool> addBill(RecurringBill b, {DateTime? from}) async {
    if (kIsWeb) return false;
    final now = from ?? DateTime.now();
    final day = b.dayOfMonth.clamp(1, 28);
    final due = nextBillDue(b.dayOfMonth, now);
    return addEvent(
      title: tr('فاتورة: ${b.name}', 'Bill: ${b.name}'),
      description: tr('${egp(b.amount)} — كل شهر يوم ${arNum(day)}',
          '${egp(b.amount)} — monthly on day ${arNum(day)}'),
      start: due,
      end: due,
      allDay: true,
      recurrence: a2c.Recurrence(frequency: a2c.Frequency.monthly),
    );
  }

  /// **مهمة**: حدث فى ميعاد التسليم. المهمة من غير ميعاد مالهاش مكان فى
  /// التقويم، فبترجّع false من غير ما تفتح حاجة.
  static Future<bool> addTask(Task t) async {
    if (kIsWeb) return false;
    final due = t.dueAt == null ? null : DateTime.tryParse(t.dueAt!);
    if (due == null) return false;
    // ميعاد من غير ساعة (تاريخ بس) = حدث طول اليوم.
    final allDay = due.hour == 0 && due.minute == 0;
    return addEvent(
      title: tr('مهمة: ${t.title}', 'Task: ${t.title}'),
      description: t.notes,
      start: due,
      end: allDay ? due : due.add(const Duration(minutes: 30)),
      allDay: allDay,
    );
  }
}
