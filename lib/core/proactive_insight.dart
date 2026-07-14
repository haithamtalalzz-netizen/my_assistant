import '../data/insights_repo.dart';
import '../data/settings_repo.dart';
import 'insights.dart';
import 'l10n.dart';
import 'notifications.dart';

/// رؤية استباقية يومية: إشعار الصبح «مديرك لاحظ إن…» بأقوى رؤية من محرّك
/// التحليلات — بيتحسب المحتوى وقت الجدولة من بيانات المستخدم الفعلية،
/// وبيتجدول كل فتحة للتطبيق زي باقى المجدولات. محلى بالكامل (مفيش سحابة).
class ProactiveInsight {
  /// ساعة الإرسال الافتراضية (٨:٣٠ صباحاً).
  static const int _hour = 8;
  static const int _minute = 30;

  static Future<void> ensureScheduled() async {
    await Notifications.cancel(Notifications.proactiveNotifId);
    final settings = SettingsRepo();
    if (!await settings.proactiveInsightEnabled()) return;

    // نبنى الرؤى ونختار الأقوى (buildInsights مرتّبة تنازلياً بالوزن).
    final data = await InsightsRepo().assemble();
    final insights = buildInsights(data);
    if (insights.isEmpty) return;
    final top = insights.first;

    // نجدول لصبح النهاردة لو لسه الوقت ماجاش، وإلا لصبح بكرة.
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, _hour, _minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await Notifications.scheduleOnce(
      id: Notifications.proactiveNotifId,
      title: tr('مديرك لاحظ إن…', 'Your manager noticed…'),
      body: top.text,
      when: when,
    );
  }
}
