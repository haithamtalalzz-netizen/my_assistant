import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/settings_repo.dart';

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
}
