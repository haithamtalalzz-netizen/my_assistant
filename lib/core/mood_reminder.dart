// تذكير المزاج — تسجّل من الإشعار نفسه، من غير ما تفتح التطبيق.
//
// ليه ده يستاهل: تتبّع المزاج بيموت لإن تسجيله بيتكلّف أكتر مما بيدّى —
// تفتح، تدوّر على البند، تدوس. لو الدوسة بقت فى الإشعار اللى قدامك،
// التكلفة بقت صفر، والمنحنى اللى بعد شهر هو الفايدة كلها.
//
// **ليه تلات وشوش مش خمسة؟** أندرويد بيعرض ٣ أزرار على الأكثر فى
// الإشعار. فالتلاتة بياخدوا الطرفين والنُص (١ · ٣ · ٥)، ولو مزاجك بين
// بين تدوس على الإشعار نفسه وتختار من الخمسة جوّه الشاشة.
//
// مفاتيح الإعدادات: `mood_reminder` (1/0، **مقفول افتراضيًا** — تنبيه
// جديد مايفتحش نفسه) · `mood_reminder_time` (HH:mm، الافتراضى ٢١:٠٠).
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/mood_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

class MoodReminder {
  static const int notifId = 940002;
  static const String enabledKey = 'mood_reminder';
  static const String timeKey = 'mood_reminder_time';
  static const int defaultHour = 21;
  static const int defaultMinute = 0;

  /// الوشوش اللى بتظهر فى الإشعار: (الدرجة، الزرار).
  ///
  /// الدرجة جوّه الـactionId عشان المعالج الخلفى يقراها من غير جدول
  /// ترجمة تانى يقدر يختلف عن ده.
  static const List<(int, String)> faces = [
    (1, '😞'),
    (3, '😐'),
    (5, '😄'),
  ];

  static String actionId(int score) => 'mood_$score';

  /// بيطلّع الدرجة من اسم الزرار، أو null لو مش زرار مزاج.
  static int? scoreOfAction(String action) {
    if (!action.startsWith('mood_')) return null;
    final n = int.tryParse(action.substring(5));
    return n == null || n < 1 || n > 5 ? null : n;
  }

  static List<AndroidNotificationAction> get actions => [
        for (final (score, face) in faces)
          AndroidNotificationAction(actionId(score), face,
              showsUserInterface: false, cancelNotification: true),
      ];

  /// مقفول لحد ما يفتحه — مش زى «يومك الصبح» اللى مفتوح افتراضيًا،
  /// لإن ده بيزنّ كل يوم على حاجة محدش طلبها.
  static Future<bool> isEnabled([SettingsRepo? repo]) async =>
      await (repo ?? SettingsRepo()).get(enabledKey) == '1';

  /// ميعاد التذكير المحفوظ (ساعة، دقيقة).
  static Future<(int, int)> timeOf([SettingsRepo? repo]) async {
    final raw = await (repo ?? SettingsRepo()).get(timeKey) ?? '';
    final parts = toEnglishDigits(raw).split(':');
    final h = int.tryParse(parts.isEmpty ? '' : parts[0]) ?? defaultHour;
    final m =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? defaultMinute) : defaultMinute;
    return (h.clamp(0, 23), m.clamp(0, 59));
  }

  /// بيجدول تذكير يومى بالوشوش.
  ///
  /// بيتنادى عند فتح التطبيق وبعد أى تغيير فى الإعداد.
  static Future<void> reschedule() async {
    await Notifications.cancel(notifId);
    final settings = SettingsRepo();
    if (!await isEnabled(settings)) return;
    final (hour, minute) = await timeOf(settings);
    await Notifications.scheduleDaily(
      id: notifId,
      // العنوان بيقول الحاجة لوحده — على شاشة ساعة مش هيبان غيره.
      title: tr('مزاجك النهارده إيه؟', 'How was your day?'),
      body: tr('دوس على وش — أو افتح واختار من الخمسة',
          'Tap a face — or open for all five'),
      hour: hour,
      minute: minute,
      payload: 'mood',
      actions: actions,
    );
  }

  /// بينفّذ دوسة وش من الإشعار. بيرجّع true لو اتسجّل.
  ///
  /// **مابيدوسش على مزاج اتسجّل قبل كده بملاحظته**: لو كتبت ملاحظة
  /// الصبح، دوسة الوش بالليل بتغيّر الدرجة وتسيب الملاحظة.
  static Future<bool> applyAction(String action) async {
    final score = scoreOfAction(action);
    if (score == null) return false;
    final repo = MoodRepo();
    final today = await repo.forDay(dayKey(DateTime.now()));
    await repo.setToday(score, note: today?.note ?? '');
    return true;
  }
}
