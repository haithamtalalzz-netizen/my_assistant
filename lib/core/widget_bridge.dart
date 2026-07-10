import 'dart:developer' as dev;

import 'package:home_widget/home_widget.dart';

import '../data/appointments_repo.dart';
import '../data/health_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'prayers.dart';
import 'water_guard.dart';

/// جسر ويدجت الشاشة الرئيسية: التطبيق بيدفع نصوص جاهزة (بأرقام عربية)
/// والويدجت الأندرويد بيعرضها زي ما هي.
class WidgetBridge {
  static const String provider = 'MyAssistantWidgetProvider';
  static const String qualifiedProvider =
      'com.hhub.my_assistant.MyAssistantWidgetProvider';

  static Future<void> push() async {
    try {
      final now = DateTime.now();
      final day = dayKey(now);
      final settings = SettingsRepo();

      final gov = governorateByName(await settings.governorateName());
      final prayers = prayerTimesFor(now, gov);
      final next = prayers.nextIndex(now);
      final prayerLine = next == null
          ? 'خلصت صلوات النهارده'
          : '${kPrayerNames[next]} ${arTime(prayers.times[next])}';

      final appts = await AppointmentsRepo().forDay(now);
      final String apptsLine;
      if (appts.isEmpty) {
        apptsLine = 'مفيش مواعيد النهارده';
      } else {
        final first = appts.first;
        apptsLine = appts.length == 1
            ? '${first.title} — ${arTime(first.when)}'
            : '${arNum(appts.length)} مواعيد — أولها ${first.title} ${arTime(first.when)}';
      }

      final water = await HealthRepo().waterOn(day);
      final goal = await settings.waterGoal();

      await HomeWidget.saveWidgetData<String>('line_prayer', prayerLine);
      await HomeWidget.saveWidgetData<String>('line_appts', apptsLine);
      await HomeWidget.saveWidgetData<String>(
          'line_water', 'المياه ${arNum(water)} / ${arNum(goal)}');
      await HomeWidget.updateWidget(
          name: provider, qualifiedAndroidName: qualifiedProvider);
    } on Exception catch (e, st) {
      dev.log('فشل تحديث الويدجت', error: e, stackTrace: st);
    }
  }
}

/// بيتنفذ في background isolate لما المستخدم يدوس + المياه من الويدجت.
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  try {
    if (uri.host == 'water') {
      await HealthRepo().addWater(dayKey(DateTime.now()), 1);
      await WidgetBridge.push();
      await WaterGuard.ensureScheduled();
    }
  } on Exception catch (e, st) {
    dev.log('فشل تنفيذ ضغطة الويدجت', error: e, stackTrace: st);
  }
}
