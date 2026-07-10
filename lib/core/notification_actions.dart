import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/meds_repo.dart';
import 'ar.dart';
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
    }
    await WidgetBridge.push();
  } on Exception catch (e, st) {
    dev.log('فشل تنفيذ زرار الإشعار ($action)', error: e, stackTrace: st);
  }
}
