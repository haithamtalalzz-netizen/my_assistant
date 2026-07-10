import 'dart:developer' as dev;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// قراءة نص من صورة على الجهاز (ML Kit) — النسخة الأصلية للموبايل/سطح المكتب.
Future<String?> recognizeFromPath(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return result.text;
  } on Exception catch (e) {
    dev.log('فشلت قراءة الصورة', error: e);
    return null;
  } finally {
    await recognizer.close();
  }
}
