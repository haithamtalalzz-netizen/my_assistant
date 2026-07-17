import 'dart:async';
import 'log.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/meds_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';
import 'widget_bridge.dart';

/// أزرار الأفعال جوه الإشعارات: بتتنفذ من غير ما التطبيق يتفتح.
/// الـ payload بصيغة "نوع|بيانات": med|id|slot و appt|id و bill|id.

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  unawaited(handleNotificationResponse(response));
}

void notificationTapHandler(NotificationResponse response) {
  unawaited(handleNotificationResponse(response));
}

Future<void> handleNotificationResponse(NotificationResponse response) async {
  final payload = response.payload ?? '';
  final action = response.actionId ?? '';
  if (action.isEmpty || payload.isEmpty) return;
  try {
    final parts = payload.split('|');
    switch (action) {
      case 'med_taken':
        if (parts.length >= 3 && parts[0] == 'med') {
          await MedsRepo().setTaken(
              int.parse(parts[1]), dayKey(DateTime.now()), parts[2], true);
        }
      case 'appt_done':
        if (parts.length >= 2 && parts[0] == 'appt') {
          await AppointmentsRepo().setDone(int.parse(parts[1]), true);
        }
      case 'bill_paid':
        if (parts.length >= 2 && parts[0] == 'bill') {
          await BillsRepo().markPaid(int.parse(parts[1]));
        }
      case 'appt_snooze':
        if (parts.length >= 2 && parts[0] == 'appt') {
          await _snoozeAppt(int.parse(parts[1]));
        }
    }
    await WidgetBridge.push();
  } on Exception catch (e, st) {
    logError('فشل تنفيذ زرار الإشعار ($action)', e, st);
  }
}

/// «أجّل ساعة»: يعيد جدولة تذكير الموعد بعد ساعة من دلوقتي. بيشتغل من الـ
/// isolate الخلفى فمحتاج يهيّئ الإشعارات فيه الأول.
Future<void> _snoozeAppt(int id) async {
  await Notifications.init();
  final appt = await AppointmentsRepo().byId(id);
  if (appt == null || appt.done) return;
  await Notifications.scheduleOnce(
    id: Notifications.apptNotifId(id),
    title: tr('تذكير مؤجَّل: ${appt.title}', 'Snoozed: ${appt.title}'),
    body: tr('الموعد الساعة ${arTime(appt.when)}',
        'Appointment at ${arTime(appt.when)}'),
    when: DateTime.now().add(const Duration(hours: 1)),
    payload: 'appt|$id',
    actions: [
      AndroidNotificationAction('appt_done', tr('تم ✓', 'Done ✓'),
          showsUserInterface: false, cancelNotification: true),
      AndroidNotificationAction('appt_snooze', tr('⏰ أجّل ساعة', '⏰ +1h'),
          showsUserInterface: false, cancelNotification: true),
    ],
  );
}
