import 'dart:convert';

import 'package:web/web.dart' as web;

/// المتصفح: بينزّل الملف على جهاز المستخدم عبر رابط data — من غير أى سيرفر
/// ومن غير ما البيانات تخرج من المتصفح.
Future<void> deliverFile(
    String fileName, String mimeType, List<int> bytes) async {
  final url = 'data:$mimeType;base64,${base64Encode(bytes)}';
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
