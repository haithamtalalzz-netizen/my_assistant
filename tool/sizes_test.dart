// **مولَّد** — كل شاشة × ٦ مقاسات (موبايل صغير → تابلت كبير).
// الغرض: **مفيش حاجة مقصوصة** على أى مقاس. تجاوز الحدود بيتبلّغ كاستثناء
// رسم فبيتمسك هنا بمكانه فى الكود؛ الاختبار الوظيفى مابيشوفهوش.
//   flutter test tool/sizes_test.dart
// التوليد: tool/gen_sizes.py
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';
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
import 'package:my_assistant/screens/docs/doc_form.dart';
import 'package:my_assistant/screens/docs/docs_screen.dart';
import 'package:my_assistant/screens/emergency_view.dart';
import 'package:my_assistant/screens/food/barcode_scan_screen.dart';
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
import 'package:my_assistant/screens/health/my_health_screen.dart';
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
import 'package:my_assistant/screens/watch_help_screen.dart';
import 'package:my_assistant/screens/shell.dart';
import 'package:my_assistant/screens/tasks/focus_screen.dart';
import 'package:my_assistant/screens/tasks/tasks_screen.dart';
import 'package:my_assistant/screens/today_screen.dart';
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
import 'package:my_assistant/screens/day_full_screen.dart';
import 'package:my_assistant/screens/health/meds_hub_screen.dart';

/// مقاسات حقيقية: أصغر أندرويد شائع → تابلت كبير بالعرض.
const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'موبايل عادى 360': Size(360, 800),
  'موبايل كبير 414': Size(414, 896),
  'فولد مفتوح 673': Size(673, 841),
  'تابلت 800': Size(800, 1280),
  'تابلت كبير 1024': Size(1024, 1366),
};

bool _ignorable(Object ex) {
  final s = ex.toString();
  return s.contains('MissingPluginException') ||
      s.contains('Looking up a deactivated') ||
      s.contains('HttpException') ||
      s.contains('Invalid image data');
}

/// بيطلّع من تقرير الخطأ: نوع القصّ + **مكانه فى الكود**.
String _brief(FlutterErrorDetails d) {
  final s = d.toString();
  final of =
      RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(s);
  final loc =
      RegExp(r'file:///[^\s]*/lib/([^\s:]+\.dart):(\d+)').firstMatch(s);
  final where = loc == null ? '?' : 'lib/${loc.group(1)}:${loc.group(2)}';
  if (of != null) return 'قصّ ${of.group(1)}px ${of.group(2)} @ $where';
  return '${d.exception.toString().split("\n").first} @ $where';
}

/// بيدوّر على **نصّ اتخنق لحد ما بقى غير مرئى** — عرضه ≈ صفر وهو محتاج
/// عرض. ده بيحصل لمّا شريط العنوان يبقى فيه أزرار كتير فالعنوان مايلاقيش
/// مكان خالص (اتأكّدت بالصورة: «الجيم» كان مختفى تمامًا على ٣٢٠ ورا ٦ أيقونات).
///
/// ⚠️ جرّبت قبل كده أبلّغ عن أى نصّ `didExceedMaxLines` — طلع **كاذب**:
/// بيبلّغ عن «التنبيهات» و«عدد» وهُمّ ظاهرين تمام (الصور أثبتت). السبب إن
/// `InputDecorator` و`AppBar` بيقيسوا النصّ فى صناديق ضيّقة أثناء التخطيط.
/// القاعدة الوحيدة اللى صمدت قدام الصور هى «العرض ≈ صفر».
List<String> _truncatedShort(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize) continue;
    final needed = ro.getMaxIntrinsicWidth(double.infinity);
    if (needed < 4 || ro.size.width >= 4) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    // 🔴 Flutter بيرسم Icon كـRichText بحرف من منطقة الاستعمال الخاص،
    // وخط الأيقونات ارتفاع سطره أكبر من مقاس الأيقونة — فأى أيقونة جوّه
    // صندوق ضيّق كانت بتتبلّغ كأنها «نصّ متقصوص»، والرسالة تطلع «» لإن
    // الحرف مالوش شكل. الأيقونة مش نصّ، فبتتعدّى.
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    out.add('نصّ مخفى (عرضه صفر): «$txt»');
  }
  return out.toList();
}

