/// صور وهمية للملابس التجريبية — **بتتولّد بالكود مش ملفات مرفقة**.
///
/// ليه كده: (أ) مافيش أصول تتحط فى الـAPK فيكبر، (ب) بتشتغل على الموبايل
/// والويب بنفس الطريقة (بتتخزّن جوه القاعدة زى أى صورة)، (ج) بتسافر مع
/// النسخة الاحتياطية أوتوماتيك.
///
/// فيه نوعين:
/// - [demoSwatchPng]: سواتش بتدرّج لون القطعة (الشكل القديم — لسه مستخدم
///   فى الاختبارات وكبديل لأى نوع مش معروف).
/// - [demoClothingPng]: **رسمة القطعة نفسها** (قميص · جينز · جاكيت · كوتشى ·
///   ساعة · كاب …) ملوّنة بلون القطعة على خلفية فاتحة — عشان بند «ملابسى»
///   يتجرّب بصور شبه الحقيقية مش مربّعات لون.
library;

import 'dart:math' as math;
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

/// أنواع الرسمات المتاحة لـ[demoClothingPng]. أى نوع تانى بيرجع سواتش.
const List<String> kDemoClothingKinds = [
  'tshirt',
  'shirt',
  'checkShirt',
  'polo',
  'sweater',
  'trousers',
  'jeans',
  'shorts',
  'jacket',
  'coat',
  'hoodie',
  'shoe',
  'sneaker',
  'boot',
  'watch',
  'cap',
  'scarf',
  'belt',
];

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

/// بيرسم قطعة لبس من نوع [kind] (من [kDemoClothingKinds]) بلون [colorName]
/// ويرجّعها PNG. الرسمة على مساحة ٣٢٠×٤٠٠ (نفس نسبة كروت «ملابسى»).
///
/// نوع مش معروف → سواتش اللون (مش استثناء) عشان البذر مايقفش.
Uint8List demoClothingPng(String kind, String colorName) {
  if (!kDemoClothingKinds.contains(kind)) {
    return demoSwatchPng(colorName, width: 320, height: 400);
  }
  final pen = _Pen(demoColorOf(colorName));
  switch (kind) {
    case 'tshirt':
      pen.tshirt();
    case 'shirt':
      pen.shirt();
    case 'checkShirt':
      pen.shirt(checks: true);
    case 'polo':
      pen.polo();
    case 'sweater':
      pen.sweater();
    case 'trousers':
      pen.trousers();
    case 'jeans':
      pen.trousers(jeans: true);
    case 'shorts':
      pen.shorts();
    case 'jacket':
      pen.jacket();
    case 'coat':
      pen.coat();
    case 'hoodie':
      pen.hoodie();
    case 'shoe':
      pen.shoe();
    case 'sneaker':
      pen.sneaker();
    case 'boot':
      pen.boot();
    case 'watch':
      pen.watch();
    case 'cap':
      pen.cap();
    case 'scarf':
      pen.scarf();
    case 'belt':
      pen.belt();
  }
  return Uint8List.fromList(img.encodePng(pen.im));
}

/// رسّام بسيط فوق حزمة `image`: لوح ٣٢٠×٤٠٠ + لوحة ألوان مشتقّة من لون
/// القطعة (أساسى/ظل/غامق/فاتح) + مساعدات مضلّعات ودواير وخطوط.
class _Pen {
  static const int w = 320;
  static const int h = 400;

  final img.Image im = img.Image(width: w, height: h);
  late final img.Color bg;
  late final img.Color fill;
  late final img.Color shade;
  late final img.Color dark;
  late final img.Color light;

  /// لون الخيط/التفاصيل: فاتح على قطعة غامقة والعكس.
  late final img.Color thread;

  _Pen((int, int, int) rgb) {
    final (r, g, b) = rgb;
    bg = img.ColorRgb8(238, 239, 243);
    fill = img.ColorRgb8(r, g, b);
    shade = _mul(rgb, 0.72);
    dark = _mul(rgb, 0.48);
    light = _mix(rgb, (255, 255, 255), 0.38);
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    thread = lum > 160 ? img.ColorRgb8(120, 120, 126) : img.ColorRgb8(236, 228, 210);
    img.fill(im, color: bg);
  }

