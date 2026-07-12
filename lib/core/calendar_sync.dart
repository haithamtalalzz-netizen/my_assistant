import 'package:add_2_calendar/add_2_calendar.dart' as a2c;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ربط أحداث التطبيق بتقويم الموبايل (أندرويد/آبل).
/// بيفتح شاشة «إضافة حدث» في تطبيق التقويم بالبيانات جاهزة — المستخدم يأكّد الحفظ.
class CalendarSync {
  static Future<bool> addEvent({
    required String title,
    String description = '',
    String location = '',
    required DateTime start,
    DateTime? end,
    bool allDay = false,
  }) async {
    if (kIsWeb) return false;
    final event = a2c.Event(
      title: title,
      description: description,
      location: location,
      startDate: start,
      endDate: end ?? start.add(const Duration(hours: 1)),
      allDay: allDay,
    );
    return a2c.Add2Calendar.addEvent2Cal(event);
  }
}
