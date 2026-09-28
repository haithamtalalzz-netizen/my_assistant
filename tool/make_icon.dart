// أداة أيقونة التطبيق: بتحوّل الرسمة المصدر لملفّين جاهزين لـ
// flutter_launcher_icons.
//
//   dart run tool/make_icon.dart && dart run flutter_launcher_icons
//
// 🔴 الرسمة المصدر مرسومة كـ «مربّع بحواف مستديرة» **على خلفية سودا** —
// فالأركان الأربعة سودا. لو استعملناها زى ما هى، أى لانشر بيرسم أيقونة
// مربّعة هيبان فيه أركان سودا حوالين الشكل. فبنملا الأسود ده بلون الخلفية
// نفسه (بنمدّ أول بكسل مش أسود فى كل صف) بدل ما نقصّ الصورة — القصّ كان
// هيحتاج ٩٥px من كل ناحية (نصف قطر الحواف ≈ ٣٠٨px) وكان هيقطع طرف الهوائى.
//
// 🔴 والأيقونة التكيّفية (adaptive) بيتقصّ منها دايرة: المنطقة الآمنة ~٦٦٪
// بس. فالـforeground بنحطّ فيه الرسمة بـ٧٤٪ فى نصّ كانفاس بلون الخلفية —
// كده الروبوت والكليب-بورد مايتقصّوش، والدايرة بتبان متّصلة باللون.
import 'dart:io';

import 'package:image/image.dart' as img;

const _src = 'assets/icon/source_robot.png';
const _canvas = 1024;

/// أى بكسل أغمق من كده فى أركان الصورة بيتحسب «خلفية سودا».
const _darkCut = 45;

double _lum(img.Pixel p) => 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

/// بتملا الأركان السودا بلون أول بكسل مش أسود فى نفس الصف (يمين وشمال).
/// الصفوف اللى فى النصّ حوافها زرقا أصلاً فمابتتلمسش — ووش الروبوت الأسود
/// فى وسط الصورة مش فى ركن، فمافيش خطر عليه.
void _fillCorners(img.Image im) {
  for (var y = 0; y < im.height; y++) {
    if (_lum(im.getPixel(0, y)) < _darkCut) {
      var x = 0;
      while (x < im.width && _lum(im.getPixel(x, y)) < _darkCut) {
        x++;
      }
      if (x < im.width) {
        final c = im.getPixel(x, y);
        for (var i = 0; i < x; i++) {
          im.setPixelRgb(i, y, c.r, c.g, c.b);
        }
      }
    }
    final last = im.width - 1;
    if (_lum(im.getPixel(last, y)) < _darkCut) {
      var x = last;
      while (x >= 0 && _lum(im.getPixel(x, y)) < _darkCut) {
        x--;
      }
      if (x >= 0) {
        final c = im.getPixel(x, y);
        for (var i = last; i > x; i--) {
          im.setPixelRgb(i, y, c.r, c.g, c.b);
        }
      }
    }
  }
}

/// اللون **الأكثر تكرارًا** فى إطار الصورة — بيستخدم كخلفية للـforeground
/// وللـ`adaptive_icon_background` فى pubspec.
///
/// المتوسّط كان بيطلع أزرق غامق باهت لإن الركن السفلى غامق، فكان بيعمل
/// حلقة بتبان حوالين الرسمة. الأكثر تكرارًا = لون الأيقونة الحقيقى.
({int r, int g, int b}) _edgeColor(img.Image im) {
  final counts = <int, int>{};
  void add(img.Pixel p) {
    // تقريب لكل ١٦ درجة عشان تدرّجات اللون الواحد تتجمّع مع بعض.
    final key = (p.r ~/ 16) << 16 | (p.g ~/ 16) << 8 | (p.b ~/ 16);
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final band = im.width ~/ 16;
  for (var i = 0; i < im.width; i += 2) {
    for (var d = 0; d < band; d += 2) {
      add(im.getPixel(i, d));
      add(im.getPixel(i, im.height - 1 - d));
      add(im.getPixel(d, i));
      add(im.getPixel(im.width - 1 - d, i));
    }
  }
  var best = 0, bestN = -1;
  counts.forEach((k, v) {
    if (v > bestN) {
      bestN = v;
      best = k;
    }
  });
  return (
    r: ((best >> 16) & 0xff) * 16 + 8,
    g: ((best >> 8) & 0xff) * 16 + 8,
    b: (best & 0xff) * 16 + 8
  );
}

void main() {
  final bytes = File(_src).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('تعذّر قراءة $_src');
    exit(1);
  }

  // مربّع بأقصى بُعد لو مش مربّع أصلاً.
  final side = decoded.width > decoded.height ? decoded.width : decoded.height;
  final squared = img.Image(width: side, height: side)
    ..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(squared, decoded,
      dstX: (side - decoded.width) ~/ 2, dstY: (side - decoded.height) ~/ 2);

  _fillCorners(squared);
  final bg = _edgeColor(squared);

  // (١) الأيقونة الكاملة — 1024×1024 بملء الإطار.
  final full = img.copyResize(squared, width: _canvas, height: _canvas);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(full));

  // (٢) الـforeground — الرسمة ٧٤٪ فى نصّ كانفاس بلون الأيقونة السائد.
  // الدايرة اللى أندرويد بيقصّها من الأيقونة التكيّفية ≈٧٢٪ من الكانفاس،
  // يعنى بتغطّى ~٩٧٪ من الرسمة والهامش تقريبًا مابيبانش — فاللون المسطّح
  // كفاية. (جرّبت أمدّ حواف الرسمة بدل اللون فطلعت خطوط أفقية، لإن
  // حواف الرسمة نفسها متفاوتة.)
  const inner = (_canvas * 74) ~/ 100;
  final fg = img.Image(width: _canvas, height: _canvas)
    ..clear(img.ColorRgb8(bg.r, bg.g, bg.b));
  img.compositeImage(fg, img.copyResize(squared, width: inner, height: inner),
      dstX: (_canvas - inner) ~/ 2, dstY: (_canvas - inner) ~/ 2);
  File('assets/icon/app_icon_fg.png').writeAsBytesSync(img.encodePng(fg));

  final hex = '#${bg.r.toRadixString(16).padLeft(2, '0')}'
          '${bg.g.toRadixString(16).padLeft(2, '0')}'
          '${bg.b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
  stdout.writeln('تم: app_icon.png + app_icon_fg.png (مصدر ${side}px)');
  stdout.writeln('لون الخلفية للـadaptive: $hex  ← حطّه فى pubspec.yaml');
}