  static img.Color _mul((int, int, int) c, double k) => img.ColorRgb8(
      (c.$1 * k).round().clamp(0, 255),
      (c.$2 * k).round().clamp(0, 255),
      (c.$3 * k).round().clamp(0, 255));

  static img.Color _mix((int, int, int) a, (int, int, int) b, double t) =>
      img.ColorRgb8(
          (a.$1 + (b.$1 - a.$1) * t).round().clamp(0, 255),
          (a.$2 + (b.$2 - a.$2) * t).round().clamp(0, 255),
          (a.$3 + (b.$3 - a.$3) * t).round().clamp(0, 255));

  // ---- مساعدات رسم ----

  List<img.Point> _pts(List<(num, num)> p) =>
      [for (final (x, y) in p) img.Point(x, y)];

  /// مضلّع مملوء بحدّ ناعم.
  void poly(List<(num, num)> p, img.Color c, {img.Color? edge, num t = 3}) {
    img.fillPolygon(im, vertices: _pts(p), color: c);
    if (edge != null) {
      img.drawPolygon(im,
          vertices: _pts(p), color: edge, antialias: true, thickness: t);
    }
  }

  void line(num x1, num y1, num x2, num y2, img.Color c,
      {num t = 2, img.Image? mask}) {
    img.drawLine(im,
        x1: x1.round(),
        y1: y1.round(),
        x2: x2.round(),
        y2: y2.round(),
        color: c,
        antialias: true,
        thickness: t,
        mask: mask);
  }

  void circle(num x, num y, int r, img.Color c, {img.Color? edge}) {
    img.fillCircle(im,
        x: x.round(), y: y.round(), radius: r, color: c, antialias: true);
    if (edge != null) ring(x, y, r, c: edge);
  }

  /// حلقة (دايرة بسُمك) من [r] لـ[r]+[t].
  void ring(num x, num y, int r, {required img.Color c, int t = 3}) {
    for (var i = 0; i < t; i++) {
      img.drawCircle(im,
          x: x.round(), y: y.round(), radius: r + i, color: c, antialias: true);
    }
  }

  void rect(num x1, num y1, num x2, num y2, img.Color c, {num radius = 0}) {
    img.fillRect(im,
        x1: x1.round(),
        y1: y1.round(),
        x2: x2.round(),
        y2: y2.round(),
        color: c,
        radius: radius);
  }

  /// قناع (أبيض جوه المضلّع، أسود بره) — عشان نرسم نقشة جوه القطعة بس.
  img.Image maskOf(List<(num, num)> p) {
    final m = img.Image(width: w, height: h);
    img.fill(m, color: img.ColorRgb8(0, 0, 0));
    img.fillPolygon(m, vertices: _pts(p), color: img.ColorRgb8(255, 255, 255));
    return m;
  }

  /// نقط قوس بيضاوى من زاوية [a0] لـ[a1] (راديان).
  List<(num, num)> arc(num cx, num cy, num rx, num ry, double a0, double a1,
      {int steps = 24}) {
    return [
      for (var i = 0; i <= steps; i++)
        (() {
          final a = a0 + (a1 - a0) * i / steps;
          return (cx + rx * math.cos(a), cy + ry * math.sin(a));
        })(),
    ];
  }

  // ---- أجسام مشتركة ----

  /// جسم قطعة علوية: كمّ قصير أو طويل، وحافة عند [hem].
  List<(num, num)> topBody({required bool longSleeve, int hem = 340}) =>
      longSleeve
          ? [
              (124, 66), (62, 84), (18, 255), (62, 268), (96, 160), (96, hem),
              (224, hem), (224, 160), (258, 268), (302, 255), (258, 84),
              (196, 66),
            ]
          : [
              (124, 66), (62, 84), (26, 150), (44, 180), (96, 160), (96, hem),
              (224, hem), (224, 160), (276, 180), (294, 150), (258, 84),
              (196, 66),
            ];

  /// فتحة رقبة دايرية (+ ريب اختيارى).
  void roundNeck({bool rib = true, img.Color? ribColor}) {
    circle(160, 66, 34, bg);
    if (rib) {
      ring(160, 66, 34, c: ribColor ?? shade, t: 5);
      // الحلقة بتطلع فوق الكتفين — نمسح الجزء اللى فوق الجسم.
      rect(0, 0, w, 60, bg);
    }
  }

