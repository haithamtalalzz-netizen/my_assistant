// أداة مطوّر: بترسم كل أنواع الملابس التجريبية فى مجلّد لمعاينتها بالعين.
//   dart run tool/render_demo_clothes.dart <out_dir>
import 'dart:io';

import 'package:my_assistant/core/demo_images.dart';

void main(List<String> args) {
  final out = Directory(args.isEmpty ? 'build/demo_clothes' : args.first)
    ..createSync(recursive: true);
  const colors = {
    'tshirt': 'رمادى', 'shirt': 'أبيض', 'checkShirt': 'أحمر', 'polo': 'أخضر',
    'sweater': 'بيج', 'trousers': 'أسود', 'jeans': 'أزرق', 'shorts': 'رمادى',
    'jacket': 'أزرق فاتح', 'coat': 'أسود', 'hoodie': 'كحلى', 'shoe': 'أسود',
    'sneaker': 'أبيض', 'boot': 'بنى', 'watch': 'فضى', 'cap': 'أسود',
    'scarf': 'رمادى', 'belt': 'بنى',
  };
  for (final k in kDemoClothingKinds) {
    final sw = Stopwatch()..start();
    final png = demoClothingPng(k, colors[k] ?? 'رمادى');
    File('${out.path}/$k.png').writeAsBytesSync(png);
    stdout.writeln('$k ${png.length} bytes ${sw.elapsedMilliseconds} ms');
  }
}
