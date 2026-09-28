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
import 'package:my_assistant/screens/account_screen.dart';
import 'package:my_assistant/screens/alerts_center_screen.dart';
import 'package:my_assistant/screens/archived_data_screen.dart';
import 'package:my_assistant/screens/baladna/debts_screen.dart';
import 'package:my_assistant/screens/baladna/gameya_screen.dart';
import 'package:my_assistant/screens/baladna/home_maintenance_screen.dart';
import 'package:my_assistant/screens/baladna/relatives_screen.dart';
import 'package:my_assistant/screens/baladna/savings_screen.dart';
import 'package:my_assistant/screens/brain/charts_screen.dart';
import 'package:my_assistant/screens/brain/chat_screen.dart';
import 'package:my_assistant/screens/brain/insights_screen.dart';
import 'package:my_assistant/screens/calendar_screen.dart';
import 'package:my_assistant/screens/challenges_screen.dart';
import 'package:my_assistant/screens/dashboard_screen.dart';
import 'package:my_assistant/screens/diagnostics_screen.dart';
import 'package:my_assistant/screens/diary_screen.dart';
import 'package:my_assistant/screens/docs/doc_form.dart';
import 'package:my_assistant/screens/docs/docs_screen.dart';
import 'package:my_assistant/screens/emergency_view.dart';
import 'package:my_assistant/screens/food/diet_plans_screen.dart';
import 'package:my_assistant/screens/food/fasting_screen.dart';
import 'package:my_assistant/screens/food/food_card_screen.dart';
import 'package:my_assistant/screens/food/meal_planner_screen.dart';
import 'package:my_assistant/screens/growth/courses_screen.dart';
import 'package:my_assistant/screens/growth/goals_screen.dart';
import 'package:my_assistant/screens/growth/habit_analytics_screen.dart';
import 'package:my_assistant/screens/growth/reading_screen.dart';
import 'package:my_assistant/screens/gym/exercise_library_screen.dart';
import 'package:my_assistant/screens/gym/gym_screen.dart';
import 'package:my_assistant/screens/gym/gym_session_form.dart';
import 'package:my_assistant/screens/gym/progress_screen.dart';
import 'package:my_assistant/screens/gym/walk_tracker_screen.dart';
import 'package:my_assistant/screens/gym/workout_programs_screen.dart';
import 'package:my_assistant/screens/habits/habits_screen.dart';
import 'package:my_assistant/screens/health/cycle_screen.dart';
import 'package:my_assistant/screens/health/health_hub_screen.dart';
import 'package:my_assistant/screens/health/lab_results_screen.dart';
import 'package:my_assistant/screens/health/mood_screen.dart';
import 'package:my_assistant/screens/health/symptom_journal_screen.dart';
import 'package:my_assistant/screens/health/vaccinations_screen.dart';
import 'package:my_assistant/screens/home/pharmacy_form.dart';
import 'package:my_assistant/screens/home/pharmacy_screen.dart';
import 'package:my_assistant/screens/home/plants_screen.dart';
import 'package:my_assistant/screens/inbox_screen.dart';
import 'package:my_assistant/screens/medical/medical_form.dart';
import 'package:my_assistant/screens/medical/medical_screen.dart';
import 'package:my_assistant/screens/money/money_screen.dart';
import 'package:my_assistant/screens/money/subscriptions_screen.dart';
import 'package:my_assistant/screens/money/wallets_screen.dart';
import 'package:my_assistant/screens/money/wishlist_screen.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:my_assistant/screens/passwords/passwords_screen.dart';
import 'package:my_assistant/screens/pets/pets_screen.dart';
import 'package:my_assistant/screens/quit_screen.dart';
import 'package:my_assistant/screens/recipes_screen.dart';
import 'package:my_assistant/screens/reports/calculators_screen.dart';
import 'package:my_assistant/screens/reports/custom_pdf_screen.dart';
import 'package:my_assistant/screens/reports/year_review_screen.dart';
import 'package:my_assistant/screens/reports_hub_screen.dart';
import 'package:my_assistant/screens/rules_screen.dart';
import 'package:my_assistant/screens/schedule/appointment_form.dart';
import 'package:my_assistant/screens/schedule/appointments_calendar_screen.dart';
import 'package:my_assistant/screens/schedule/med_form.dart';
import 'package:my_assistant/screens/schedule/schedule_screen.dart';
import 'package:my_assistant/screens/search_screen.dart';
import 'package:my_assistant/screens/settings_screen.dart';
import 'package:my_assistant/screens/shell.dart';
import 'package:my_assistant/screens/tasks/focus_screen.dart';
import 'package:my_assistant/screens/tasks/tasks_screen.dart';
import 'package:my_assistant/screens/time_machine_screen.dart';
import 'package:my_assistant/screens/today_screen.dart';
import 'package:my_assistant/screens/wardrobe/clothing_form.dart';
import 'package:my_assistant/screens/wardrobe/outfit_screen.dart';
import 'package:my_assistant/screens/wardrobe/wardrobe_screen.dart';
import 'package:my_assistant/screens/weekly/weekly_planning_screen.dart';
import 'package:my_assistant/screens/workout/workout_plan_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_hub_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_reminders_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_situations_screen.dart';
import 'package:my_assistant/screens/worship/daily_wird_screen.dart';
import 'package:my_assistant/screens/worship/duas_screen.dart';
import 'package:my_assistant/screens/worship/fasting_screen.dart';
import 'package:my_assistant/screens/worship/hadith_library_screen.dart';
import 'package:my_assistant/screens/worship/hajj_umrah_screen.dart';
import 'package:my_assistant/screens/worship/islamic_occasions_screen.dart';
import 'package:my_assistant/screens/worship/khatma_screen.dart';
import 'package:my_assistant/screens/worship/mawarith_screen.dart';
import 'package:my_assistant/screens/worship/memorization_screen.dart';
import 'package:my_assistant/screens/worship/monthly_times_screen.dart';
import 'package:my_assistant/screens/worship/names_screen.dart';
import 'package:my_assistant/screens/worship/post_prayer_dhikr_screen.dart';
import 'package:my_assistant/screens/worship/prayer_screen.dart';
import 'package:my_assistant/screens/worship/qibla_screen.dart';
import 'package:my_assistant/screens/worship/quran_search_screen.dart';
import 'package:my_assistant/screens/worship/quran_topics_screen.dart';
import 'package:my_assistant/screens/worship/religious_content_screen.dart';
import 'package:my_assistant/screens/worship/ruqyah_screen.dart';
import 'package:my_assistant/screens/worship/sadaqah_screen.dart';
import 'package:my_assistant/screens/worship/spiritual_stats_screen.dart';
import 'package:my_assistant/screens/worship/tasbih_screen.dart';
import 'package:my_assistant/screens/worship/worship_history_screen.dart';
import 'package:my_assistant/screens/worship/worship_program_screen.dart';
import 'package:my_assistant/screens/worship/zakat_guide_screen.dart';
import 'package:my_assistant/screens/worship/zakat_livestock_screen.dart';
import 'package:my_assistant/screens/worship/zakat_screen.dart';

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
      find.byType(PopupMenuButton<dynamic>),
      find.byType(SwitchListTile),
      find.byType(Card),
    ];