  /// ياقة قميص (مثلّثين).
  void collar() {
    circle(160, 66, 34, bg);
    poly([(122, 60), (160, 116), (128, 110), (106, 84)], fill, edge: shade);
    poly([(198, 60), (160, 116), (192, 110), (214, 84)], fill, edge: shade);
  }

  void buttons(int x, int y0, int y1, {int step = 42, int r = 5}) {
    for (var y = y0; y <= y1; y += step) {
      circle(x, y, r, light, edge: shade);
    }
  }

  // ---- القطع ----

  void tshirt() {
    final body = topBody(longSleeve: false);
    poly(body, fill, edge: shade);
    roundNeck();
    // خط الكمّ.
    line(96, 160, 44, 180, shade, t: 2);
    line(224, 160, 276, 180, shade, t: 2);
  }

  void shirt({bool checks = false}) {
    final body = topBody(longSleeve: true);
    poly(body, fill, edge: shade);
    if (checks) {
      final m = maskOf(body);
      for (var x = 0; x < w; x += 28) {
        line(x, 0, x, h, dark, t: 4, mask: m);
        line(x + 14, 0, x + 14, h, light, t: 1, mask: m);
      }
      for (var y = 0; y < h; y += 28) {
        line(0, y, w, y, dark, t: 4, mask: m);
        line(0, y + 14, w, y + 14, light, t: 1, mask: m);
      }
      img.drawPolygon(im,
          vertices: _pts(body), color: shade, antialias: true, thickness: 3);
    }
    collar();
    line(160, 116, 160, 340, shade, t: 2);
    buttons(160, 146, 320);
    // كفّات.
    line(20, 247, 64, 260, shade, t: 3);
    line(300, 247, 256, 260, shade, t: 3);
  }

  void polo() {
    poly(topBody(longSleeve: false), fill, edge: shade);
    collar();
    line(160, 116, 160, 192, shade, t: 2);
    buttons(160, 140, 172, step: 32, r: 4);
    line(96, 160, 44, 180, shade, t: 2);
    line(224, 160, 276, 180, shade, t: 2);
  }

  void sweater() {
    const hem = 340;
    final body = topBody(longSleeve: true, hem: hem);
    poly(body, fill, edge: shade);
    // نسيج تريكو: خطوط أفقية خفيفة جوه القطعة.
    final m = maskOf(body);
    for (var y = 80; y < hem; y += 12) {
      line(0, y, w, y, shade, t: 1, mask: m);
    }
    roundNeck(ribColor: dark);
    // ريب الحافة والكفّات.
    rect(96, hem - 20, 224, hem, shade);
    for (var x = 100; x < 224; x += 8) {
      line(x, hem - 20, x, hem, dark, t: 1);
    }
    line(20, 246, 64, 259, dark, t: 10);
    line(300, 246, 256, 259, dark, t: 10);
  }

  /// بنطلون (أو جينز بخيوطه البرتقالى).
  void trousers({bool jeans = false}) {
    const hem = 372;
    final stitch = jeans ? img.ColorRgb8(214, 160, 80) : thread;
    // كتلة الوسط ثم الرجلين.
    poly([(94, 86), (226, 86), (230, 160), (90, 160)], fill);
    poly([(90, 150), (160, 150), (152, hem), (86, hem)], fill);
    poly([(160, 150), (230, 150), (234, hem), (168, hem)], fill);
    // فتحة الرجلين (V).
    poly([(150, 150), (170, 150), (160, 184)], bg);
    // حدود ناعمة.
    img.drawPolygon(im,
        vertices: _pts([
          (94, 86), (226, 86), (230, 160), (234, hem), (168, hem), (160, 184),
          (152, hem), (86, hem), (90, 160),
        ]),
        color: shade,
        antialias: true,
        thickness: 3);
    // حزام الوسط + عراوى.
    rect(94, 56, 226, 88, shade, radius: 4);
    for (final x in [112, 160, 208]) {
      rect(x - 4, 52, x + 4, 92, dark, radius: 2);
    }
    // السوستة.
    line(160, 88, 160, 142, stitch, t: 2);
    line(160, 88, 176, 92, stitch, t: 2);
    // الجيوب.
    line(104, 92, 122, 132, stitch, t: 2);
    line(216, 92, 198, 132, stitch, t: 2);
    if (jeans) {
      // جيب الفكّة + برشام.
      line(196, 96, 210, 96, stitch, t: 2);
      line(196, 96, 198, 112, stitch, t: 2);
      circle(120, 132, 3, img.ColorRgb8(200, 190, 150));
      circle(200, 132, 3, img.ColorRgb8(200, 190, 150));
    }
    // خياطة الحافة السفلية.
    line(88, hem - 8, 150, hem - 8, stitch, t: 2);
    line(170, hem - 8, 232, hem - 8, stitch, t: 2);
    // خياطة جانبية.
    line(90, 160, 86, hem - 12, stitch, t: 1);
    line(230, 160, 234, hem - 12, stitch, t: 1);
  }

