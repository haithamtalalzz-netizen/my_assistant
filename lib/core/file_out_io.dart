import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// موبايل/سطح مكتب: بيحفظ الملف مؤقت وبيفتح شاشة المشاركة.
Future<void> deliverFile(
    String fileName, String mimeType, List<int> bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
}
