import 'package:flutter/foundation.dart';

/// تسجيل موحّد للأخطاء والمعلومات.
///
/// **ليه مش `dev.log` (من `dart:developer`)؟** لإنه **مالوش أى أثر فى بناء
/// الـrelease** — بيروح للـVM service اللى مش موجود أصلاً فى الريليز، والريليز
/// هو **البناء الوحيد** اللى بيتثبت على التليفون. يعنى كل سطور «فشل كذا» كانت
/// بتتكتب على الفاضى: الفشل الصامت كان شكله زى النجاح بالظبط.
/// `debugPrint` بيعدّى على `print` → `I/flutter` فى logcat حتى فى الريليز.
///
/// العلامات ثابتة عشان الفلترة تبقى سهلة:
/// ```
/// adb logcat -d | grep "❌"      # الأخطاء الملتقطة
/// adb logcat -d | grep "ℹ️"      # المعلومات والقياسات
/// ```
///
/// **قاعدة:** ماتحطش بيانات المستخدم فى الرسالة (مبالغ/أسماء/ردود API) —
/// اللوج بيتقرا بـadb، والتطبيق كله مبنى على إن البيانات ماتخرجش من الجهاز.
/// الوصف + كائن الاستثناء كفاية.
void logError(String what, Object error, [StackTrace? stack]) {
  debugPrint('❌ $what: $error');
  if (stack != null) debugPrintStack(stackTrace: stack, maxFrames: 8);
}

/// سطر معلوماتى (نجاح عملية أو قياس أداء).
void logInfo(String message) => debugPrint('ℹ️ $message');
