// هارنس تصوير الشاشات — بيرندر ودجت Flutter **حقيقى** لصورة PNG.
//
// ليه ملف منفصل: عشان أى تجربة تصميم تستخدمه من غير ما يتكرر، وعشان
// المصايد اللى بتخلّى الصورة تكذب تتحلّ فى مكان واحد:
//
//  🔴 من غير `runAsync` الـ`toImage` بتعلّق للأبد من غير صورة ولا رسالة.
//  🔴 من غير تحميل خط الأيقونات **كل أيقونة بتطلع مربّع** — والصورة تبان
//     «مكسورة» وهى سليمة.
//  🔴 خط بيئة الاختبار مافيهوش عربى، فالكلام بيطلع مربّعات — لازم Cairo
//     (خط التطبيق نفسه) يتحمّل بالـFontLoader.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/privacy.dart';

const String shotsDir = 'build/design_shots';

final GlobalKey _shotKey = GlobalKey();

/// بيحمّل خط التطبيق (Cairo) + خط أيقونات ماتيريال من الـSDK.
Future<void> loadShotFonts() async {
  final cairo = FontLoader('Cairo');
  for (final f in ['Cairo-Regular', 'Cairo-SemiBold', 'Cairo-Bold']) {
    cairo.addFont(rootBundle.load('assets/fonts/$f.ttf'));
  }
  await cairo.load();

  final root = Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter';
  final iconsFile = File(
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
  if (!iconsFile.existsSync()) {
    throw StateError('مالقيتش خط الأيقونات: ${iconsFile.path} — '
        'من غيره كل أيقونة هتطلع مربّع والصورة هتكذب.');
  }
  final bytes = iconsFile.readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(bytes.buffer))))
      .load();
}

/// بيرسم [child] فى مقاس موبايل ويحفظه `<shotsDir>/<name>.png`.
Future<File> shot(
  WidgetTester tester,
  String name,
  Widget child, {
  Size size = const Size(390, 844),
  double pixelRatio = 3,
}) async {
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = size * pixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(RepaintBoundary(key: _shotKey, child: child));
  await tester.pumpAndSettle();

  final boundary =
      _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List png;
  // لازم runAsync: toImage بترجّع Future بيتحلّ برّه الزمن الوهمى.
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    png = data!.buffer.asUint8List();
    img.dispose();
  });

  final dir = Directory(shotsDir)..createSync(recursive: true);
  final file = File('${dir.path}/$name.png')..writeAsBytesSync(png);
  return file;
}

/// غلاف الشاشة: RTL + عربى + الثيم المطلوب + مقاس ثابت.
Widget shotApp(ThemeData theme, Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      // 🔴 الافتراضى مابيدعمش العربى → AppBar بيرمى «No MaterialLocalizations».
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme,
      // 🔴 نفس `builder` بتاع التطبيق الحقيقى. من غيره الهارنس بيبنى
      // MaterialApp **مختلف** عن اللى بيشتغل على الموبايل، فالصورة
      // تطلع شاشة مكشوفة والتطبيق مغطّيها — أداة تحقّق مابتعيدش بناء
      // الإقلاع بتخترع أعطاب وتخبّى حقيقية.
      builder: (_, child) =>
          PrivacyShell(child: child ?? const SizedBox.shrink()),
      home: Directionality(textDirection: TextDirection.rtl, child: home),
    );