  void shorts() {
    const hem = 244;
    poly([(94, 86), (226, 86), (236, 150), (84, 150)], fill);
    poly([(84, 150), (160, 150), (156, hem), (74, hem)], fill);
    poly([(160, 150), (236, 150), (246, hem), (164, hem)], fill);
    poly([(150, 150), (170, 150), (160, 186)], bg);
    img.drawPolygon(im,
        vertices: _pts([
          (94, 86), (226, 86), (236, 150), (246, hem), (164, hem), (160, 186),
          (156, hem), (74, hem), (84, 150),
        ]),
        color: shade,
        antialias: true,
        thickness: 3);
    // أستك الوسط + رباط.
    rect(94, 60, 226, 90, shade, radius: 6);
    line(150, 90, 146, 118, light, t: 3);
    line(170, 90, 174, 118, light, t: 3);
    // شريط رياضى جانبى.
    line(92, 96, 78, hem - 4, light, t: 6);
    line(228, 96, 242, hem - 4, light, t: 6);
  }

  void jacket() {
    const hem = 332;
    final body = topBody(longSleeve: true, hem: hem);
    poly(body, fill, edge: shade);
    roundNeck(ribColor: dark);
    ring(160, 66, 39, c: dark, t: 6);
    rect(0, 0, w, 60, bg);
    // السوستة.
    line(160, 104, 160, hem, light, t: 3);
    for (var y = 110; y < hem; y += 12) {
      line(156, y, 164, y, shade, t: 1);
    }
    // جيوب مايلة.
    line(112, 236, 132, 292, shade, t: 4);
    line(208, 236, 188, 292, shade, t: 4);
    // ريب الحافة والكفّات.
    rect(96, hem - 18, 224, hem, shade);
    line(20, 246, 64, 259, dark, t: 10);
    line(300, 246, 256, 259, dark, t: 10);
  }

  void coat() {
    const hem = 386;
    final body = topBody(longSleeve: true, hem: hem);
    poly(body, fill, edge: shade);
    circle(160, 66, 34, bg);
    // اللابيل (الياقة العريضة).
    poly([(122, 62), (162, 170), (132, 150), (106, 96)], shade, edge: dark, t: 2);
    poly([(198, 62), (158, 170), (188, 150), (214, 96)], shade, edge: dark, t: 2);
    line(160, 170, 160, hem, shade, t: 2);
    // زرارين صفّين (double-breasted).
    for (final y in [206, 256, 306]) {
      circle(138, y, 6, dark);
      circle(182, y, 6, dark);
    }
    // أغطية الجيوب.
    rect(102, 272, 148, 286, shade, radius: 3);
    rect(172, 272, 218, 286, shade, radius: 3);
    line(20, 247, 64, 260, shade, t: 3);
    line(300, 247, 256, 260, shade, t: 3);
  }

