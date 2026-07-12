import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_actions.dart';

/// غلاف موحد للإشعارات المحلية: مواعيد (مرة واحدة)، أدوية (يومي متكرر)،
/// مستندات (مرة واحدة قبل الانتهاء). لو التهيئة فشلت كل النداءات تبقى no-op.
class Notifications {
  Notifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  // نطاقات ثابتة لمعرفات الإشعارات عشان مايحصلش تصادم بين الوحدات.
  static int apptNotifId(int id) => 100000 + id;
  static int medNotifId(int id, int slot) => 200000 + id * 10 + slot;
  static int docNotifId(int id) => 300000 + id;
  static int prayerNotifId(int dayIndex, int prayerIndex) =>
      400000 + dayIndex * 10 + prayerIndex;
  static int workoutNotifId(int weekday) => 500000 + weekday;
  static int occasionNotifId(int id) => 600000 + id;
  static const int eveningNotifId = 700001;
  static int planNotifId(int index) => 800000 + index;
  static int billNotifId(int id) => 900000 + id;
  static const int streakNotifId = 910001;
  static int debtNotifId(int id) => 950000 + id;
  static int gameyaNotifId(int id) => 960000 + id;
  static int homeMaintNotifId(int id) => 970000 + id;
  static int incomeNotifId(int id) => 980000 + id;
  static int pharmacyNotifId(int id) => 990000 + id;
  static int warrantyNotifId(int id) => 1000000 + id;
  static int meterNotifId(int typeIndex) => 1010000 + typeIndex;
  static const int quranNotifId = 1020001;
  static int relativeNotifId(int id) => 1030000 + id;
  static int capsuleNotifId(int id) => 1040000 + id;
  static int leaveNotifId(int id) => 1050000 + id;
  static int plantNotifId(int id) => 1060000 + id;
  static const int weekSummaryNotifId = 1070001;
  static const int cyclePeriodNotifId = 1080001; // تذكير قبل الدورة
  static const int cycleFertileNotifId = 1080002; // بداية أيام الخصوبة
  static const int cycleLateNotifId = 1080003; // تأخّر الدورة
  static const int cycleCareNotifId = 1080004; // عناية أثناء الدورة
  static const int pillNotifId = 1090001; // حبوب منع الحمل اليومية
  static const int fridayNotifId = 1100001; // تذكير الجمعة (الكهف + الصلاة على النبى)
  static const int adhanTestNotifId = 1100002; // تجربة صوت الأذان

