import '../data/appointments_repo.dart';
import '../data/settings_repo.dart';
import '../data/tasks_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'prayers.dart';
import 'weather.dart';

/// بيبنى نص الموجز الصباحى (للقراءة الصوتية أو العرض) — جُمل قصيرة مناسبة
/// للـTTS: تحية + الصلاة الجاية + مواعيد النهارده + المهام المستحقة + الطقس.
/// طبقة core من غير ودجت عشان تتختبر.
Future<String> buildMorningBrief([DateTime? at]) async {
  final now = at ?? DateTime.now();
  final parts = <String>[];

  // التحية بالاسم.
  final name = await SettingsRepo().userName();
  parts.add(name.isEmpty
      ? greetingFor(now)
      : tr('${greetingFor(now)} يا $name', '${greetingFor(now)}, $name'));

  // الصلاة الجاية.
  try {
    final gov = await resolvePlace(SettingsRepo());
    final times = prayerTimesFor(now, gov);
    final next = times.nextIndex(now);
    if (next != null) {
      parts.add(tr(
          'صلاة ${prayerNameLabel(next)} الساعة ${arTime(times.times[next])}.',
          '${prayerNameLabel(next)} prayer at ${arTime(times.times[next])}.'));
    }
  } on Exception catch (_) {
    // من غير موقع متظبّط — نكمل من غير سطر الصلاة.
  }

  // مواعيد النهارده.
  final appts = await AppointmentsRepo().forDay(now);
  if (appts.isEmpty) {
    parts.add(tr('مفيش مواعيد النهارده.', 'No appointments today.'));
  } else if (appts.length == 1) {
    parts.add(tr(
        'عندك موعد واحد: ${appts.first.title} الساعة ${arTime(appts.first.when)}.',
        'One appointment: ${appts.first.title} at ${arTime(appts.first.when)}.'));
  } else {
    parts.add(tr(
        'عندك ${arNum(appts.length)} مواعيد، أولها ${appts.first.title} الساعة ${arTime(appts.first.when)}.',
        '${arNum(appts.length)} appointments, first is ${appts.first.title} at ${arTime(appts.first.when)}.'));
  }

  // المهام المستحقة.
  final due = (await TasksRepo().dueTasks(now)).length;
  if (due > 0) {
    parts.add(tr('وعندك ${arNum(due)} مهمة مستحقة.',
        'And ${arNum(due)} tasks due.'));
  }

  // الطقس (كاش يومى، مجانى بدون مفتاح).
  try {
    final w = await WeatherService.today();
    if (w != null) parts.add(w.summaryLine());
  } on Exception catch (_) {
    // مفيش نت — نكمل من غيره.
  }

  parts.add(tr('يوم سعيد إن شاء الله.', 'Have a great day.'));
  return parts.join(' ');
}
