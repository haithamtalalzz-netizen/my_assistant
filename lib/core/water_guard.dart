import '../data/health_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

/// تذكير مياه ذكي: مش كل ساعتين زي التطبيقات المزعجة — تنبيهين بس،
/// وبيتلغوا تلقائيًا لو انت ماشي كويس. بيتعاد حسابهم مع كل تغيير للمياه.
class WaterGuard {
  static const int afternoonId = 920001;
  static const int eveningId = 920002;

  static Future<void> ensureScheduled() async {
    await Notifications.cancel(afternoonId);
    await Notifications.cancel(eveningId);

    final now = DateTime.now();
    final settings = SettingsRepo();
    final goal = await settings.waterGoal();
    final water = await HealthRepo().waterOn(dayKey(now));

    // العصر (٤م): لو لسه أقل من نص الهدف وقتها.
    final afternoon = DateTime(now.year, now.month, now.day, 16);
    if (afternoon.isAfter(now) && water < goal / 2) {
      await Notifications.scheduleOnce(
        id: afternoonId,
        title: tr('المياه يا معلم', 'Water time'),
        body: tr(
            'انت لسه في ${arNum(water)} من ${arNum(goal)} — اشرب كوباية دلوقتي',
            "You're at ${arNum(water)} of ${arNum(goal)} — drink a cup now"),
        when: afternoon,
      );
    }

    // بليل (٨م): لو لسه بعيد عن الهدف.
    final evening = DateTime(now.year, now.month, now.day, 20);
    if (evening.isAfter(now) && water < goal * 0.8) {
      final remaining = goal - water;
      await Notifications.scheduleOnce(
        id: eveningId,
        title: tr('آخر فرصة لهدف المياه', 'Last chance for your water goal'),
        body: tr('فاضل ${arNum(remaining)} كوبايات على هدف النهارده',
            '${arNum(remaining)} cups left to reach today\'s goal'),
        when: evening,
      );
    }
  }
}
