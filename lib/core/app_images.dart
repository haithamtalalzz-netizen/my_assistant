import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db.dart';
import 'log.dart';

/// تخزين وعرض صور التطبيق (مستندات · تقدّم بدنى · ملف طبى · وصفات · ملابس)
/// بطريقة **بتشتغل على الموبايل والويب**.
///
/// - **الموبايل:** الصورة بتتنسخ فى مجلد التطبيق، وبنخزّن مسارها (زى الأول).
/// - **الويب:** مفيش نظام ملفات، فالصورة بتتخزّن **جوه قاعدة البيانات**
///   (جدول `app_images`) وبنخزّن مفتاحها بالشكل `img:<key>`.
///
/// المكسب الجانبى المهم: بما إن الصور على الويب بقت صفوف فى القاعدة،
/// **نسخة JSON الاحتياطية بتاخدها معاها أوتوماتيك** من غير أى شغل زيادة.
class AppImages {
  static const String _prefix = 'img:';
  static const String table = 'app_images';

  /// أقصى بُعد للصورة على الويب — الصور بتتخزّن جوه القاعدة وبتتحوّل base64
  /// فى النسخة الاحتياطية، فلازم تفضل صغيرة.
  static const int webMaxDimension = 1280;
  static const int webJpegQuality = 70;

  /// بيصغّر الصورة ويعيد ترميزها JPEG.
  ///
  /// ليه ده لازم على الويب: `image_picker` على المتصفح **بيتجاهل**
  /// `maxWidth`/`imageQuality` خالص، فالصورة بتتخزّن بحجمها الأصلى من
  /// الكاميرا (٤-٨ ميجا) → القاعدة تتضخّم وملف النسخة يبقى تقيل.
  ///
  /// دالة نقية (بتاخد بايتات وترجّع بايتات) عشان تبقى قابلة للاختبار.
  /// لو الترميز فشل أو طلع أكبر من الأصل، بترجّع الأصل زى ما هو.
  static Uint8List compressForWeb(
    Uint8List input, {
    int maxDim = webMaxDimension,
    int quality = webJpegQuality,
  }) {
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) return input;
      final longest =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      final resized = longest > maxDim
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxDim : null,
              height: decoded.height > decoded.width ? maxDim : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      // ماينفعش نطلع بحاجة أكبر من اللى دخلت (مثلًا صورة صغيرة أصلاً).
      return out.length < input.length ? out : input;
    } catch (e, st) {
      // مش `on Exception` بس: فك الترميز بيرمى `RangeError` على ملف تالف،
      // و`RangeError` نوعه Error مش Exception فمكانش بيتمسك.
      logError('فشل ضغط الصورة — هتتخزّن زى ما هى', e, st);
      return input;
    }
  }

  /// هل القيمة دى صورة متخزّنة جوه القاعدة (مش مسار ملف)؟
  static bool isInline(String path) => path.startsWith(_prefix);

  static String _keyOf(String path) => path.substring(_prefix.length);

  /// بيختار صورة ويحفظها بالطريقة المناسبة للمنصة.
  /// بيرجّع القيمة اللى تتخزّن فى قاعدة البيانات (مسار أو `img:<key>`)،
  /// أو null لو المستخدم لغى.
  static Future<String?> pickAndStore(
    ImageSource source, {
    double maxWidth = 2000,
    int quality = 85,
    String namePrefix = 'img',
  }) async {
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: maxWidth, imageQuality: quality);
    if (picked == null) return null;
    return storeXFile(picked, namePrefix: namePrefix);
  }

  /// بيحفظ ملف صورة موجود (مثلًا صورة اتشاركت مع التطبيق).
  static Future<String?> storeXFile(XFile picked,
      {String namePrefix = 'img'}) async {
    try {
      if (kIsWeb) {
        final raw = await picked.readAsBytes();
        return storeBytes(raw, compress: true, namePrefix: namePrefix);
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docsDir.path, 'doc_images'));
      await dir.create(recursive: true);
      final dest = p.join(dir.path,
          '${namePrefix}_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}');
      await File(picked.path).copy(dest);
      return dest;
    } on Exception catch (e, st) {
      logError('فشل حفظ الصورة', e, st);
      return null;
    }
  }

  /// بيخزّن بايتات صورة جوه قاعدة البيانات ويرجّع مفتاحها `img:<key>`.
  /// (ده مسار الويب — ومتاح للاختبار على أى منصة.)
  static Future<String> storeBytes(Uint8List bytes,
      {String mime = 'image/jpeg',
      String namePrefix = 'img',
      bool compress = false}) async {
    final data = compress ? compressForWeb(bytes) : bytes;
    if (compress && !identical(data, bytes)) mime = 'image/jpeg';
    final db = await AppDb.instance;
    final key = '${namePrefix}_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert(table, {
      'key': key,
      'mime': mime,
      'data': base64Encode(data),
      'created_at': DateTime.now().toIso8601String(),
    });
    return '$_prefix$key';
  }

  /// بايتات الصورة — بيقرا من القاعدة أو من الملف حسب نوع القيمة.
  static Future<Uint8List?> bytesOf(String path) async {
    if (path.isEmpty) return null;
    try {
      if (isInline(path)) {
        final db = await AppDb.instance;
        final rows = await db
            .query(table, where: 'key = ?', whereArgs: [_keyOf(path)], limit: 1);
        if (rows.isEmpty) return null;
        return base64Decode(rows.first['data'] as String);
      }
      if (kIsWeb) return null;
      final f = File(path);
      return await f.exists() ? await f.readAsBytes() : null;
    } on Exception catch (e) {
      logError('فشلت قراءة الصورة', e);
      return null;
    }
  }

  /// بيمسح الصورة (من القاعدة أو من القرص).
  static Future<void> remove(String path) async {
    if (path.isEmpty) return;
    try {
      if (isInline(path)) {
        final db = await AppDb.instance;
        await db.delete(table, where: 'key = ?', whereArgs: [_keyOf(path)]);
        return;
      }
      if (kIsWeb) return;
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on Exception catch (e) {
      logError('فشل مسح الصورة', e);
    }
  }

  static String _mimeFromName(String name) {
    final e = p.extension(name).toLowerCase();
    if (e == '.png') return 'image/png';
    if (e == '.webp') return 'image/webp';
    if (e == '.heic') return 'image/heic';
    return 'image/jpeg';
  }
}

/// ودجت عرض موحّد — بيعرض الصورة سواء كانت ملف (موبايل) أو جوه القاعدة (ويب).
/// بديل مباشر لـ`Image.file(File(path))`.
class AppImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// نفس توقيع `Image.file` — عشان يبقى بديل مباشر.
  final ImageErrorWidgetBuilder? errorBuilder;

  const AppImage(this.path,
      {super.key,
      this.fit = BoxFit.cover,
      this.width,
      this.height,
      this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    // المسار العادى على الموبايل — من غير قراءة غير متزامنة (أسرع وأخف).
    if (!kIsWeb && !AppImages.isInline(path)) {
      return Image.file(File(path),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder ?? (_, _, _) => _broken(context));
    }
    return FutureBuilder<Uint8List?>(
      future: AppImages.bytesOf(path),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(width: width, height: height);
          }
          return errorBuilder?.call(
                  context, 'image not found', StackTrace.empty) ??
              _broken(context);
        }
        return Image.memory(bytes, fit: fit, width: width, height: height);
      },
    );
  }

  Widget _broken(BuildContext context) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.outline),
      );
}
