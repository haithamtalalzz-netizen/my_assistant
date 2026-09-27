import '../data/appointments_repo.dart';
import '../data/meds_repo.dart';
import '../data/settings_repo.dart';
import '../data/tasks_repo.dart';
import '../data/worship_repo.dart';
import 'ar.dart';
import 'day_timeline.dart';
import 'l10n.dart';
import 'log.dart';
import 'notifications.dart';
import 'prayers.dart';

/// **إشعار «يومك» الصبح** — إشعار واحد بيقولك أول حاجة قدامك وكام بند
/// عندك النهارده، من غير ما تفتح التطبيق.
///
/// مبنى فوق [buildDayTimeline]، فنفس اللى بيظهر فى الرئيسية بالظبط —
/// مافيش حساب تانى ممكن يختلف عنه.
///
/// مفاتيح الإعدادات: `morning_digest` (1/0، **مفعّل افتراضيًا**) ·
/// `morning_digest_time` (HH:mm، الافتراضى 07:00).
class MorningDigest {
  static const int notifId = 940001;
  static const String enabledKey = 'morning_digest';
  static const String timeKey = 'morning_digest_time';
  static const int defaultHour = 7;
  static const int defaultMinute = 0;

  static Future<bool> isEnabled([SettingsRepo? repo]) async {
    final v = await (repo ?? SettingsRepo()).get(enabledKey);
    // مفيش قيمة = مفعّل (الميزة مفيدة من غير ما يدوّر عليها).
    return v == null || v.trim().isEmpty || v == '1';
  }

  /// بيبنى نصّ الإشعار من بنود النهارده.
  ///
  /// دالة **نقية** عشان تتختبر: بتاخد الخط والوقت وبترجّع العنوان والنص،
  /// أو null لو اليوم فاضى (مانزنّش على المستخدم من غير داعى).
  static ({String title, String body})? compose(
      List<TimelineEvent> timeline, DateTime now) {
    if (timeline.isEmpty) return null;
    final next = nextDayEvent(timeline, now);
    final pending = timeline.where((e) => !e.done).length;
    if (pending == 0) return null;

    final title = tr('يومك النهارده', 'Your day');
    if (next == null) {
      return (
        title: title,
        body: tr('عندك ${arNum(pending)} بند لسه مخلصوش',
            '${arNum(pending)} items still open'),
      );
    }
    final rest = pending - 1;
    final first = tr('أول حاجة: ${next.title} ${next.timeLabel}',
        'First up: ${next.title} at ${next.timeLabel}');
    final body = rest <= 0
        ? first
        : tr('$first — وبعدها ${arNum(rest)} بنود',
            '$first — then ${arNum(rest)} more');
    return (title: title, body: body);
  }

  /// بيجدول إشعار بكرة الصبح (أو النهارده لو الميعاد لسه ماجاش).
  ///
  /// بيتنادى عند فتح التطبيق وبعد أى تغيير فى الإعداد. الإشعار **يومى
  /// متكرر**، والنص بيتحدّث كل مرة التطبيق يتفتح — ودى حدّ معروف: لو
  /// التطبيق مافتحش لأيام، النص بيفضل بتاع آخر مرة اتحدّث فيها.
  static Future<void> reschedule({DateTime? now}) async {
    await Notifications.cancel(notifId);
    final settings = SettingsRepo();
    if (!await isEnabled(settings)) return;

    final at = now ?? DateTime.now();
    final raw = await settings.get(timeKey) ?? '';
    final parts = toEnglishDigits(raw).split(':');
    final hour = int.tryParse(parts.isEmpty ? '' : parts[0]) ?? defaultHour;
    final minute =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? defaultMinute) : defaultMinute;

    final text = await _composeForToday(at);
    await Notifications.scheduleDaily(
      id: notifId,
      title: text?.title ?? tr('يومك النهارده', 'Your day'),
      body: text?.body ??
          tr('افتح التطبيق وشوف اللى قدامك', 'Open the app to see your day'),
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
      payload: 'morning_digest',
    );
  }

  /// بيلمّ بنود النهارده ويركّب النص (بيبلع أى فشل — الإشعار مش أهم من
  /// إن التطبيق يفتح).
  static Future<({String title, String body})?> _composeForToday(
      DateTime now) async {
    try {
      final settings = SettingsRepo();
      List<DateTime> prayers = const [];
      Set<int> prayed = const {};
      try {
        final gov = await resolvePlace(settings);
        prayers = prayerTimesFor(now, gov).times;
        prayed = await WorshipRepo().prayedOn(now);
      } on Exception catch (e) {
        logError('مواقيت اليوم مش متاحة لإشعار الصبح', e);
      }
      final line = buildDayTimeline(
        now: now,
        prayers: prayers,
        prayedIdx: prayed,
        appointments: await AppointmentsRepo().forDay(now),
        meds: await MedsRepo().all(activeOnly: true),
        takenSlots: await MedsRepo().takenOn(dayKey(now)),
        tasks: await TasksRepo().dueTasks(now),
        maxPast: null,
      );
      return compose(line, now);
    } on Exception catch (e, st) {
      logError('فشل تركيب إشعار الصبح', e, st);
      return null;
    }
  }
}
