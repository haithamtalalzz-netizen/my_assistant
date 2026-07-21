import '../models/models.dart';
import 'prayers.dart';

/// نوع البند فى الخط الزمنى — بيحدّد الأيقونة والتصرّف عند الضغط.
enum DayEventKind { prayer, appointment, med, meal, habit }

/// حالة البند بالنسبة للحظة الحالية.
enum DayEventWhen { past, now, upcoming, anytime }

/// بند واحد فى يوم المستخدم.
///
/// مقصود إنه **بيانات صافية** (مفيهوش أى ودجت) عشان يتبنى ويتترتّب ويتّاخد
/// عليه اختبارات من غير Flutter — الشاشة بس اللى بترسمه.
class DayEvent {
  /// وقت البند — null يعنى «أى وقت النهاردة» (زى العادات).
  final DateTime? at;
  final String title;
  final String subtitle;
  final String emoji;
  final DayEventKind kind;
  final bool done;

  /// مفتاح التصرّف: رقم الصلاة، أو id الموعد/العادة، أو «medId|slot».
  final String actionKey;

  const DayEvent({
    required this.at,
    required this.title,
    required this.kind,
    required this.actionKey,
    this.subtitle = '',
    this.emoji = '•',
    this.done = false,
  });

  DayEventWhen whenRelativeTo(DateTime now) {
    if (at == null) return DayEventWhen.anytime;
    final diff = at!.difference(now).inMinutes;
    // «دلوقتى» = نص ساعة قبل البند لحد نص ساعة بعده.
    if (diff.abs() <= 30) return DayEventWhen.now;
    return diff < 0 ? DayEventWhen.past : DayEventWhen.upcoming;
  }
}

/// الساعة التقريبية لكل وجبة — الوجبات متخزّنة بالاسم مش بالوقت،
/// فمحتاجين وقت افتراضى عشان نرتّبها وسط باقى اليوم.
const Map<String, int> kMealNominalHour = {
  'سحور': 3,
  'فطار': 8,
  'سناك': 11,
  'غدا': 14,
  'عشا': 20,
};

int _mealHour(String slot) => kMealNominalHour[slot] ?? 12;

DateTime? _slotTime(DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}

/// بيبنى يوم المستخدم كقايمة واحدة مرتّبة بالوقت.
///
/// ليه ده موجود: الرئيسية القديمة كانت بتعرض المواعيد والأدوية والوجبات فى
/// كروت منفصلة، والبند الواحد كان بيتكرّر برضه فى «محتاج منك دلوقتي».
/// هنا كل حاجة بتتحط مرة واحدة فى مكانها الزمنى الصح.
///
/// البنود اللى ملهاش وقت (العادات) بتتحط فى الآخر كمجموعة «أى وقت النهاردة».
List<DayEvent> buildDayTimeline({
  required DateTime now,
  PrayerDay? prayers,
  Set<int> prayedIndexes = const {},
  List<Appointment> appointments = const [],
  List<Medication> medications = const [],
  Set<String> takenMeds = const {},
  List<Meal> meals = const [],
  List<Habit> habits = const [],
  Set<int> doneHabits = const {},
  bool includePrayers = true,
  bool includeHabits = true,
  /// تسمية فئة الموعد — بتتبعت من الشاشة عشان الملف ده يفضل من غير
  /// أى اعتماد على واجهة المستخدم.
  String Function(String category)? apptLabel,
}) {
  final out = <DayEvent>[];
  final day = DateTime(now.year, now.month, now.day);

  if (includePrayers && prayers != null) {
    for (var i = 0; i < prayers.times.length; i++) {
      out.add(DayEvent(
        at: prayers.times[i],
        title: prayerNameLabel(i),
        kind: DayEventKind.prayer,
        actionKey: '$i',
        emoji: '🕌',
        done: prayedIndexes.contains(i),
      ));
    }
  }

  for (final a in appointments) {
    out.add(DayEvent(
      at: a.when,
      title: a.title,
      subtitle: apptLabel?.call(a.category) ?? a.category,
      kind: DayEventKind.appointment,
      actionKey: '${a.id}',
      emoji: '📅',
      done: a.done,
    ));
  }

  for (final m in medications) {
    for (final slot in m.times) {
      final at = _slotTime(day, slot);
      if (at == null) continue;
      out.add(DayEvent(
        at: at,
        title: m.name,
        subtitle: m.dosage,
        kind: DayEventKind.med,
        actionKey: '${m.id}|$slot',
        emoji: '💊',
        done: takenMeds.contains('${m.id}|$slot'),
      ));
    }
  }

  for (final meal in meals) {
    out.add(DayEvent(
      at: DateTime(day.year, day.month, day.day, _mealHour(meal.slot)),
      title: meal.slot,
      subtitle: meal.description,
      kind: DayEventKind.meal,
      actionKey: '${meal.id}',
      emoji: '🍽',
      done: true, // الوجبة اتسجّلت يعنى اتاكلت
    ));
  }

  // ترتيب زمنى — البنود بدون وقت بتتأجّل للآخر.
  out.sort((a, b) {
    if (a.at == null && b.at == null) return 0;
    if (a.at == null) return 1;
    if (b.at == null) return -1;
    return a.at!.compareTo(b.at!);
  });

  if (includeHabits) {
    for (final h in habits) {
      out.add(DayEvent(
        at: null,
        title: h.name,
        kind: DayEventKind.habit,
        actionKey: '${h.id}',
        emoji: '🔁',
        done: doneHabits.contains(h.id),
      ));
    }
  }

  return out;
}

/// أقرب بند لسه ماخلصش — ده اللى الشاشة بتبرزه كـ«اللى جاى دلوقتى».
DayEvent? nextPendingEvent(List<DayEvent> events, DateTime now) {
  for (final e in events) {
    if (e.done || e.at == null) continue;
    if (!e.at!.isBefore(now)) return e;
  }
  return null;
}
