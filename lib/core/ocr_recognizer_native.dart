import 'log.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// قراءة نص من صورة على الجهاز (ML Kit) — النسخة الأصلية للموبايل.
///
/// 🔴 **ML Kit مابيدعمش العربى.** الاسكربتات المتاحة عنده: latin · chinese ·
/// devanagiri · japanese · korean — **مفيش `arabic`**. يعنى القراءة شغّالة
/// على الأرقام والتواريخ واللاتينى، والكلام العربى لأ.
///
/// البديل المجانى الوحيد اللى بيشتغل على الجهاز للعربى هو **Tesseract**
/// (`ara.traineddata` كأصل مرفق) — بيكبّر الـAPK ودقته على صور الكاميرا أقل.
/// خدمات السحابة (Cloud Vision وغيرها) بتقرا عربى كويس لكنها **سيرفر +
/// تكلفة** = مرفوضة بشرط المستخدم «مفيش سيرفر ولا فلوس».
Future<String?> recognizeFromPath(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return result.text;
  } on Exception catch (e) {
    logError('فشلت قراءة الصورة', e);
    return null;
  } finally {
    await recognizer.close();
  }
}
