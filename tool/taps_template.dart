// قالب مشية الضغط — بيتولّد منه `tool/taps_test.dart`:
//   python tool/gen_taps.py && flutter test tool/taps_test.dart
//
// الفكرة: الحوارات والشيتات **مابتتبنيش إلا لمّا حد يدوس زرار**، فمسح
// الشاشات (sizes_test.dart) مابيوصلهاش خالص. دى بتفتح كل شاشة وتدوس كل
// زرار فيها وتمسك القصّ اللى بيحصل جوّه الحوار اللى اتفتح.
//
// ⚠️ ده مش ملف اختبار — هو قالب. الاختبار المولَّد هو taps_test.dart.
// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/app_state.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// __IMPORTS__

/// مقاسين بس (مش ٦): الضيّق هو اللى القصّ بيبان فيه، والتابلت عشان
/// الحوارات اللى شكلها بيتغيّر بالعرض. المسح الكامل فى `sizes_test.dart`.
const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'تابلت 800': Size(800, 1280),
};

/// أنواع الودجت اللى بندوس عليها — أزرار وصفوف، مش كل `InkWell` فى الشاشة
/// (ده كان هيخلّى المشية ساعات).
List<Finder> _tapTypes() => <Finder>[
      find.byType(FloatingActionButton),
      find.byType(IconButton),
      find.byType(TextButton),
      find.byType(OutlinedButton),
      find.byType(FilledButton),
      find.byType(ElevatedButton),
      find.byType(ActionChip),
      find.byType(ChoiceChip),
      find.byType(ListTile),
    ];

/// أقصى عدد ضغطات لكل شاشة — عشان زمن المشية مايتفلّتش.
const _maxTaps = 14;

bool _ignorable(Object ex) {
  final s = ex.toString();
  return s.contains('MissingPluginException') ||
      s.contains('Looking up a deactivated') ||
      s.contains('HttpException') ||
      s.contains('Invalid image data');
}

/// بيرجّع وصف القصّ بمكانه — وبيرجّع '' لأى خطأ تانى (المشية بتدوس على
/// أزرار بتودّى لأماكن كتير؛ اللى يهمّنا هنا **القصّ** بس).
String _overflow(FlutterErrorDetails d) {
  final s = d.toString();
  final of =
      RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(s);
  if (of == null) return '';
  final loc =
      RegExp(r'file:///[^\s]*/lib/([^\s:]+\.dart):(\d+)').firstMatch(s);
  final where = loc == null ? '?' : 'lib/${loc.group(1)}:${loc.group(2)}';
  return 'قصّ ${of.group(1)}px ${of.group(2)} @ $where';
}