  void hoodie() {
    const hem = 336;
    final body = topBody(longSleeve: true, hem: hem);
    // الكبّوت الأول (وراء الجسم).
    poly([(106, 90), (112, 44), (140, 16), (180, 16), (208, 44), (214, 90)],
        fill, edge: shade);
    poly([(124, 90), (128, 52), (148, 32), (172, 32), (192, 52), (196, 90)],
        dark);
    poly(body, fill, edge: shade);
    // فتحة الرقبة بتوصل بالكبّوت.
    poly([(124, 66), (196, 66), (196, 92), (124, 92)], dark);
    // رباط الكبّوت.
    line(148, 92, 142, 156, light, t: 3);
    line(172, 92, 178, 156, light, t: 3);
    circle(142, 158, 4, light);
    circle(178, 158, 4, light);
    // جيب الكنجر.
    img.drawPolygon(im,
        vertices: _pts([(108, 250), (212, 250), (222, 322), (98, 322)]),
        color: shade,
        antialias: true,
        thickness: 3);
    rect(96, hem - 18, 224, hem, shade);
    line(20, 246, 64, 259, dark, t: 10);
    line(300, 246, 256, 259, dark, t: 10);
  }

  void shoe() {
    final sole = img.ColorRgb8(40, 40, 46);
    rect(26, 300, 294, 322, sole, radius: 8);
    // أوكسفورد واطى: المقدمة شمال والكعب يمين.
    poly([
      (30, 300), (34, 270), (66, 248), (136, 238), (186, 224), (232, 216),
      (262, 226), (284, 258), (292, 300),
    ], fill, edge: shade);
    // خط مقدمة الحذاء + لمعة.
    line(80, 300, 108, 250, shade, t: 3);
    line(52, 274, 126, 246, light, t: 2);
    // لسان الرباط + الرباط.
    poly([(176, 232), (238, 222), (246, 256), (194, 266)], shade, edge: dark,
        t: 2);
    line(188, 240, 232, 232, thread, t: 3);
    line(194, 250, 238, 242, thread, t: 3);
    line(200, 260, 244, 252, thread, t: 3);
    // الكعب.
    line(246, 232, 270, 296, shade, t: 2);
  }

  void sneaker() {
    final soleC = img.ColorRgb8(226, 226, 230);
    final soleEdge = img.ColorRgb8(150, 150, 156);
    rect(24, 288, 296, 328, soleC, radius: 14);
    img.drawPolygon(im,
        vertices: _pts([(24, 288), (296, 288), (296, 328), (24, 328)]),
        color: soleEdge,
        antialias: true,
        thickness: 2);
    // كوتشى واطى: كعب مرتفع شوية عن المقدمة.
    poly([
      (30, 290), (38, 250), (76, 228), (140, 220), (176, 196), (214, 178),
      (250, 176), (272, 194), (286, 246), (292, 290),
    ], fill, edge: shade);
    // مقدمة فاتحة.
    poly([(30, 290), (38, 250), (76, 228), (118, 222), (104, 290)], light,
        edge: shade, t: 2);
    // شريط جانبى مايل (اللوجو).
    poly([(112, 268), (200, 236), (268, 218), (264, 236), (200, 254), (118, 282)],
        dark);
    // عيون الرباط + الرباط.
    final eyes = [(178, 210), (196, 196), (214, 186), (232, 180)];
    for (final (x, y) in eyes) {
      circle(x, y, 4, dark);
    }
    for (var i = 0; i + 1 < eyes.length; i++) {
      line(eyes[i].$1, eyes[i].$2, eyes[i + 1].$1 + 10, eyes[i + 1].$2 + 18,
          thread, t: 4);
    }
    // خط الكعب.
    line(262, 200, 276, 288, shade, t: 2);
  }

  void boot() {
    final sole = img.ColorRgb8(40, 40, 46);
    rect(28, 300, 292, 326, sole, radius: 10);
    poly([
      (30, 300), (34, 262), (64, 246), (108, 240), (112, 80), (214, 80),
      (216, 240), (262, 250), (284, 268), (292, 300),
    ], fill, edge: shade);
    rect(112, 80, 214, 98, shade);
    // الرباط على الساق.
    for (var y = 116; y <= 216; y += 32) {
      circle(140, y, 4, dark);
      circle(184, y, 4, dark);
      line(140, y, 184, y + 20, thread, t: 3);
    }
    line(70, 300, 98, 254, shade, t: 3);
    line(48, 276, 100, 250, light, t: 2);
  }

