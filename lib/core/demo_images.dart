/// صور وهمية للملابس التجريبية — **بتتولّد بالكود مش ملفات مرفقة**.
///
/// ليه كده: (أ) مافيش أصول تتحط فى الـAPK فيكبر، (ب) بتشتغل على الموبايل
/// والويب بنفس الطريقة (بتتخزّن جوه القاعدة زى أى صورة)، (ج) بتسافر مع
/// النسخة الاحتياطية أوتوماتيك.
///
/// وشكلها مقصود: تدرّج بلون القطعة. أهم حاجة فى شاشة «ألبس إيه النهارده»
/// إنك تشوف **ألوان الطقم مع بعض** — فالسواتش دى بتخدم الغرض فعلًا.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// أسماء الألوان العربية اللى الملابس التجريبية بتستخدمها → RGB.
/// أى اسم مش موجود بياخد رمادى محايد بدل ما يفشل.
const Map<String, (int, int, int)> kDemoColors = {
  'أبيض': (245, 245, 247),
  'أسود': (38, 38, 42),
  'رمادى': (140, 144, 150),
  'كحلى': (32, 52, 96),
  'أزرق': (52, 106, 190),
  'أزرق فاتح': (120, 168, 224),
  'أحمر': (186, 60, 60),
  'أخضر': (72, 140, 96),
  'بيج': (214, 194, 164),
  'بنى': (120, 86, 60),
  'فضى': (192, 196, 204),
};

(int, int, int) demoColorOf(String name) =>
    kDemoColors[name.trim()] ?? (150, 150, 155);

/// بيولّد PNG بتدرّج رأسى للّون ده.
///
/// [darken] بيحدّد قد إيه أسفل الصورة أغمق من أعلاها — بيدّى إحساس القماش
/// بدل مستطيل مصمت.
Uint8List demoSwatchPng(String colorName,
    {int width = 360, int height = 460, double darken = 0.45}) {
  final (r, g, b) = demoColorOf(colorName);
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    // ١.٠ فوق → (١ - darken) تحت.
    final t = 1 - (y / height) * darken;
    final rr = (r * t).clamp(0, 255).toInt();
    final gg = (g * t).clamp(0, 255).toInt();
    final bb = (b * t).clamp(0, 255).toInt();
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, rr, gg, bb);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
