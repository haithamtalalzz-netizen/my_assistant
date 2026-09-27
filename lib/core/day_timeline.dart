import '../models/models.dart';
import 'ar.dart';
import 'l10n.dart';
import 'prayers.dart';

/// نوع البند فى خط اليوم — بيحدد الأيقونة واللون فى الواجهة.
enum TimelineKind { prayer, appointment, med, task }

/// بند واحد فى خط اليوم.
class TimelineEvent {
  final DateTime at;
  final String title;
  final String sub;
  final TimelineKind kind;
  final bool done;

  /// رقم السجل (موعد/دوا/مهمة) — عشان الضغط يفتح الحاجة الصح.
  final int? id;

  /// جرعة الدوا (للأدوية بس).
  final String? slot;

  const TimelineEvent({
    required this.at,
    required this.title,
    required this.kind,
    this.sub = '',
    this.done = false,
    this.id,
    this.slot,
  });

  String get timeLabel => arTime(at);
}

/// بيركّب **خط اليوم**: صلوات · مواعيد · جرعات · مهام بميعاد — مرتّبين
/// بالوقت.
///
/// دالة **نقية**: بتاخد بيانات محمّلة بالفعل (الرئيسية بتحمّلها أصلاً)
/// ومابتعملش أى استعلام — فتتختبر من غير قاعدة بيانات ولا وقت حقيقى.
///
/// - [prayers]: مواقيت النهارده الخمسة بالترتيب (فجر…عشاء).
/// - [prayedIdx]: أرقام الصلوات اللى اتصلّت (0..4).
/// - [takenSlots]: مفاتيح الجرعات المتاخدة بصيغة `'<medId>|<slot>'` —
///   نفس الصيغة اللى الرئيسية بتستخدمها.
/// - [maxPast]: أقصى عدد بنود **فاتت** تفضل ظاهرة (الباقى بيتشال عشان
///   الخط مايبقاش كله ماضى). null = خليهم كلهم.
List<TimelineEvent> buildDayTimeline({
  required DateTime now,
  List<DateTime> prayers = const [],
  Set<int> prayedIdx = const {},
  List<Appointment> appointments = const [],
  List<Medication> meds = const [],
  Set<String> takenSlots = const {},
  List<Task> tasks = const [],
  int? maxPast = 2,
}) {
  final today = dateOnly(now);
  bool isToday(DateTime d) => dateOnly(d) == today;

  final out = <TimelineEvent>[];

  for (var i = 0; i < prayers.length && i < kPrayerNames.length; i++) {
    out.add(TimelineEvent(
      at: prayers[i],
      title: kPrayerNames[i],
      sub: prayedIdx.contains(i) ? tr('اتصلّت', 'Prayed') : '',
      kind: TimelineKind.prayer,
      done: prayedIdx.contains(i),
      id: i,
    ));
  }

  for (final a in appointments) {
    if (!isToday(a.when)) continue;
    out.add(TimelineEvent(
      at: a.when,
      title: a.title,
      sub: a.location.isNotEmpty ? a.location : a.category,
      kind: TimelineKind.appointment,
      done: a.done,
      id: a.id,
    ));
  }

  for (final m in meds) {
    for (final slot in m.times) {
      final at = _slotTime(today, slot);
      if (at == null) continue;
      final taken = takenSlots.contains('${m.id}|$slot');
      out.add(TimelineEvent(
        at: at,
        title: m.name,
        sub: m.dosage.isNotEmpty ? m.dosage : tr('جرعة', 'Dose'),
        kind: TimelineKind.med,
        done: taken,
        id: m.id,
        slot: slot,
      ));
    }
  }

  for (final t in tasks) {
    final due = t.dueAt == null ? null : DateTime.tryParse(t.dueAt!);
    // مهمة من غير ميعاد ملهاش مكان على خط زمنى.
    if (due == null || !isToday(due)) continue;
    out.add(TimelineEvent(
      at: due,
      title: t.title,
      sub: tr('مهمة', 'Task'),
      kind: TimelineKind.task,
      done: t.done,
      id: t.id,
    ));
  }

  out.sort((a, b) => a.at.compareTo(b.at));
  if (maxPast == null) return out;

  // بنسيب آخر [maxPast] بند فات بس — الباقى ماضى مايفيدش.
  final past = [for (final e in out) if (e.at.isBefore(now)) e];
  if (past.length <= maxPast) return out;
  final drop = past.take(past.length - maxPast).toSet();
  return [for (final e in out) if (!drop.contains(e)) e];
}

/// أول بند **لسه ما خلصش** بعد [now] — ده اللى بيتعرض فى البطل.
/// لو كل حاجة خلصت بيرجّع null.
TimelineEvent? nextDayEvent(List<TimelineEvent> events, DateTime now) {
  for (final e in events) {
    if (!e.done && !e.at.isBefore(now)) return e;
  }
  return null;
}

/// أول بند **فات ميعاده ولسه ما اتعملش** — لو مفيش حاجة جاية، ده اللى
/// يتعرض («فاتك كذا») بدل ما البطل يفضل فاضى.
TimelineEvent? overdueDayEvent(List<TimelineEvent> events, DateTime now) {
  for (final e in events) {
    if (!e.done && e.at.isBefore(now)) return e;
  }
  return null;
}

/// كام بند خلص من إجمالى بنود اليوم.
({int done, int total}) dayTimelineProgress(List<TimelineEvent> events) =>
    (done: events.where((e) => e.done).length, total: events.length);

/// بيحوّل جرعة مكتوبة («08:00» أو «8:00») لوقت فى اليوم ده.
DateTime? _slotTime(DateTime day, String slot) {
  final parts = toEnglishDigits(slot).split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0].trim());
  final m = int.tryParse(parts[1].trim());
  if (h == null || m == null) return null;
  return DateTime(day.year, day.month, day.day, h, m);
}
