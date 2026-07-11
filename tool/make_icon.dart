// أداة لمرة واحدة: تحوّل صورة الأيقونة (JPEG) لـ PNG نظيف + تعمل نسخة
// «foreground» بهامش آمن عشان القص الدائري في أندرويد ما يقصّش السمّاعة.
//
// التشغيل: dart run tool/make_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const src = 'assets/icon/appicon.png.jpeg';
  final bytes = File(src).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('تعذّر قراءة $src');
    exit(1);
  }

  // مربّع بأقصى بُعد (لو مش مربّع أصلًا) على خلفية بيضا.
  final side = decoded.width > decoded.height ? decoded.width : decoded.height;
  final squared = img.Image(width: side, height: side)
    ..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(squared, decoded,
      dstX: (side - decoded.width) ~/ 2, dstY: (side - decoded.height) ~/ 2);

  // (1) الأيقونة الكاملة (للـ legacy icon) — 1024×1024.
  final full = img.copyResize(squared, width: 1024, height: 1024);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(full));

  // (2) foreground بهامش أصغر عشان الوش يبان أكبر: الرسمة بحجم ~86% في نص
  //     كانفاس أبيض 1024. الرسمة المصدر أصلًا فيها هامش أبيض حوالين الوش،
  //     فالوش الفعلي يفضل جوّه المنطقة الآمنة للـ adaptive icon.
  const canvas = 1024;
  const inner = 880; // ~86%
  final fg = img.Image(width: canvas, height: canvas)
    ..clear(img.ColorRgb8(255, 255, 255));
  final scaled = img.copyResize(squared, width: inner, height: inner);
  img.compositeImage(fg, scaled,
      dstX: (canvas - inner) ~/ 2, dstY: (canvas - inner) ~/ 2);
  File('assets/icon/app_icon_fg.png').writeAsBytesSync(img.encodePng(fg));

  stdout.writeln('تم: app_icon.png + app_icon_fg.png (${side}px مصدر)');
}
