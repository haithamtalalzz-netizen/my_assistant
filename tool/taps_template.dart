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


/// بيقيس القصّ **من شجرة الرسم مباشرة** بدل ما يستنّى بلاغ الإطار.
///
/// 🔴 ليه: استبدال `FlutterError.onError` كان بيبلع بلاغات الإطار، فلمّا
/// يوصل خطأ **غير متزامن** (نداء إضافة بيرمى) بيلاقى حساباته فاضية ويفشل
/// بـ«A test overrode FlutterError.onError …» — ١٩ شاشة كانت بتسقط كده
/// وهى سليمة، ومحاولة تمرير الخطأ للمعالج الأصلى ماحلّتهاش لإن المسار ده
/// مابيعدّيش على `onError` من الأصل.
///
/// الحساب هو نفس اللى `RenderFlex` بيعمله جوّاه: مجموع أطوال الأبناء على
/// المحور مقابل الطول المتاح.
List<String> overflowingFlexes(WidgetTester tester) {
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
    final over = sum - avail;
    if (over <= 0.5) continue;
    final where = _creatorLine(ro);
    final dir = ro.direction == Axis.horizontal ? 'عرضاً' : 'طولاً';
    out.add('قصّ ${over.round()}px $dir @ $where');
  }
  return out.toList();
}

/// بيطلّع «lib/…:سطر» من سلسلة إنشاء الودجت.
String _creatorLine(RenderObject ro) {
  final m = RegExp(r'([\w/]+\.dart):(\d+):\d+')
      .firstMatch(ro.debugCreator?.toString() ?? '');
  return m == null ? '?' : '${m.group(1)}:${m.group(2)}';
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

/// المعالج الأصلى لبلاغات فشل الاختبار — بنغلّفه مش بنلغيه.
final TestExceptionReporter _origReporter = reportTestException;

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    // 🔴 إضافات زى الماسح الضوئى والكاميرا مش موجودة فى بيئة الاختبار،
    // فبترمى `MissingPluginException` — وساعات **بعد ما الاختبار يخلص**
    // فمايقدرش حد يمسحها من جوّه (`takeException` بتشتغل جوّه الاختبار بس).
    // `reportTestException` نقطة رسمية وبتتقرا **قبل** كل اختبار، فتغييرها
    // هنا مرّة واحدة مسموح. ١٩ شاشة كانت بتسقط بالضوضاء دى وهى سليمة.
    reportTestException = (details, description) {
      if (details.exception.toString().contains('MissingPluginException')) {
        return;
      }
      _origReporter(details, description);
    };
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

  /// بتفضّى بلاغات الإطار المتراكمة. `takeException` بتمسك **واحد** كل
  /// مرة، وإضافة زى الماسح الضوئى بترمى أكتر من واحد (channel + stream)،
  /// فمرة واحدة ماتكفيش والباقى بيفشّل الاختبار.
  void clearErrors(WidgetTester t) {
    for (var i = 0; i < 12 && t.takeException() != null; i++) {}
  }

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
    // ٨ لفّات: ضغطة ممكن تفتح شاشة جوّه شاشة (هَب جوّه هَب)، ولو فضلت
    // مفتوحة مؤقّتها الدورى بيفضل شغّال لآخر الاختبار.
    for (var i = 0; i < 8; i++) {
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
      clearErrors(t);
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
      // مفيش استبدال لـ`FlutterError.onError` خالص — بنقيس القصّ من شجرة
      // الرسم، وبنمسح بلاغات الإطار بـ`takeException` زى أى اختبار عادى.
      clearErrors(tester);
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
        errs.addAll(overflowingFlexes(tester));

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
            errs.addAll(overflowingFlexes(tester));
            clearErrors(tester);
            // 🔴 ضغطة على خانة كتابة بتشغّل مؤقّت **وميض المؤشّر**
            // (`EditableTextState._startCursorBlink`، دورى كل ٥٠٠ms)
            // وبيفضل شغّال ما دام فيه تركيز — ده كان أحد سببين بيسقّطوا
            // ٤٩ شاشة بـ«A Timer is still pending» وهى سليمة.
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pump(const Duration(milliseconds: 120));
            await popAll(tester);
          }
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await popAll(tester);
        clearErrors(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        // 🔴 تفضية بالتناوب — ودى اللى حلّت مسألة «A Timer is still
        // pending» اللى كانت بتسقّط ٤٩ شاشة من ١٠٧ وهى سليمة:
        //
        //   • الوقت **الوهمى** بيشغّل المؤقّتات (SnackBar ٤ ث · توست ·
        //     تفريغ السجلّ ٢ ث) لكنه **مابيحرّكش** نداءات قاعدة البيانات.
        //   • `runAsync` بيشغّل الحلقة **الحقيقية** فنداء القاعدة بيخلص،
        //     لكنه ساعتها بيجدول مؤقّتات جديدة (setState → إطار، ديباونس).
        //
        // يعنى مرّة واحدة من كل نوع ماتكفيش: لازم لفّات بالتناوب لحد ما
        // الاتنين يهدوا. من غيرها الشغل الفاضل بيخلص وسط الاختبار **اللى
        // بعده** فيفشل هو.
        for (var round = 0; round < 3; round++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)));
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
          clearErrors(tester);
        }
      } finally {
        clearErrors(tester);
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
