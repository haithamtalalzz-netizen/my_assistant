// «رتبلي يومي» — مجدول محلي بالقواعد: ياخد الثوابت (مواعيد/صلوات/تمرين)
// ويوزع المعلق (مواعيد فايتة + عادات) على الفراغات. ملف نقي قابل للاختبار.

import 'l10n.dart';

enum PlanKind { appointment, prayer, workout, overdue, habit }

class PlanItem {
  final DateTime start;
  final DateTime end;
  final String title;
  final PlanKind kind;

  const PlanItem({
    required this.start,
    required this.end,
    required this.title,
    required this.kind,
  });
}

class PlanInput {
  final DateTime now;

  /// نهاية اليوم المخطط (مثلًا ١٠:٣٠ مساءً).
  final DateTime dayEnd;

  /// مواعيد اليوم الجاية: وقت + عنوان.
  final List<(DateTime, String)> appointments;

  /// أوقات الصلاة الجاية النهارده.
  final List<(DateTime, String)> prayers;

  /// تمرين النهارده (لو مخطط ولسه ماتعملش): وقته المفضل + اسمه.
  final (DateTime, String)? workout;

  /// عناوين مواعيد فايتة محتاجة قرار.
  final List<String> overdue;

  /// عادات لسه ماتعملتش النهارده.
  final List<String> pendingHabits;

  const PlanInput({
    required this.now,
    required this.dayEnd,
    this.appointments = const [],
    this.prayers = const [],
    this.workout,
    this.overdue = const [],
    this.pendingHabits = const [],
  });
}

const _apptMinutes = 60;
const _prayerMinutes = 20;
const _workoutMinutes = 60;
const _overdueMinutes = 30;
const _habitMinutes = 20;
const _minGapMinutes = 25;

List<PlanItem> buildDayPlan(PlanInput input) {
  // ١) الثوابت.
  final fixed = <PlanItem>[];
  for (final (time, title) in input.appointments) {
    if (time.isAfter(input.now)) {
      fixed.add(PlanItem(
        start: time,
        end: time.add(const Duration(minutes: _apptMinutes)),
        title: title,
        kind: PlanKind.appointment,
      ));
    }
  }
  for (final (time, title) in input.prayers) {
    if (time.isAfter(input.now) && time.isBefore(input.dayEnd)) {
      fixed.add(PlanItem(
        start: time,
        end: time.add(const Duration(minutes: _prayerMinutes)),
        title: tr('صلاة $title', '$title prayer'),
        kind: PlanKind.prayer,
      ));
    }
  }
  if (input.workout != null) {
    final (preferred, title) = input.workout!;
    var start = preferred.isAfter(input.now) ? preferred : input.now;
    fixed.add(PlanItem(
      start: start,
      end: start.add(const Duration(minutes: _workoutMinutes)),
      title: tr('تمرين: $title', 'Workout: $title'),
      kind: PlanKind.workout,
    ));
  }
  fixed.sort((a, b) => a.start.compareTo(b.start));

  // ٢) قائمة الحشو: الفايت الأول وبعدين العادات.
  final queue = <(String, PlanKind, int)>[
    for (final t in input.overdue.take(3))
      (tr('إنهاء المؤجل: $t', 'Finish postponed: $t'), PlanKind.overdue,
          _overdueMinutes),
    for (final h in input.pendingHabits) (h, PlanKind.habit, _habitMinutes),
  ];

  // ٣) نمشي على الفراغات ونملأها.
  final result = <PlanItem>[...fixed];
  var cursor = input.now;
  final boundaries = [...fixed, PlanItem(
    start: input.dayEnd,
    end: input.dayEnd,
    title: '',
    kind: PlanKind.appointment,
  )];
  for (final block in boundaries) {
    while (queue.isNotEmpty) {
      final (title, kind, minutes) = queue.first;
      final gap = block.start.difference(cursor).inMinutes;
      if (gap < _minGapMinutes || gap < minutes) break;
      result.add(PlanItem(
        start: cursor,
        end: cursor.add(Duration(minutes: minutes)),
        title: title,
        kind: kind,
      ));
      cursor = cursor.add(Duration(minutes: minutes + 10));
      queue.removeAt(0);
    }
    if (block.end.isAfter(cursor)) cursor = block.end;
  }

  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}
