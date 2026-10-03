// «المتابعة والأدوات» — الأرقام اللى على الأبواب، والأبواب اللى اتشالت.
//
// الشاشة بقت قايمة بأرقامها، والأرقام دى هى اللى الصورة مابتكشفهاش:
// الصورة تقول «١» مرسومة فى مكانها الصح، بس مش تقول إن الـ«١» معناها
// «قاعدة واحدة بتتحقق» مش «قاعدة واحدة موجودة» — والفرق بين الاتنين هو
// كل سبب وجود الرقم.
//
// وفيه كمان اللى اتشال: «آلة الزمن» و«مركز التنبيهات» و«التقارير» كانوا
// تلات أبواب بتودّى لحاجة موجودة فى مكان تانى. الاختبارات هنا بتثبّت إنهم
// مش راجعين من غير ما حد ياخد القرار تانى.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/hub_stats.dart';
import 'package:my_assistant/data/rules_repo.dart';
import 'package:my_assistant/data/weekly_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/calendar_screen.dart';
import 'package:my_assistant/screens/reports_hub_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  group('أرقام المتابعة والأدوات', () {
    test('البند الفاضى بيسكت — مابيقولش صفر', () async {
      // «0» بتتقرا كأن حاجة اتحسبت وطلعت صفر. الفاضى حاجة تانية خالص،
      // فالسطر المفروض يسكت لحد ما يبقى عنده حاجة يقولها.
      expect(await chartsStat(), isNull);
      expect(await calendarStat(), isNull);
      expect(await inboxStat(), isNull);
      expect(await docsStat(), isNull);
      expect(await rulesStat(), isNull);
    });

    test('الرسوم بتعدّ اللى فيه بيانات، مش اللى موجود', () async {
      // شاشة الرسوم فيها ٨ رسوم على طول. الرقم المفيد هو كام واحد فيهم
      // هيرسم فعلاً — الباقى صندوق فاضى.
      await db.insert('sleep_logs', {'day': dayKey(DateTime.now()), 'hours': 7.5});
      var stat = await chartsStat();
      expect(stat!.big, arNum(1));

      await db.insert('measurements', {
        'type': 'وزن',
        'value': 95,
        'day': dayKey(DateTime.now()),
      });
      stat = await chartsStat();
      expect(stat!.big, arNum(2));
    });

    test('نوم قديم مش رسم: الرسم آخر ٣٠ يوم', () async {
      // الرسم بيقرا آخر ٣٠ يوم بس، فسجل من سنة مايتحسبش — غير كده الرقم
      // يوعد برسم والشاشة تفتح فاضية.
      final old = dateOnly(DateTime.now()).subtract(const Duration(days: 400));
      await db.insert('sleep_logs', {'day': dayKey(old), 'hours': 7});
      expect(await chartsStat(), isNull);
    });

    test('قواعدى بتقول «بتتحقق» مش «موجودة»', () async {
      final repo = RulesRepo();
      // على قاعدة بيانات فاضية: خطوات النهاردة = 0.
      await repo.add(const CustomRule(
          metric: 'today_steps', op: '<', threshold: 10000, message: 'امشى'));
      await repo.add(const CustomRule(
          metric: 'today_steps', op: '>', threshold: 10000, message: 'برافو'));

      final stat = await rulesStat();
      // قاعدتين موجودين، واحدة بس بتتحقق.
      expect(stat!.big, arNum(1));
      expect(stat.bigSub, 'بتتحقق');
      expect(stat.bigColor, isNotNull, reason: 'الرقم اللى بيناديك لازم ملوّن');
    });

    test('مفيش قاعدة بتتحقق ← بيقول العدد بلون عادى', () async {
      await RulesRepo().add(const CustomRule(
          metric: 'today_steps', op: '>', threshold: 10000, message: 'برافو'));
      final stat = await rulesStat();
      expect(stat!.big, arNum(1));
      expect(stat.bigSub, 'قاعدة');
      expect(stat.bigColor, isNull);
    });

    test('القاعدة المقفولة مابتتحسبش', () async {
      await RulesRepo().add(const CustomRule(
          metric: 'today_steps',
          op: '<',
          threshold: 10000,
          message: 'امشى',
          enabled: false));
      final stat = await rulesStat();
      expect(stat!.bigSub, 'قاعدة', reason: 'مقفولة = مابتتحققش');
    });

    test('التخطيط الأسبوعى بيقول آخر مرة، مش عدد', () async {
      // البند ده مالوش «عدد» يستحق يتقال — السؤال الوحيد عنه: عملته
      // الأسبوع ده ولا لأ.
      var stat = await weeklyPlanStat();
      expect(stat!.sub, contains('طقس'));
      expect(stat.big, isNull);

      final now = DateTime.now();
      await WeeklyRepo().save(WeeklyReview(
        weekKey: currentWeekKey(now),
        wentWell: 'تمام',
        createdAt: now.toIso8601String(),
      ));
      stat = await weeklyPlanStat();
      expect(stat!.sub, 'خطّطت الأسبوع ده');
    });

    test('مراجعة قديمة بتطلع حمرا', () async {
      final old = DateTime.now().subtract(const Duration(days: 21));
      await WeeklyRepo().save(WeeklyReview(
        weekKey: currentWeekKey(old),
        wentWell: 'تمام',
        createdAt: old.toIso8601String(),
      ));
      final stat = await weeklyPlanStat();
      expect(stat!.bigColor, isNotNull);
    });

    test('المستندات بتقول عددها', () async {
      // بنكتب فى الجدول على طول: `DocsRepo.save` بتجدّد تنبيه،
      // والتنبيهات مالهاش قناة فى الاختبار.
      await db.insert('documents', {'title': 'البطاقة', 'type': 'id'});
      final stat = await docsStat();
      expect(stat!.big, arNum(1));
    });

    test('الحاسبات والتقارير أرقامهم ثابتة وبتوصف اللى جوّه', () async {
      // الاتنين دول مالهمش بيانات، فرقمهم هو عدد الأدوات اللى جوّه —
      // ولو حد زوّد أداة ونسى الرقم، الاختبار ده هو اللى يقوله.
      expect((await pdfReportsStat())!.big, arNum(3));
      expect((await calculatorsStat())!.big, arNum(8));
    });
  });

  group('الأبواب اللى اتشالت', () {
    testWidgets('«تقارير PDF» مابقاش فيها إحصائيات ولا رؤى', (tester) async {
      // الشاشة دى كانت طبقة: جوّاها «إحصائياتك» و«رؤى المدير» وهُمّ
      // بنود مستقلة فى **نفس** الهَب. فبقت للورق بس.
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('ar')],
        home: ReportsHubScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('تقارير PDF'), findsOneWidget);
      expect(find.text('إحصائياتك'), findsNothing);
      expect(find.text('رؤى المدير'), findsNothing);
      // والتلاتة الورقية لازم يفضلوا.
      expect(find.textContaining('تقرير مخصّص'), findsOneWidget);
      expect(find.textContaining('ملخص الشهر'), findsOneWidget);
      expect(find.textContaining('تقرير الدكتور'), findsOneWidget);
    });

    test('«آلة الزمن» اتشالت كشاشة', () async {
      // الشاشة اتدمجت فى التقويم (السهمين اللى بيمشّوا بين الأيام).
      // الملف نفسه اتمسح، فأى محاولة ترجّعه هتتكسر فى الـanalyze —
      // والاختبار ده موجود عشان يقول **ليه** اتشالت لما حد يسأل.
      expect(
        await File('lib/screens/time_machine_screen.dart').exists(),
        isFalse,
      );
    });
  });

  group('ورقة اليوم فى التقويم — بديل «آلة الزمن»', () {
    testWidgets('فيها سهمين تمشّى بيهم بين الأيام', (tester) async {
      // ده **الشرط** اللى خلّى دمج «آلة الزمن» قرار مش خسارة: لو السهمين
      // مش موجودين يبقى احنا شِلنا شاشة وشِلنا معاها قدرتها.
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('ar')],
        home: CalendarScreen(),
      ));
      await tester.pumpAndSettle();

      // أول يوم فى الشهر — دايمًا موجود وماضى (أو النهاردة).
      await tester.tap(find.text(arNum(1)).first);
      await tester.pumpAndSettle();

      final day1 = DateTime(DateTime.now().year, DateTime.now().month);
      expect(find.text(arFullDate(day1)), findsOneWidget);

      // بندوّر جوّه الورقة بس: الشاشة اللى تحتها لسه فى الشجرة وفيها
      // سهم بدّل الشهر، فبحث عام هيلاقى سهمين ويقول إن الورقة تمام
      // وهى فاضية.
      Finder inSheet(IconData icon) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byIcon(icon));
      expect(inSheet(Icons.chevron_right), findsOneWidget);
      expect(inSheet(Icons.chevron_left), findsOneWidget);

      // سهم «قبله» بيرجّع يوم — ودى اللى آلة الزمن كانت بتعملها.
      await tester.tap(inSheet(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text(arFullDate(day1.subtract(const Duration(days: 1)))),
          findsOneWidget);
    });

    testWidgets('مافيش رجوع لبكرة', (tester) async {
      // اليوم اللى لسه ماجاش مالوش سجل، فالسهم لازم يبقى مقفول عند
      // النهاردة — غير كده بيفتح أوراق فاضية للأبد.
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('ar')],
        home: CalendarScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(arNum(DateTime.now().day)).first);
      await tester.pumpAndSettle();

      final forward = tester.widget<IconButton>(find.ancestor(
          of: find.descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byIcon(Icons.chevron_left)),
          matching: find.byType(IconButton)));
      expect(forward.onPressed, isNull);
    });
  });
}
