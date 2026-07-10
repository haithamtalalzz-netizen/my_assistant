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
import 'core/notification_actions.dart';
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
import 'data/meters_repo.dart';
import 'data/pharmacy_repo.dart';
import 'data/plants_repo.dart';
import 'data/quran_repo.dart';
import 'data/relatives_repo.dart';
import 'data/settings_repo.dart';
import 'data/warranty_repo.dart';
import 'data/home_maintenance_repo.dart';
import 'data/meds_repo.dart';
import 'data/occasions_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  // جدولات بتتجدد مع كل فتحة: صلاة + مناسبات + ملخص الليلة + فواتير
  // + حماية السلاسل + النسخة التلقائية الأسبوعية.
  unawaited(PrayerScheduler.ensureScheduled());
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
}