/// بيدوّر على **نصّ اتخنق لحد ما بقى غير مرئى** — عرضه ≈ صفر وهو محتاج
/// عرض. ده بيحصل لمّا شريط العنوان يبقى فيه أزرار كتير فالعنوان مايلاقيش
/// مكان خالص (اتأكّدت بالصورة: «الجيم» كان مختفى تمامًا على ٣٢٠ ورا ٦ أيقونات).
///
/// ⚠️ جرّبت قبل كده أبلّغ عن أى نصّ `didExceedMaxLines` — طلع **كاذب**:
/// بيبلّغ عن «التنبيهات» و«عدد» وهُمّ ظاهرين تمام (الصور أثبتت). السبب إن
/// `InputDecorator` و`AppBar` بيقيسوا النصّ فى صناديق ضيّقة أثناء التخطيط.
/// القاعدة الوحيدة اللى صمدت قدام الصور هى «العرض ≈ صفر».
List<String> truncatedShortTexts(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize) continue;
    final needed = ro.getMaxIntrinsicWidth(double.infinity);
    if (needed < 4 || ro.size.width >= 4) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    out.add('نصّ مخفى (عرضه صفر): «$txt»');
  }
  return out.toList();
}

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
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

  // 🔴 `AppState._scheduleTimer` مؤقّت **دورى** (كل دقيقة) بيفضل شغّال لو
  // جدول الثيم اتفعّل — وضغطة فى المشية ممكن تفعّله، فكل اختبار بعد كده
  // بيفشل بـ«A Timer is still pending» من غير ما يكون فيه عطب.
  tearDown(() async {
    await AppState.setSchedule(enabled: false);
  });

  // pumpAndSettle ممنوع: فيه شاشات مؤشّرها بيلفّ للأبد فبتعلّق للأبد.
  Future<void> settle(WidgetTester t, [int n = 4]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 220));
    }
    // 🔴 الوقت الوهمى مابيحرّكش نداءات القاعدة الحقيقية (sqflite ffi).
    // من غير التفضية دى، `_load()` بتاعة الشاشة بتخلص وسط الاختبار **اللى
    // بعده** وتجدول مؤقّت هناك فيفشل وهو سليم.
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)));
    await t.pump(const Duration(milliseconds: 220));
  }

  /// بيقفل أى حوار أو صفحة اتفتحت بالضغطة عشان الشاشة ترجع لأصلها.
  Future<void> popAll(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      final navs = find.byType(Navigator);
      if (navs.evaluate().isEmpty) return;
      final NavigatorState nav;
      try {
        nav = t.state<NavigatorState>(navs.first);
      } catch (_) {
        return;
      }
      if (!nav.canPop()) return;
      nav.pop();
      await settle(t, 2);
      t.takeException();
    }
  }

  Future<void> tapWalk(WidgetTester tester, Widget Function() build) async {
    // بنفضّى أى شغل قاعدة بيانات فاضل من الاختبار اللى فات قبل ما نبدأ،
    // عشان مايخلصش فى نصّنا ويجدول مؤقّت علينا.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)));
    final found = <String, List<String>>{};
    for (final e in _sizes.entries) {
      final errs = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        if (_ignorable(d.exception)) return;
        final b = _overflow(d);
        if (b.isNotEmpty) errs.add(b);
      };
      tester.takeException();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      try {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          locale: const Locale('ar'),
          home:
              Directionality(textDirection: TextDirection.rtl, child: build()),
        ));
        await settle(tester);
        errs.addAll(truncatedShortTexts(tester));

        var taps = 0;
        for (final f in _tapTypes()) {
          // 🔴 العدد بيتقاس من جديد كل لفّة: الشجرة بتتغيّر بعد كل ضغطة،
          // فلو خزّنّا العدد مرة واحدة `f.at(i)` بترمى RangeError.
          for (var i = 0; taps < _maxTaps; i++) {
            final Finder target;
            try {
              if (f.evaluate().length <= i) break;
              target = f.at(i);
              if (target.evaluate().isEmpty) continue;
            } catch (_) {
              break;
            }
            taps++;
            try {
              await tester.tap(target, warnIfMissed: false);
              await settle(tester);
            } catch (_) {
              // ضغطة مش ممكنة (مخفية/برّه الشاشة) — مش عطب واجهة.
            }
            errs.addAll(truncatedShortTexts(tester));
            tester.takeException();
            await popAll(tester);
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        // 🔴 لازم نعدّى وقت كفاية عشان المؤقّتات الوحيدة تشتغل قبل ما
        // الاختبار يخلص — `core/log.dart` بيجدول تفريغ بعد ٢ ثانية، وبدون
        // كده ٤٨ شاشة كانت بتفشل بـ«A Timer is still pending» من غير ما
        // يكون فيها عطب أصلاً.
        // ٦ ثوانى وهمية: بتعدّى الـSnackBar (٤ ث) والتوست.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        // 🔴 والأهم: الوقت الوهمى **مابيحرّكش** نداءات القاعدة الحقيقية
        // (sqflite ffi). لو سبناها، بتخلص وسط الاختبار **اللى بعده** وتجدول
        // مؤقّت هناك، فبيفشل بـ«A Timer is still pending» وهو سليم — ده
        // اللى كان بيسقّط ٤٨ شاشة من ١٠٧. `runAsync` بيشغّل الحلقة الحقيقية
        // فبتخلص هنا فى مكانها.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)));
        await tester.pump(const Duration(seconds: 3));
      } finally {
        FlutterError.onError = prev;
        tester.takeException();
      }
      for (final m in errs.toSet()) {
        found.putIfAbsent(m, () => <String>[]).add(e.key);
      }
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
  }

  // __TESTS__
}
