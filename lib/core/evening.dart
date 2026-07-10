import '../data/appointments_repo.dart';
import '../data/settings_repo.dart';
import '../data/workout_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

/// وضع المساء: إشعار «ملخص بكرة» بيتجدول لليلة دي مع كل فتحة للتطبيق —
/// المحتوى بيتحسب وقت الجدولة من بيانات بكرة الفعلية.
class EveningScheduler {
  static Future<void> ensureScheduled() async {
    await Notifications.cancel(Notifications.eveningNotifId);
    final settings = SettingsRepo();
    if (!await settings.eveningSummaryEnabled()) return;

    final now = DateTime.now();
    final timeParts = (await settings.eveningTime()).split(':');
    final hour = int.tryParse(timeParts[0]) ?? 21;
    final minute =
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 30 : 30;
    final tonight = DateTime(now.year, now.month, now.day, hour, minute);
    if (tonight.isBefore(now)) return; // فات معاد الليلة — الفتحة الجاية تجدول

    final tomorrow = dateOnly(now).add(const Duration(days: 1));
    final parts = <String>[];

    final appts = await AppointmentsRepo().forDay(tomorrow);
    if (appts.isEmpty) {
      parts.add(tr('مفيش مواعيد بكرة.', 'No appointments tomorrow.'));
    } else {
      parts.add(appts.length == 1
          ? tr('بكرة: ${appts.first.title} الساعة ${arTime(appts.first.when)}.',
              'Tomorrow: ${appts.first.title} at ${arTime(appts.first.when)}.')
          : tr(
              'بكرة عندك ${arNum(appts.length)} مواعيد — أولها ${appts.first.title} ${arTime(appts.first.when)}.',
              'Tomorrow you have ${arNum(appts.length)} appointments — first is ${appts.first.title} at ${arTime(appts.first.when)}.'));
    }

    final plan = await WorkoutRepo().plan();
    final workout = plan[tomorrow.weekday];
    if (workout != null) {
      parts.add(tr('تمرين بكرة: $workout.', 'Workout tomorrow: $workout.'));
    }

    if (appts.isNotEmpty && appts.first.when.hour <= 10) {
      parts.add(tr('نام بدري الليلة.', 'Sleep early tonight.'));
    }

    await Notifications.scheduleOnce(
      id: Notifications.eveningNotifId,
      title: tr('ملخص بكرة', "Tomorrow's summary"),
      body: parts.join(' '),
      when: tonight,
    );
  }
}
