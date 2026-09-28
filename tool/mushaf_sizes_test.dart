// شاشتَى المصحف — **فى ملف لوحدهم** عن قصد.
//
// 🔴 بيحمّلوا أصل ضخم بمؤشّر لانهائى، فلو اتحطّوا مع باقى الشاشات
// بيسمّموا اللى بعدهم (جُرِّب: ٥٢ اختبار بيفشل). هنا كل واحد فى عمليّة
// الملف بتاعته فمفيش تلويث — والتغطية بتكتمل بدل ما يفضلوا بره المسح.
//   flutter test tool/mushaf_sizes_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/screens/worship/quran_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';

const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'موبايل عادى 360': Size(360, 800),
  'تابلت 800': Size(800, 1280),
};

/// نفس قاعدة المسح: **الصندوق أقصر من سطر واحد** = نصّ مقطوع أكيد.
List<String> _vClipped(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1) continue;
    final line = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: 1,
      textScaler: ro.textScaler,
    )..layout();
    if (ro.size.height >= line.height - 0.5) continue;
    final txt = ro.text.toPlainText().trim();
    if (txt.isEmpty) continue;
    out.add('نصّ متقصوص طولاً (${ro.size.height.round()} من '
        '${line.height.round()}): «$txt»');
  }
  return out.toList();
}

/// مجموع أطوال أبناء الصفّ مقابل المتاح — نفس حساب `RenderFlex` جوّاه.
List<String> _ovf(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderFlex>()) {
    if (!ro.hasSize) continue;
    var sum = 0.0;
    ro.visitChildren((c) {
      if (c is RenderBox && c.hasSize) {
        sum += ro.direction == Axis.horizontal ? c.size.width : c.size.height;
      }
    });
    final avail =
        ro.direction == Axis.horizontal ? ro.size.width : ro.size.height;
    if (sum - avail > 0.5) {
      out.add('قصّ ${(sum - avail).round()}px '
          '${ro.direction == Axis.horizontal ? 'عرضاً' : 'طولاً'}');
    }
  }
  return out.toList();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  Directory('.dart_tool/sqflite_common_ffi/databases')
      .createSync(recursive: true);
  late Database db;

  setUpAll(() async {
    await loadShotFonts();
    await initializeDateFormatting('ar');
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
    await seedDemoData();
  });

  tearDownAll(() async {
    AppDb.reset();
    await db.close();
  });

  testWidgets('المصحف على ٣ مقاسات', (tester) async {
    final found = <String, List<String>>{};
    for (final e in _sizes.entries) {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        locale: const Locale('ar'),
        home: const Directionality(
            textDirection: TextDirection.rtl, child: MushafScreen()),
      ));
      // pumpAndSettle ممنوع: المؤشّر بيلفّ للأبد.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      for (final m in {..._ovf(tester), ..._vClipped(tester)}) {
        found.putIfAbsent(m, () => <String>[]).add(e.key);
      }
      for (var i = 0; i < 12 && tester.takeException() != null; i++) {}
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    if (found.isNotEmpty) {
      fail(found.entries
          .map((x) => '${x.key}   [${x.value.join(" · ")}]')
          .join('\n'));
    }
  });
}