/// أقصى عدد ضغطات لكل شاشة — عشان زمن المشية مايتفلّتش.
const _maxTaps = 20;


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

/// بيطلّع «lib/…:سطر» من سلسلة إنشاء الودجت، ولو مالقاش مسار بيرجّع
/// **أسماء الودجتات** بتاعة التطبيق فى السلسلة — «@ ?» لوحدها مابتفيدش.
String _creatorLine(RenderObject ro) {
  final chain = ro.debugCreator?.toString() ?? '';
  final m = RegExp(r'([\w/]+\.dart):(\d+):\d+').firstMatch(chain);
  if (m != null) return '${m.group(1)}:${m.group(2)}';
  final names = RegExp(r'([A-Z][A-Za-z0-9_]{3,})')
      .allMatches(chain)
      .map((x) => x.group(1)!)
      .where((x) => !x.startsWith('Render'))
      .toSet()
      .take(3)
      .join(' ← ');
  return names.isEmpty ? '?' : names;
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
///
/// 🔴 **مش `final` على مستوى الملف**: `final` فى دارت **بيتقيّم عند أول
/// استعمال** مش عند التشغيل — يعنى كان بياخد قيمته **جوّه** المعالج الجديد
/// بعد ما اتسنده، فيساوى نفسه ويدخل حلقة لانهائية (Stack Overflow على أول
/// خطأ حقيقى). بنمسكه صراحةً فى `setUpAll` قبل الإسناد.
late final TestExceptionReporter _origReporter;

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    // 🔴 إضافات زى الماسح الضوئى والكاميرا مش موجودة فى بيئة الاختبار،
    // فبترمى `MissingPluginException` — وساعات **بعد ما الاختبار يخلص**
    // فمايقدرش حد يمسحها من جوّه (`takeException` بتشتغل جوّه الاختبار بس).
    // `reportTestException` نقطة رسمية وبتتقرا **قبل** كل اختبار، فتغييرها
    // هنا مرّة واحدة مسموح. ١٩ شاشة كانت بتسقط بالضوضاء دى وهى سليمة.
    _origReporter = reportTestException;
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

  testWidgets('AccountScreen', (t) => tapWalk(t, () => const AccountScreen()));
  testWidgets('AdhkarHubScreen', (t) => tapWalk(t, () => const AdhkarHubScreen()));
  testWidgets('AdhkarRemindersScreen', (t) => tapWalk(t, () => const AdhkarRemindersScreen()));
  testWidgets('AdhkarSituationsScreen', (t) => tapWalk(t, () => const AdhkarSituationsScreen()));
  testWidgets('AlertsCenterScreen', (t) => tapWalk(t, () => const AlertsCenterScreen()));
  testWidgets('AppointmentForm', (t) => tapWalk(t, () => const AppointmentForm()));
  testWidgets('AppointmentsCalendarScreen', (t) => tapWalk(t, () => const AppointmentsCalendarScreen()));
  testWidgets('ArchivedDataScreen', (t) => tapWalk(t, () => const ArchivedDataScreen()));
  testWidgets('CalculatorsScreen', (t) => tapWalk(t, () => const CalculatorsScreen()));
  testWidgets('CalendarScreen', (t) => tapWalk(t, () => const CalendarScreen()));
  testWidgets('ChallengesScreen', (t) => tapWalk(t, () => const ChallengesScreen()));
  testWidgets('ChartsScreen', (t) => tapWalk(t, () => const ChartsScreen()));
  testWidgets('ChatScreen', (t) => tapWalk(t, () => const ChatScreen()));
  testWidgets('ClothingForm', (t) => tapWalk(t, () => const ClothingForm()));
  testWidgets('CoursesScreen', (t) => tapWalk(t, () => const CoursesScreen()));
  testWidgets('CustomPdfScreen', (t) => tapWalk(t, () => const CustomPdfScreen()));
  testWidgets('CycleScreen', (t) => tapWalk(t, () => const CycleScreen()));
  testWidgets('DailyWirdScreen', (t) => tapWalk(t, () => const DailyWirdScreen()));
  testWidgets('DashboardScreen', (t) => tapWalk(t, () => const DashboardScreen()));
  testWidgets('DebtsScreen', (t) => tapWalk(t, () => const DebtsScreen()));
  testWidgets('DiagnosticsScreen', (t) => tapWalk(t, () => const DiagnosticsScreen()));
  testWidgets('DiaryScreen', (t) => tapWalk(t, () => const DiaryScreen()));
  testWidgets('DietPlansScreen', (t) => tapWalk(t, () => const DietPlansScreen()));
  testWidgets('DocForm', (t) => tapWalk(t, () => const DocForm()));
  testWidgets('DocsScreen', (t) => tapWalk(t, () => const DocsScreen()));
  testWidgets('DuasScreen', (t) => tapWalk(t, () => const DuasScreen()));
  testWidgets('EmergencyView', (t) => tapWalk(t, () => const EmergencyView()));
  testWidgets('ExerciseLibraryScreen', (t) => tapWalk(t, () => const ExerciseLibraryScreen()));
  testWidgets('FastingScreen', (t) => tapWalk(t, () => const FastingScreen()));
  testWidgets('FocusScreen', (t) => tapWalk(t, () => const FocusScreen()));
  testWidgets('FoodCardScreen', (t) => tapWalk(t, () => const FoodCardScreen()));
  testWidgets('GameyaScreen', (t) => tapWalk(t, () => const GameyaScreen()));
  testWidgets('GoalsScreen', (t) => tapWalk(t, () => const GoalsScreen()));
  testWidgets('GymScreen', (t) => tapWalk(t, () => const GymScreen()));
  testWidgets('GymSessionForm', (t) => tapWalk(t, () => const GymSessionForm()));
  testWidgets('HabitAnalyticsScreen', (t) => tapWalk(t, () => const HabitAnalyticsScreen()));
  testWidgets('HabitsScreen', (t) => tapWalk(t, () => const HabitsScreen()));
  testWidgets('HadithLibraryScreen', (t) => tapWalk(t, () => const HadithLibraryScreen()));
  testWidgets('HajjUmrahScreen', (t) => tapWalk(t, () => const HajjUmrahScreen()));
  testWidgets('HealthHubScreen', (t) => tapWalk(t, () => const HealthHubScreen()));
  testWidgets('HomeMaintenanceScreen', (t) => tapWalk(t, () => const HomeMaintenanceScreen()));
  testWidgets('InboxScreen', (t) => tapWalk(t, () => const InboxScreen()));
  testWidgets('InsightsScreen', (t) => tapWalk(t, () => const InsightsScreen()));
  testWidgets('IslamicOccasionsScreen', (t) => tapWalk(t, () => const IslamicOccasionsScreen()));
  testWidgets('KhatmaScreen', (t) => tapWalk(t, () => const KhatmaScreen()));
  testWidgets('LabResultsScreen', (t) => tapWalk(t, () => const LabResultsScreen()));
  testWidgets('MawarithScreen', (t) => tapWalk(t, () => const MawarithScreen()));
  testWidgets('MealPlannerScreen', (t) => tapWalk(t, () => const MealPlannerScreen()));
  testWidgets('MedForm', (t) => tapWalk(t, () => const MedForm()));
  testWidgets('MedicalForm', (t) => tapWalk(t, () => const MedicalForm()));
  testWidgets('MedicalScreen', (t) => tapWalk(t, () => const MedicalScreen()));
  testWidgets('MedsScreen', (t) => tapWalk(t, () => const MedsScreen()));
  testWidgets('MemorizationScreen', (t) => tapWalk(t, () => const MemorizationScreen()));
  testWidgets('MoneyScreen', (t) => tapWalk(t, () => const MoneyScreen()));
  testWidgets('MonthlyTimesScreen', (t) => tapWalk(t, () => const MonthlyTimesScreen()));
  testWidgets('MoodScreen', (t) => tapWalk(t, () => const MoodScreen()));
  testWidgets('NafilFastingScreen', (t) => tapWalk(t, () => const NafilFastingScreen()));
  testWidgets('NamesScreen', (t) => tapWalk(t, () => const NamesScreen()));
  testWidgets('NotesScreen', (t) => tapWalk(t, () => const NotesScreen()));
  testWidgets('OutfitScreen', (t) => tapWalk(t, () => const OutfitScreen()));
  testWidgets('PasswordsScreen', (t) => tapWalk(t, () => const PasswordsScreen()));
  testWidgets('PetsScreen', (t) => tapWalk(t, () => const PetsScreen()));
  testWidgets('PharmacyForm', (t) => tapWalk(t, () => const PharmacyForm()));
  testWidgets('PharmacyScreen', (t) => tapWalk(t, () => const PharmacyScreen()));
  testWidgets('PlantsScreen', (t) => tapWalk(t, () => const PlantsScreen()));
  testWidgets('PostPrayerDhikrScreen', (t) => tapWalk(t, () => const PostPrayerDhikrScreen()));
  testWidgets('PrayerScreen', (t) => tapWalk(t, () => const PrayerScreen()));
  testWidgets('ProgressScreen', (t) => tapWalk(t, () => const ProgressScreen()));
  testWidgets('QiblaScreen', (t) => tapWalk(t, () => const QiblaScreen()));
  testWidgets('QuitScreen', (t) => tapWalk(t, () => const QuitScreen()));
  testWidgets('QuranSearchScreen', (t) => tapWalk(t, () => const QuranSearchScreen()));
  testWidgets('QuranTopicsScreen', (t) => tapWalk(t, () => const QuranTopicsScreen()));
  testWidgets('ReadingScreen', (t) => tapWalk(t, () => const ReadingScreen()));
  testWidgets('RecipesScreen', (t) => tapWalk(t, () => const RecipesScreen()));
  testWidgets('RelativesScreen', (t) => tapWalk(t, () => const RelativesScreen()));
  testWidgets('ReligiousContentScreen', (t) => tapWalk(t, () => const ReligiousContentScreen()));
  testWidgets('ReportsHubScreen', (t) => tapWalk(t, () => const ReportsHubScreen()));
  testWidgets('RulesScreen', (t) => tapWalk(t, () => const RulesScreen()));
  testWidgets('RuqyahScreen', (t) => tapWalk(t, () => const RuqyahScreen()));
  testWidgets('SadaqahScreen', (t) => tapWalk(t, () => const SadaqahScreen()));
  testWidgets('SavingsScreen', (t) => tapWalk(t, () => const SavingsScreen()));
  testWidgets('ScheduleScreen', (t) => tapWalk(t, () => const ScheduleScreen()));
  testWidgets('SearchScreen', (t) => tapWalk(t, () => const SearchScreen()));
  testWidgets('SettingsScreen', (t) => tapWalk(t, () => const SettingsScreen()));
  testWidgets('Shell', (t) => tapWalk(t, () => const Shell()));
  testWidgets('SpiritualStatsScreen', (t) => tapWalk(t, () => const SpiritualStatsScreen()));
  testWidgets('SubscriptionsScreen', (t) => tapWalk(t, () => const SubscriptionsScreen()));
  testWidgets('SymptomJournalScreen', (t) => tapWalk(t, () => const SymptomJournalScreen()));
  testWidgets('TasbihScreen', (t) => tapWalk(t, () => const TasbihScreen()));
  testWidgets('TasksScreen', (t) => tapWalk(t, () => const TasksScreen()));
  testWidgets('TimeMachineScreen', (t) => tapWalk(t, () => const TimeMachineScreen()));
  testWidgets('TodayScreen', (t) => tapWalk(t, () => const TodayScreen()));
  testWidgets('VaccinationsScreen', (t) => tapWalk(t, () => const VaccinationsScreen()));
  testWidgets('WalkTrackerScreen', (t) => tapWalk(t, () => const WalkTrackerScreen()));
  testWidgets('WalletsScreen', (t) => tapWalk(t, () => const WalletsScreen()));
  testWidgets('WardrobeScreen', (t) => tapWalk(t, () => const WardrobeScreen()));
  testWidgets('WeeklyPlanningScreen', (t) => tapWalk(t, () => const WeeklyPlanningScreen()));
  testWidgets('WishlistScreen', (t) => tapWalk(t, () => const WishlistScreen()));
  testWidgets('WorkoutPlanScreen', (t) => tapWalk(t, () => const WorkoutPlanScreen()));
  testWidgets('WorkoutProgramsScreen', (t) => tapWalk(t, () => const WorkoutProgramsScreen()));
  testWidgets('WorshipHistoryScreen', (t) => tapWalk(t, () => const WorshipHistoryScreen()));
  testWidgets('WorshipProgramScreen', (t) => tapWalk(t, () => const WorshipProgramScreen()));
  testWidgets('YearReviewScreen', (t) => tapWalk(t, () => const YearReviewScreen()));
  testWidgets('ZakatGuideScreen', (t) => tapWalk(t, () => const ZakatGuideScreen()));
  testWidgets('ZakatLivestockScreen', (t) => tapWalk(t, () => const ZakatLivestockScreen()));
  testWidgets('ZakatScreen', (t) => tapWalk(t, () => const ZakatScreen()));
}