  /// تفاصيل إشعار الأذان — صوت من res/raw أو ملف مخصّص (content:// URI).
  /// لكل صوت قناة منفصلة لأن صوت القناة مابيتغيّرش بعد إنشائها.
  static NotificationDetails _adhanDetailsFor(
      {required String channelId, required AndroidNotificationSound sound}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'أذان الصلاة',
          channelDescription: 'أذان صوتى عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: sound,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  /// يبنى تفاصيل الأذان من إعداد الصوت (raw من الحزمة أو uri مخصّص).
  static NotificationDetails? _adhanDetails(
      {String? raw, String? uri, String? channel}) {
    if (uri != null && uri.isNotEmpty) {
      return _adhanDetailsFor(
          channelId: channel ?? 'prayer_adhan_custom',
          sound: UriAndroidNotificationSound(uri));
    }
    if (raw != null && raw.isNotEmpty) {
      return _adhanDetailsFor(
          channelId: 'prayer_adhan_$raw',
          sound: RawResourceAndroidNotificationSound(raw));
    }
    return null;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'my_assistant_main',
      'تنبيهات المساعد',
      channelDescription: 'تذكيرات المواعيد والأدوية والمستندات',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// نفس القناة لكن بأزرار أفعال («اتاخد ✓» / «تم» / «اتدفعت»).
  static NotificationDetails _detailsWith(
      List<AndroidNotificationAction>? actions) {
    if (actions == null || actions.isEmpty) return _details;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'my_assistant_main',
        'تنبيهات المساعد',
        channelDescription: 'تذكيرات المواعيد والأدوية والمستندات',
        importance: Importance.max,
        priority: Priority.high,
        actions: actions,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<void> init(
      {void Function(NotificationResponse)? onResponse}) async {
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } on Exception catch (e) {
        dev.log('فشل تحديد المنطقة الزمنية، هنستخدم القاهرة', error: e);
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      }
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: onResponse,
        onDidReceiveBackgroundNotificationResponse:
            onResponse == null ? null : notificationBackgroundHandler,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      _ready = true;
    } on Exception catch (e, st) {
      dev.log('فشلت تهيئة الإشعارات — التطبيق هيكمل من غيرها',
          error: e, stackTrace: st);
    }
  }

  static Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    List<AndroidNotificationAction>? actions,
    String? adhanRaw,
    String? adhanUri,
    String? adhanChannel,
  }) async {
    if (!_ready) return;
    if (when.isBefore(DateTime.now())) return;
    final at = tz.TZDateTime.from(when, tz.local);
    final details =
        _adhanDetails(raw: adhanRaw, uri: adhanUri, channel: adhanChannel) ??
            _detailsWith(actions);
    try {
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      dev.log('فشل التنبيه الدقيق #$id — هنجرب غير دقيق', error: e);
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    final details = _detailsWith(actions);
    try {
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time);
    } on PlatformException catch (e) {
      dev.log('فشل التنبيه اليومي الدقيق #$id — هنجرب غير دقيق', error: e);
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time);
    }
  }

  /// تكرار شهري في يوم [dayOfMonth] — للفواتير الدورية.
  static Future<void> scheduleMonthly({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth,
    required int hour,
    required int minute,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
        tz.local, now.year, now.month, dayOfMonth, hour, minute);
    while (at.isBefore(now)) {
      at = tz.TZDateTime(tz.local, at.year, at.month + 1, dayOfMonth, hour, minute);
    }
    final details = _detailsWith(actions);
    try {
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime);
    } on PlatformException catch (e) {
      dev.log('فشل التنبيه الشهري الدقيق #$id — هنجرب غير دقيق', error: e);
      await _plugin.zonedSchedule(id, title, body, at, details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime);
    }
  }

  /// تكرار أسبوعي: كل يوم [weekday] (بترقيم Dart: 1=الإثنين .. 7=الأحد).
  static Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (at.weekday != weekday || at.isBefore(now)) {
      at = at.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(id, title, body, at, _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
    } on PlatformException catch (e) {
      dev.log('فشل التنبيه الأسبوعي الدقيق #$id — هنجرب غير دقيق', error: e);
      await _plugin.zonedSchedule(id, title, body, at, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
    }
  }

  /// تجربة صوت أذان فورًا (raw من الحزمة أو uri مخصّص).
  static Future<void> showAdhanTest(
      {String? raw, String? uri, String? channel}) async {
    if (!_ready) return;
    final details = _adhanDetails(raw: raw, uri: uri, channel: channel);
    if (details == null) return;
    await _plugin.show(
        adhanTestNotifId, 'أذان (تجربة)', 'صوت الأذان شغّال ✓', details);
  }

  /// إشعار فوري (مش مجدول).
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(id, title, body, _details);
  }

  static Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// يضبط صوت/اهتزاز القناة حسب الوضع: 'sound' / 'vibration' / 'both'.
  /// (على أندرويد 8+ القناة هي اللي بتتحكم؛ فبنعيد إنشاءها.)
  static Future<void> applyChannelMode(String mode) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final sound = mode == 'both' || mode == 'sound';
    final vibrate = mode == 'both' || mode == 'vibration';
    try {
      await android.deleteNotificationChannel('my_assistant_main');
      await android.createNotificationChannel(AndroidNotificationChannel(
        'my_assistant_main',
        'تنبيهات المساعد',
        description: 'تذكيرات المواعيد والأدوية والمستندات',
        importance: Importance.max,
        playSound: sound,
        enableVibration: vibrate,
      ));
    } on Exception catch (e) {
      dev.log('فشل ضبط قناة الإشعارات', error: e);
    }
  }
}
