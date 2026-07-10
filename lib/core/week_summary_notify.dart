import '../data/settings_repo.dart';
import 'l10n.dart';
import 'notifications.dart';

/// إشعار «ملخص الأسبوع» — بيتجدول لأقرب جمعة الساعة ٨ مساءً، وبيتجدد مع كل
/// فتحة للتطبيق. بيبعت تنبيه بيفكّر المستخدم يفتح الشات ويقول «ملخص الأسبوع»
/// (بدل ما نحسب ملخص قديم دلوقتي — الأرقام بتتحسب لحظة ما يفتح).
class WeekSummaryScheduler {
  static Future<void> ensureScheduled() async {
    await Notifications.cancel(Notifications.weekSummaryNotifId);
    if (await SettingsRepo().get('week_summary_enabled') == '0') return;

    final now = DateTime.now();
    // الجمعة الجاية (Dart: friday = 5) الساعة ٨ مساءً.
    final days = (DateTime.friday - now.weekday) % 7;
    var when = DateTime(now.year, now.month, now.day + days, 20);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 7));

    await Notifications.scheduleOnce(
      id: Notifications.weekSummaryNotifId,
      title: tr('ملخص أسبوعك جاهز', 'Your week in review'),
      body: tr('افتح «اسأل مديرك» وقول «ملخص الأسبوع» تشوف أسبوعك في سطور.',
          'Open "Ask your manager" and say "week summary" to see your week.'),
      when: when,
    );
  }
}
