import '../data/settings_repo.dart';
import 'l10n.dart';
import 'notifications.dart';

/// يفكّ «HH:mm» لساعة ودقيقة (مع افتراضى عند الغياب/التلف).
(int, int) parseHm(String? s, {int defH = 0, int defM = 0}) {
  if (s == null || s.trim().isEmpty) return (defH, defM);
  final parts = s.trim().split(':');
  final h = int.tryParse(parts[0]) ?? defH;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? defM) : defM;
  return (h.clamp(0, 23), m.clamp(0, 59));
}

/// تذكير أذكار الصباح والمساء — تنبيهين يوميين متكررين في الأوقات اللى يختارها
/// المستخدم. بيتعاد جدولتهم عند فتح التطبيق وعند تغيير الإعداد.
/// مفاتيح الإعدادات: `adhkar_reminders` (1/0) · `adhkar_morning_time` (HH:mm)
/// · `adhkar_evening_time` (HH:mm).
class AdhkarReminders {
  static const int morningId = 930001;
  static const int eveningId = 930002;

  static Future<void> reschedule() async {
    await Notifications.cancel(morningId);
    await Notifications.cancel(eveningId);
    final s = SettingsRepo();
    if ((await s.get('adhkar_reminders')) != '1') return;
    final (mh, mm) =
        parseHm(await s.get('adhkar_morning_time'), defH: 6, defM: 30);
    final (eh, em) =
        parseHm(await s.get('adhkar_evening_time'), defH: 17, defM: 0);
    await Notifications.scheduleDaily(
      id: morningId,
      title: tr('أذكار الصباح 🌅', 'Morning adhkar 🌅'),
      body: tr('ابدأ يومك بأذكار الصباح', 'Start your day with morning adhkar'),
      hour: mh,
      minute: mm,
      payload: 'adhkar_m',
    );
    await Notifications.scheduleDaily(
      id: eveningId,
      title: tr('أذكار المساء 🌆', 'Evening adhkar 🌆'),
      body: tr('لا تنسَ أذكار المساء', "Don't forget your evening adhkar"),
      hour: eh,
      minute: em,
      payload: 'adhkar_e',
    );
  }
}
