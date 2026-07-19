import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/app_state.dart';
// على الويب: يظبط فاكتوري sqflite (IndexedDB)؛ على الموبايل: لا شيء.
import 'core/db_init_web.dart' if (dart.library.io) 'core/db_init_stub.dart';
import 'core/backup.dart';
import 'core/evening.dart';
import 'core/log.dart';
import 'core/proactive_insight.dart';
import 'core/notification_actions.dart';
import 'core/adhkar_reminders.dart';
import 'core/notifications.dart';
import 'core/prayers.dart';
import 'core/month_summary.dart';
import 'core/streak_guard.dart';
import 'core/water_guard.dart';
import 'core/week_summary_notify.dart';
import 'core/widget_bridge.dart';
import 'data/bills_repo.dart';
import 'data/gameya_repo.dart';
import 'data/income_repo.dart';
import 'data/capsule_repo.dart';
import 'data/cycle_repo.dart';
import 'data/meters_repo.dart';
import 'data/pharmacy_repo.dart';
import 'data/plants_repo.dart';
import 'data/tasks_repo.dart';
import 'data/subscriptions_repo.dart';
import 'data/cars_repo.dart';
import 'data/renewals_repo.dart';
import 'data/trips_repo.dart';
import 'data/pets_repo.dart';
import 'data/fasting_repo.dart';
import 'data/vaccinations_repo.dart';
import 'data/quran_repo.dart';
import 'data/relatives_repo.dart';
import 'data/settings_repo.dart';
import 'data/warranty_repo.dart';
import 'data/home_maintenance_repo.dart';
import 'data/meds_repo.dart';
import 'data/occasions_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // على الويب: أي خطأ بدء تشغيل يظهر على شاشة التشخيص بدل شاشة بيضا صامتة.
  if (kIsWeb) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      showStartupError(
          'FlutterError:\n${details.exceptionAsString()}\n\n${details.stack}');
    };
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      showStartupError('Uncaught:\n$error\n\n$stack');
      return true;
    };
  }
  try {
    await _startup();
  } catch (e, st) {
    if (kIsWeb) showStartupError('Startup:\n$e\n\n$st');
    rethrow;
  }
}

Future<void> _startup() async {
  // ملف اللوج الأول — السطور اللى قبل ما يجهز بتتجمّع فى الذاكرة وبتتكتب
  // بعدين، فبدايات التشغيل مابتضيعش.
  await AppLog.init();
  initDbFactory(); // على الويب: sqflite عبر IndexedDB.
  Intl.defaultLocale = 'ar';
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await AppState.load();
  if (!kIsWeb) {
    await Notifications.init(onResponse: notificationTapHandler);
    // صوت/اهتزاز الإشعارات حسب اختيار المستخدم.
    await Notifications.applyChannelMode(
        await SettingsRepo().get('notif_mode') ?? 'both');
    await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
  }
  runApp(const MyAssistantApp());
  // على الويب: مفيش إشعارات/ودجت/جدولة — التطبيق للعرض والتجربة بس.
  if (kIsWeb) return;
  // تفضيلات حساب المواقيت (الطريقة/المذهب) قبل جدولة الأذان.
  await PrayerPrefs.load();
  // جدولات بتتجدد مع كل فتحة: صلاة + مناسبات + ملخص الليلة + فواتير
  // + حماية السلاسل + النسخة التلقائية الأسبوعية.
  unawaited(PrayerScheduler.ensureScheduled());
  unawaited(FridayReminder.ensureScheduled());
  unawaited(AdhkarReminders.reschedule());
  unawaited(WidgetBridge.push());
  unawaited(OccasionsRepo().rescheduleAll());
  unawaited(EveningScheduler.ensureScheduled());
  unawaited(WeekSummaryScheduler.ensureScheduled());
  unawaited(BillsRepo().rescheduleAll());
  // وضع السفر بيوقف تذكيرات الروتين (السلاسل + المياه).
  final travelMode = await SettingsRepo().travelMode();
  if (travelMode) {
    unawaited(Notifications.cancel(Notifications.streakNotifId));
    unawaited(Notifications.cancel(WaterGuard.afternoonId));
    unawaited(Notifications.cancel(WaterGuard.eveningId));
  } else {
    unawaited(StreakGuard.ensureScheduled());
    unawaited(WaterGuard.ensureScheduled());
  }
  unawaited(AutoBackup.ensure());
  unawaited(MonthSummary.ensure());
  unawaited(MedsRepo().deactivateExpiredCourses());
  unawaited(GameyaRepo().rescheduleAll());
  unawaited(HomeMaintenanceRepo().rescheduleAll());
  unawaited(IncomeRepo().rescheduleAll());
  unawaited(PharmacyRepo().rescheduleAll());
  unawaited(WarrantyRepo().rescheduleAll());
  unawaited(MetersRepo().ensureMonthlyReminder());
  unawaited(QuranRepo().ensureReminder());
  unawaited(RelativesRepo().rescheduleAll());
  unawaited(CapsuleRepo().rescheduleAll());
  unawaited(PlantsRepo().rescheduleAll());
  unawaited(CycleRepo().ensureReminders());
  unawaited(TasksRepo().rescheduleAll());
  unawaited(SubscriptionsRepo().rescheduleAll());
  unawaited(CarsRepo().rescheduleAll());
  unawaited(RenewalsRepo().rescheduleAll());
  unawaited(TripsRepo().rescheduleAll());
  unawaited(PetsRepo().rescheduleAll());
  unawaited(FastingRepo().rescheduleCurrent());
  unawaited(ProactiveInsight.ensureScheduled());
  unawaited(VaccinationsRepo().rescheduleAll());
}
