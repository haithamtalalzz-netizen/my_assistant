import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// تسجيل موحّد للأخطاء والمعلومات — بيطبع فى logcat **و** بيكتب فى ملف على
/// الجهاز عشان تقدر تشوف الأخطاء من غير ما توصّل الموبايل بكمبيوتر.
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
/// الملف ده بيتشارك من «شارك التشخيص»، والتطبيق كله مبنى على إن البيانات
/// ماتخرجش من الجهاز إلا بفعل صريح منك. الوصف + كائن الاستثناء كفاية.
void logError(String what, Object error, [StackTrace? stack]) {
  final line = '❌ $what: $error';
  debugPrint(line);
  AppLog.append(line);
  if (stack != null) {
    debugPrintStack(stackTrace: stack, maxFrames: 8);
    // أول ٤ إطارات بس فى الملف — الباقى ضوضاء بتاكل المساحة.
    AppLog.append(
        stack.toString().split('\n').take(4).map((l) => '    $l').join('\n'));
  }
}

/// سطر معلوماتى (نجاح عملية أو قياس أداء).
void logInfo(String message) {
  final line = 'ℹ️ $message';
  debugPrint(line);
  AppLog.append(line);
}

/// ملف اللوج على الجهاز — محلى بالكامل، مافيش أى حاجة بتتبعت لأى سيرفر.
///
/// التصميم مبنى على قاعدة واحدة: **اللوجر عمره ما يكسر التطبيق ولا يبطّئه**.
/// عشان كده كل حاجة جواه `try/catch` صامت، والكتابة **مجمّعة** (بتتأجّل
/// ثانيتين وتتكتب مرة واحدة) بدل ما كل سطر يعمل I/O.
class AppLog {
  AppLog._();

  /// أقصى حجم للملف؛ لما يعدّيه بنسيب آخر نصه بس (الأحدث هو المهم).
  static const int _maxBytes = 128 * 1024;
  static const int _maxPending = 200;

  static File? _file;
  static bool _ready = false;
  static final List<String> _pending = [];
  static Timer? _timer;

  /// بيتنادى مرة من `main` — قبل كده السطور بتتجمّع فى الذاكرة وبتتكتب
  /// أول ما الملف يجهز، فمفيش حاجة بتضيع من بدايات التشغيل.
  static Future<void> init() async {
    if (kIsWeb || _ready) return; // الويب مالوش نظام ملفات
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File(p.join(dir.path, 'app.log'));
      _file = f;
      _ready = true;
      // سطر تشخيصى مفيد بذاته: بيقول اللوج بيتكتب فين وفيه كام بايت من
      // التشغيلات اللى فاتت — وده كمان الدليل الوحيد إن الملف شغال فى
      // الريليز (مافيش run-as على نسخة غير debuggable).
      final size = await f.exists() ? await f.length() : 0;
      debugPrint('ℹ️ ملف اللوج: ${f.path} ($size bytes)');
      await _flush();
    } on Exception catch (e) {
      // من غير ملف التطبيق بيكمل عادى — logcat لسه شغال.
      debugPrint('ℹ️ ملف اللوج مش متاح: $e');
    }
  }

  /// بيضيف سطر بختم وقت. آمن قبل `init` وعلى الويب.
  static void append(String line) {
    if (kIsWeb) return;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    _pending.add('[${two(now.month)}-${two(now.day)} ${two(now.hour)}:'
        '${two(now.minute)}:${two(now.second)}] $line');
    // سقف للذاكرة لو الملف عمره ما جهز (ماينفعش نكبر للأبد).
    if (_pending.length > _maxPending) {
      _pending.removeRange(0, _pending.length - _maxPending);
    }
    if (!_ready) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), _flush);
  }

  static Future<void> _flush() async {
    final f = _file;
    if (f == null || _pending.isEmpty) return;
    final batch = List<String>.from(_pending);
    _pending.clear();
    try {
      await f.writeAsString('${batch.join('\n')}\n',
          mode: FileMode.append, flush: true);
      await _rotate(f);
    } on Exception catch (e) {
      debugPrint('ℹ️ فشلت كتابة ملف اللوج: $e');
    }
  }

  /// لما الملف يكبر بنسيب آخر نصه — الأحدث هو اللى بيهمّ فى التشخيص.
  static Future<void> _rotate(File f) async {
    try {
      if (await f.length() <= _maxBytes) return;
      final text = await f.readAsString();
      await f.writeAsString(text.substring(text.length ~/ 2), flush: true);
    } on Exception catch (_) {
      // فشل التدوير مايستاهلش نكسر حاجة.
    }
  }

  /// محتوى اللوج للعرض («شارك التشخيص»).
  static Future<String> read() async {
    await _flush();
    final f = _file;
    if (f == null) return '';
    try {
      return await f.exists() ? await f.readAsString() : '';
    } on Exception catch (_) {
      return '';
    }
  }

  /// الملف نفسه للمشاركة — null لو لسه مفيش حاجة اتسجّلت.
  static Future<File?> fileForShare() async {
    await _flush();
    final f = _file;
    if (f == null) return null;
    try {
      return await f.exists() && await f.length() > 0 ? f : null;
    } on Exception catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    _pending.clear();
    final f = _file;
    if (f == null) return;
    try {
      if (await f.exists()) await f.delete();
    } on Exception catch (_) {}
  }

  /// للاختبارات: ملف مؤقّت بدل مجلد التطبيق.
  @visibleForTesting
  static void useFileForTests(File f) {
    _file = f;
    _ready = true;
    _pending.clear();
  }

  @visibleForTesting
  static Future<void> flushForTests() => _flush();

  @visibleForTesting
  static void resetForTests() {
    _timer?.cancel();
    _file = null;
    _ready = false;
    _pending.clear();
  }
}
