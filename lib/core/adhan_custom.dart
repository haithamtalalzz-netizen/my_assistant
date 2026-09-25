import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/settings_repo.dart';
import 'log.dart';

/// اختيار ملف أذان من جهاز المستخدم واستخدامه كصوت للتنبيه.
/// الملف بيتنسخ لتخزين التطبيق ثم بيتحوّل لـ content:// URI (عبر FileProvider)
/// عشان نظام الإشعارات يقدر يقراه — التطبيق نفسه مابيوزّعش أى صوت محمى.
class AdhanCustom {
  static const _ch = MethodChannel('com.hhub.my_assistant/adhan');

  /// بيرجّع اسم الملف لو تمّ الاختيار والتركيب، أو null لو اتلغى/فشل.
  static Future<String?> pickAndInstall() async {
    if (kIsWeb) return null; // الأذان المخصّص على الموبايل بس.
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'ogg', 'wav', 'm4a', 'aac'],
    );
    final path = res?.files.single.path;
    if (path == null) return null;

    final ext = p.extension(path).toLowerCase();
    final dir = await getApplicationSupportDirectory();
    // اسم فريد كل مرة عشان قناة جديدة بصوت جديد (صوت القناة ثابت بعد إنشائها).
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = File(p.join(dir.path, 'adhan_custom_$stamp$ext'));
    await File(path).copy(dest.path);

    final uri = await _ch.invokeMethod<String>('contentUri', {'path': dest.path});
    if (uri == null) return null;

    final label = res!.files.single.name;
    await SettingsRepo().setAdhanCustom(
        uri: uri, label: label, channel: 'prayer_adhan_c$stamp');
    return label;
  }

  /// بادئة أسماء ملفات الأصوات المخصّصة على القرص.
  static const List<String> filePrefixes = ['adhan_custom_', 'alarm_custom_'];

  /// بعد استعادة نسخة احتياطية على جهاز جديد: ملفات الصوت رجعت بأسمائها
  /// (فالـ`content://` URI المخزّن يفضل صالح لإنه مشتقّ من المسار)، **لكن
  /// إذن القراءة اللى اتمنح للنظام وقت الاختيار مش موجود** — ومن غيره
  /// الإشعار بيرن بالصوت الافتراضى من غير أى رسالة خطأ.
  ///
  /// بيعدّى على كل ملف صوت مستعاد وينادى نفس القناة اللى بتمنح الإذن.
  /// بيرجّع عدد الملفات اللى اترجّع إذنها.
  static Future<int> regrantAll() async {
    if (kIsWeb) return 0;
    var n = 0;
    try {
      final dir = await getApplicationSupportDirectory();
      if (!await dir.exists()) return 0;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!filePrefixes.any(name.startsWith)) continue;
        final uri =
            await _ch.invokeMethod<String>('contentUri', {'path': entity.path});
        if (uri != null) n++;
      }
    } on PlatformException catch (e, st) {
      logError('فشل تجديد إذن أصوات التنبيه بعد الاستعادة', e, st);
    } on MissingPluginException catch (e) {
      // منصّة من غير القناة دى (تست/سطح مكتب) — مافيش إذن أصلاً.
      logError('مافيش قناة أصوات على المنصّة دى', e);
    }
    return n;
  }

  /// نفس الفكرة لكن **عام**: يختار ملف صوت ويرجّع بياناته من غير ما يحفظه فى
  /// إعدادات الأذان — بيستخدمه منبّه التذكيرات. null لو اتلغى/فشل.
  static Future<({String uri, String label, String channel})?> pickSound() async {
    if (kIsWeb) return null;
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'ogg', 'wav', 'm4a', 'aac'],
    );
    final path = res?.files.single.path;
    if (path == null) return null;

    final ext = p.extension(path).toLowerCase();
    final dir = await getApplicationSupportDirectory();
    // قناة جديدة لكل ملف — صوت القناة ثابت بعد إنشائها.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = File(p.join(dir.path, 'alarm_custom_$stamp$ext'));
    await File(path).copy(dest.path);

    final uri = await _ch.invokeMethod<String>('contentUri', {'path': dest.path});
    if (uri == null) return null;
    return (
      uri: uri,
      label: res!.files.single.name,
      channel: 'note_alarm_c$stamp',
    );
  }
}
