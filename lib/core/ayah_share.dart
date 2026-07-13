import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// نسخ الآية (ونصّ التفسير) للحافظة.
Future<void> copyAyah(String surahName, int ayah, String text,
    [String tafsir = '']) async {
  final t = tafsir.isEmpty ? text : '$text\n\n($surahName — آية $ayah)\n\n$tafsir';
  await Clipboard.setData(ClipboardData(text: t));
}

/// مشاركة الآية كصورة جميلة (بطاقة).
Future<void> shareAyahImage(
    {required String surahName, required int ayah, required String text}) async {
  final bytes = await ScreenshotController().captureFromWidget(
    _AyahCard(surahName: surahName, ayah: ayah, text: text),
    pixelRatio: 3,
    delay: const Duration(milliseconds: 60),
  );
  final caption = '$surahName — آية $ayah';
  if (kIsWeb) {
    await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'ayah.png', mimeType: 'image/png')],
        text: caption);
    return;
  }
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'ayah_$ayah.png'));
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: caption);
}

class _AyahCard extends StatelessWidget {
  final String surahName;
  final int ayah;
  final String text;
  const _AyahCard(
      {required this.surahName, required this.ayah, required this.text});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0C1423), Color(0xFF1E7A5A)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('﴿ $text ﴾',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 24),
            Text('$surahName · آية $ayah',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 6),
            Text('مساعدي',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}