  void watch() {
    final caseC = img.ColorRgb8(58, 58, 66);
    final dial = img.ColorRgb8(248, 248, 250);
    rect(128, 20, 192, 380, fill, radius: 26);
    img.drawPolygon(im,
        vertices: _pts([(128, 20), (192, 20), (192, 380), (128, 380)]),
        color: shade,
        antialias: true,
        thickness: 3);
    // وصلات السير المعدنى.
    for (var y = 40; y < 380; y += 16) {
      if (y > 120 && y < 280) continue;
      line(130, y, 190, y, shade, t: 2);
    }
    circle(160, 200, 74, caseC);
    ring(160, 200, 66, c: img.ColorRgb8(150, 150, 160), t: 4);
    circle(160, 200, 62, dial);
    // علامات الساعات.
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final long = i % 3 == 0;
      line(160 + (long ? 48 : 52) * math.cos(a), 200 + (long ? 48 : 52) * math.sin(a),
          160 + 58 * math.cos(a), 200 + 58 * math.sin(a), caseC,
          t: long ? 3 : 2);
    }
    // العقارب (١٠:١٠).
    line(160, 200, 132, 178, caseC, t: 5);
    line(160, 200, 186, 166, caseC, t: 3);
    circle(160, 200, 4, caseC);
    // التاج.
    rect(232, 190, 246, 210, caseC, radius: 3);
  }

  void cap() {
    // كاب من الجنب: القبة نصف بيضاوى، والمقدمة (القرص) طالعة شمال.
    poly([(6, 192), (92, 170), (100, 198), (44, 210)], shade, edge: dark, t: 2);
    poly(arc(172, 178, 98, 104, math.pi, 2 * math.pi), fill, edge: shade);
    // خطوط القطع.
    line(172, 74, 172, 176, shade, t: 2);
    line(172, 74, 108, 156, shade, t: 2);
    line(172, 74, 236, 156, shade, t: 2);
    circle(172, 74, 6, shade);
    // الحزام السفلى.
    rect(76, 170, 270, 194, shade, radius: 6);
    // ضبط الخلف.
    rect(258, 176, 284, 188, dark, radius: 3);
  }

  void scarf() {
    // اللفّة حوالين الرقبة.
    circle(160, 112, 92, fill, edge: shade);
    circle(160, 112, 46, bg, edge: shade);
    // الطرفين المتدلّيين.
    final left = [(108, 176), (158, 184), (150, 372), (92, 366)];
    final right = [(162, 184), (212, 176), (228, 366), (170, 372)];
    poly(left, fill, edge: shade);
    poly(right, fill, edge: shade);
    final m = maskOf([...left, ...right.reversed]);
    for (var y = 196; y < 372; y += 14) {
      line(0, y, w, y, shade, t: 1, mask: m);
    }
    // الشراشيب.
    for (var x = 96; x <= 148; x += 10) {
      line(x, 368, x - 2, 388, shade, t: 2);
    }
    for (var x = 174; x <= 226; x += 10) {
      line(x, 368, x + 2, 388, shade, t: 2);
    }
  }

  void belt() {
    final metal = img.ColorRgb8(200, 204, 212);
    final metalEdge = img.ColorRgb8(120, 124, 132);
    // حزام ملفوف (من فوق): حلقات متداخلة.
    circle(160, 212, 124, fill, edge: shade);
    circle(160, 212, 96, bg, edge: shade);
    circle(160, 212, 82, fill, edge: shade);
    circle(160, 212, 56, bg, edge: shade);
    circle(160, 212, 42, fill, edge: shade);
    circle(160, 212, 18, bg, edge: shade);
    // خُرم على الحلقة الخارجية.
    for (final a in [0.0, 0.22, 0.44]) {
      final ang = -math.pi / 2 + 0.9 + a;
      circle(160 + 110 * math.cos(ang), 212 + 110 * math.sin(ang), 5, dark);
    }
    // طرف الحزام طالع فوق وعليه الإبزيم.
    poly([(146, 92), (174, 92), (174, 30), (146, 30)], fill, edge: shade);
    rect(128, 22, 192, 84, metal, radius: 10);
    img.drawPolygon(im,
        vertices: _pts([(128, 22), (192, 22), (192, 84), (128, 84)]),
        color: metalEdge,
        antialias: true,
        thickness: 2);
    rect(142, 36, 178, 70, bg, radius: 4);
    line(160, 36, 160, 74, metalEdge, t: 5);
  }

}