/// بيدوّر على **نصّ متقصوص من فوق/تحت** — صندوقه أقصر من اللى محتاجه.
/// نوع تالت من القصّ، و**مابيظهرش من غير خطّ التطبيق** (بيئة الاختبار
/// بتقيس العربى بخطّ مقاساته مختلفة).
List<String> _vClipped(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1) continue;
    // 🔴 القاعدة الوحيدة اللى مافيهاش لبس: **الصندوق أقصر من سطر واحد**،
    // يعنى النصّ مستحيل يبان كامل مهما كان.
    //
    // جرّبت الأوسع منها مرّتين وكانت بتكذب: `getMaxIntrinsicHeight`
    // بترجّع ارتفاع أقصى عدد سطور مسموح، و`TextPainter` بعرض الصندوق
    // بيحسب اللفّ — والاتنين بلّغوا عن كروت اللوحة وعناوين الشاشات وهى
    // ظاهرة تمام (الصور أثبتت). ده كان بيطلّع ١٣ بلاغ أغلبها كاذب.
    final line = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: 1,
      textScaler: ro.textScaler,
    )..layout();
    if (ro.size.height >= line.height - 0.5) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    // 🔴 Flutter بيرسم Icon كـRichText بحرف من منطقة الاستعمال الخاص،
    // وخط الأيقونات ارتفاع سطره أكبر من مقاس الأيقونة — فأى أيقونة جوّه
    // صندوق ضيّق كانت بتتبلّغ كأنها «نصّ متقصوص»، والرسالة تطلع «» لإن
    // الحرف مالوش شكل. الأيقونة مش نصّ، فبتتعدّى.
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    out.add('نصّ متقصوص طولاً (${ro.size.height.round()} من '
        '${line.height.round()}): «$txt»');
  }
  return out.toList();
}

/// هل العنصر ده جوّه خانة إدخال؟ (`InputDecorator` بيقيس بشكل مضلّل.)
bool _insideInputDecorator(RenderObject ro) {
  RenderObject? n = ro.parent;
  var depth = 0;
  while (n != null && depth < 12) {
    final t = n.runtimeType.toString();
    if (t.contains('Decoration') || t.contains('InputDecorator')) return true;
    n = n.parent;
    depth++;
  }
  return false;
}

/// بيدوّر على **نصّ اتشرح من نُصّه**: الصندوق أقصر من الارتفاع اللى
/// النصّ محتاجه فعلاً جوّه عرضه — فآخر سطر بيتقطع نُصّين.
///
/// ده نوع رابع من القصّ **ماكانش بيتمسك**: `_vClipped` بتفحص «الصندوق
/// أقصر من سطر واحد»، فصندوق بيسع سطر ونُص بيعدّى. وFlutter مابيرميش
/// استثناء لإن `SizedBox` بتقصّ من غير شكوى — مش زى `Row`/`Column`.
///
/// اتكشف من صورة موبايل: كروت «كروتك» صندوق سطرها التحت ٢٦ والسطرين
/// محتاجين ٢٨، فنُص سطر كان بيتقطع على **كل** المقاسات والأداة خضرا.
///
/// القاعدة مضبوطة عن قصد: بنقيس بنفس `maxLines` وبنفس العرض الفعلى،
/// فالنصّ اللى بينتهى بـ«…» سليم (ده اختصار مقصود مش قصّ)، واللى
/// بيتقطع بالعرض بس هو اللى بيتبلّغ.
List<String> _slicedLine(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1 || ro.size.height < 1) continue;
    final txt = ro.text.toPlainText().trim();
    if (txt.isEmpty) continue;
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    // 🔴 عناوين خانات الإدخال **بتكذب**: `InputDecorator` بيقيس العنوان
    // فى صندوق ضيّق وبيصغّره بـTransform وهو بيعوّم، فالصندوق المقاس
    // أصغر من الكلام والنصّ مع ذلك ظاهر تمام. اتأكدت بالصورة: فورم على
    // ٣٢٠ بكل خاناته والعناوين سليمة، والكاشف كان بيبلّغ عن ٧ منها.
    if (_insideInputDecorator(ro)) continue;
    final tp = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: ro.maxLines,
      textScaler: ro.textScaler,
    )..layout(maxWidth: ro.size.width);
    // بكسل واحد سماح لفروق التقريب.
    if (tp.height <= ro.size.height + 1) continue;
    out.add('سطر متشرح (صندوق ${ro.size.height.round()} / محتاج '
        '${tp.height.round()}): «$txt»');
  }
  return out.toList();
}

void main() {
  sqfliteFfiInit();
  // ضغطة على «النسخة الاحتياطية» بتفتح القاعدة **بمسارها** مش عبر
  // `AppDb`، فبيئة الاختبار لازم يبقى فيها مصنع ومجلّد — نقص فى البيئة
  // مش عطب فى التطبيق.
  databaseFactory = databaseFactoryFfiNoIsolate;
  Directory('.dart_tool/sqflite_common_ffi/databases')
      .createSync(recursive: true);
  late Database db;

  setUpAll(() async {
    // من غير خطّ التطبيق، قياس العربى بيكذب (شوف `_vClipped`).
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

  /// بيرسم الشاشة على كل المقاسات ويجمع كل قصّ بمكانه.
  Future<void> sweep(WidgetTester tester, Widget Function() build) async {
    final found = <String, List<String>>{};
    for (final e in _sizes.entries) {
      final errs = <String>[];
      final prev = FlutterError.onError;
      // بنلقط الأخطاء بنفسنا عشان نشوف **كلها** مش أول واحد بس.
      FlutterError.onError = (d) {
        if (!_ignorable(d.exception)) errs.add(_brief(d));
      };
      tester.takeException();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      try {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          locale: const Locale('ar'),
          home: Directionality(
              textDirection: TextDirection.rtl, child: build()),
        ));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        errs.addAll(_truncatedShort(tester));
        errs.addAll(_vClipped(tester));
        errs.addAll(_slicedLine(tester));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 150));
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

  testWidgets('AccountScreen', (t) => sweep(t, () => const AccountScreen()));
  testWidgets('AdhkarHubScreen', (t) => sweep(t, () => const AdhkarHubScreen()));
  testWidgets('AdhkarRemindersScreen', (t) => sweep(t, () => const AdhkarRemindersScreen()));
  testWidgets('AdhkarSituationsScreen', (t) => sweep(t, () => const AdhkarSituationsScreen()));
  testWidgets('AlertsCenterScreen', (t) => sweep(t, () => const AlertsCenterScreen()));
  testWidgets('AppointmentForm', (t) => sweep(t, () => const AppointmentForm()));
  testWidgets('AppointmentsCalendarScreen', (t) => sweep(t, () => const AppointmentsCalendarScreen()));
  testWidgets('ArchivedDataScreen', (t) => sweep(t, () => const ArchivedDataScreen()));
  testWidgets('BarcodeScanScreen', (t) => sweep(t, () => const BarcodeScanScreen()));
  testWidgets('CalculatorsScreen', (t) => sweep(t, () => const CalculatorsScreen()));
  testWidgets('CalendarScreen', (t) => sweep(t, () => const CalendarScreen()));
  testWidgets('ChallengesScreen', (t) => sweep(t, () => const ChallengesScreen()));
  testWidgets('ChartsScreen', (t) => sweep(t, () => const ChartsScreen()));
  testWidgets('ChatScreen', (t) => sweep(t, () => const ChatScreen()));
  testWidgets('CoursesScreen', (t) => sweep(t, () => const CoursesScreen()));
  testWidgets('CustomPdfScreen', (t) => sweep(t, () => const CustomPdfScreen()));
  testWidgets('CycleScreen', (t) => sweep(t, () => const CycleScreen()));
  testWidgets('DailyWirdScreen', (t) => sweep(t, () => const DailyWirdScreen()));
  testWidgets('DashboardScreen', (t) => sweep(t, () => const DashboardScreen()));
  testWidgets('DayFullScreen', (t) => sweep(t, () => DayFullScreen(
          events: const [],
          onToggle: (e, v) async => const [],
          onOpen: (_) {})));
  testWidgets('DebtsScreen', (t) => sweep(t, () => const DebtsScreen()));
  testWidgets('DiagnosticsScreen', (t) => sweep(t, () => const DiagnosticsScreen()));
  testWidgets('DietPlansScreen', (t) => sweep(t, () => const DietPlansScreen()));
  testWidgets('DocForm', (t) => sweep(t, () => const DocForm()));
  testWidgets('DocsScreen', (t) => sweep(t, () => const DocsScreen()));
  testWidgets('DuasScreen', (t) => sweep(t, () => const DuasScreen()));
  testWidgets('EmergencyView', (t) => sweep(t, () => const EmergencyView()));
  testWidgets('ExerciseLibraryScreen', (t) => sweep(t, () => const ExerciseLibraryScreen()));
  testWidgets('FastingScreen', (t) => sweep(t, () => const FastingScreen()));
  testWidgets('FocusScreen', (t) => sweep(t, () => const FocusScreen()));
  testWidgets('FoodCardScreen', (t) => sweep(t, () => const FoodCardScreen()));
  testWidgets('GameyaScreen', (t) => sweep(t, () => const GameyaScreen()));
  testWidgets('GoalsScreen', (t) => sweep(t, () => const GoalsScreen()));
  testWidgets('GymScreen', (t) => sweep(t, () => const GymScreen()));
  testWidgets('GymSessionForm', (t) => sweep(t, () => const GymSessionForm()));
  testWidgets('HabitAnalyticsScreen', (t) => sweep(t, () => const HabitAnalyticsScreen()));
  testWidgets('HabitsScreen', (t) => sweep(t, () => const HabitsScreen()));
  testWidgets('HadithLibraryScreen', (t) => sweep(t, () => const HadithLibraryScreen()));
  testWidgets('HajjUmrahScreen', (t) => sweep(t, () => const HajjUmrahScreen()));
  testWidgets('HealthHubScreen', (t) => sweep(t, () => const HealthHubScreen()));
  testWidgets('MyHealthScreen', (t) => sweep(t, () => const MyHealthScreen()));
  testWidgets('HomeMaintenanceScreen', (t) => sweep(t, () => const HomeMaintenanceScreen()));
  testWidgets('InboxScreen', (t) => sweep(t, () => const InboxScreen()));
  testWidgets('InsightsScreen', (t) => sweep(t, () => const InsightsScreen()));
  testWidgets('IslamicOccasionsScreen', (t) => sweep(t, () => const IslamicOccasionsScreen()));
  testWidgets('KhatmaScreen', (t) => sweep(t, () => const KhatmaScreen()));
  testWidgets('LabResultsScreen', (t) => sweep(t, () => const LabResultsScreen()));
  testWidgets('MawarithScreen', (t) => sweep(t, () => const MawarithScreen()));
  testWidgets('MealPlannerScreen', (t) => sweep(t, () => const MealPlannerScreen()));
  testWidgets('MedForm', (t) => sweep(t, () => const MedForm()));
  testWidgets('MedicalForm', (t) => sweep(t, () => const MedicalForm()));
  testWidgets('MedicalScreen', (t) => sweep(t, () => const MedicalScreen()));
  testWidgets('MedsScreen', (t) => sweep(t, () => const MedsScreen()));
  testWidgets('MedsHubScreen', (t) => sweep(t, () => const MedsHubScreen()));
  testWidgets('MemorizationScreen', (t) => sweep(t, () => const MemorizationScreen()));
  testWidgets('MoneyScreen', (t) => sweep(t, () => const MoneyScreen()));
  testWidgets('MonthlyTimesScreen', (t) => sweep(t, () => const MonthlyTimesScreen()));
  testWidgets('MoodScreen', (t) => sweep(t, () => const MoodScreen()));
  testWidgets('NafilFastingScreen', (t) => sweep(t, () => const NafilFastingScreen()));
  testWidgets('NamesScreen', (t) => sweep(t, () => const NamesScreen()));
  testWidgets('NotesScreen', (t) => sweep(t, () => const NotesScreen()));
  testWidgets('PasswordsScreen', (t) => sweep(t, () => const PasswordsScreen()));
  testWidgets('PetsScreen', (t) => sweep(t, () => const PetsScreen()));
  testWidgets('PharmacyForm', (t) => sweep(t, () => const PharmacyForm()));
  testWidgets('PharmacyScreen', (t) => sweep(t, () => const PharmacyScreen()));
  testWidgets('PlantsScreen', (t) => sweep(t, () => const PlantsScreen()));
  testWidgets('PostPrayerDhikrScreen', (t) => sweep(t, () => const PostPrayerDhikrScreen()));
  testWidgets('PrayerScreen', (t) => sweep(t, () => const PrayerScreen()));
  testWidgets('ProgressScreen', (t) => sweep(t, () => const ProgressScreen()));
  testWidgets('QiblaScreen', (t) => sweep(t, () => const QiblaScreen()));
  testWidgets('QuitScreen', (t) => sweep(t, () => const QuitScreen()));
  testWidgets('QuranSearchScreen', (t) => sweep(t, () => const QuranSearchScreen()));
  testWidgets('QuranTopicsScreen', (t) => sweep(t, () => const QuranTopicsScreen()));
  testWidgets('ReadingScreen', (t) => sweep(t, () => const ReadingScreen()));
  testWidgets('RecipesScreen', (t) => sweep(t, () => const RecipesScreen()));
  testWidgets('RelativesScreen', (t) => sweep(t, () => const RelativesScreen()));
  testWidgets('ReligiousContentScreen', (t) => sweep(t, () => const ReligiousContentScreen()));
  testWidgets('ReportsHubScreen', (t) => sweep(t, () => const ReportsHubScreen()));
  testWidgets('RulesScreen', (t) => sweep(t, () => const RulesScreen()));
  testWidgets('RuqyahScreen', (t) => sweep(t, () => const RuqyahScreen()));
  testWidgets('SadaqahScreen', (t) => sweep(t, () => const SadaqahScreen()));
  testWidgets('SavingsScreen', (t) => sweep(t, () => const SavingsScreen()));
  testWidgets('ScheduleScreen', (t) => sweep(t, () => const ScheduleScreen()));
  testWidgets('SearchScreen', (t) => sweep(t, () => const SearchScreen()));
  testWidgets('SettingsScreen', (t) => sweep(t, () => const SettingsScreen()));
  testWidgets('WatchHelpScreen', (t) => sweep(t, () => const WatchHelpScreen()));
  testWidgets('Shell', (t) => sweep(t, () => const Shell()));
  testWidgets('SpiritualStatsScreen', (t) => sweep(t, () => const SpiritualStatsScreen()));
  testWidgets('SubscriptionsScreen', (t) => sweep(t, () => const SubscriptionsScreen()));
  testWidgets('SymptomJournalScreen', (t) => sweep(t, () => const SymptomJournalScreen()));
  testWidgets('TasbihScreen', (t) => sweep(t, () => const TasbihScreen()));
  testWidgets('TasksScreen', (t) => sweep(t, () => const TasksScreen()));
  testWidgets('TodayScreen', (t) => sweep(t, () => const TodayScreen()));
  testWidgets('VaccinationsScreen', (t) => sweep(t, () => const VaccinationsScreen()));
  testWidgets('WalkTrackerScreen', (t) => sweep(t, () => const WalkTrackerScreen()));
  testWidgets('WalletsScreen', (t) => sweep(t, () => const WalletsScreen()));
  testWidgets('WeeklyPlanningScreen', (t) => sweep(t, () => const WeeklyPlanningScreen()));
  testWidgets('WishlistScreen', (t) => sweep(t, () => const WishlistScreen()));
  testWidgets('WorkoutPlanScreen', (t) => sweep(t, () => const WorkoutPlanScreen()));
  testWidgets('WorkoutProgramsScreen', (t) => sweep(t, () => const WorkoutProgramsScreen()));
  testWidgets('WorshipHistoryScreen', (t) => sweep(t, () => const WorshipHistoryScreen()));
  testWidgets('WorshipProgramScreen', (t) => sweep(t, () => const WorshipProgramScreen()));
  testWidgets('YearReviewScreen', (t) => sweep(t, () => const YearReviewScreen()));
  testWidgets('ZakatGuideScreen', (t) => sweep(t, () => const ZakatGuideScreen()));
  testWidgets('ZakatLivestockScreen', (t) => sweep(t, () => const ZakatLivestockScreen()));
  testWidgets('ZakatScreen', (t) => sweep(t, () => const ZakatScreen()));
}
