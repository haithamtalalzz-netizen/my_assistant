// اختبارات الدفعة الجديدة من الريديزاين: صحتى · مهامى · مواعيدى ·
// أهدافى · تطوّرى.
//
// الحاجات اللى بتتختبر هنا هى اللى **الصورة مابتكشفهاش**: حساب عمود
// اليوم فى التقويم، وأرقام البنود، والخطوة الجاية. الصورة بتقول الشكل
// طالع كويس؛ دى بتقول الرقم صح.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/challenges_repo.dart';
import 'package:my_assistant/data/goals_repo.dart';
import 'package:my_assistant/data/hub_stats.dart';
import 'package:my_assistant/data/quit_repo.dart';
import 'package:my_assistant/data/reading_repo.dart';
import 'package:my_assistant/data/relatives_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/widgets/month_grid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  late Database db;

  setUp(() async {
    // 🔴 جوّه testWidgets لازم databaseFactoryFfiNoIsolate: النسخة العادية
    // بتشتغل فى isolate والـfuture بتاعها عمره ما بيخلص جوّه الزمن الوهمى،
    // فالشاشة تفضل لودينج لحد الـtimeout.
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  group('تقويم الشهر — عمود اليوم', () {
    test('الأسبوع بيبدأ السبت', () {
      // 2026-10-03 يوم سبت.
      expect(MonthGrid.columnOf(DateTime(2026, 10, 3)), 0);
      expect(MonthGrid.columnOf(DateTime(2026, 10, 4)), 1); // أحد
      expect(MonthGrid.columnOf(DateTime(2026, 10, 5)), 2); // اتنين
      expect(MonthGrid.columnOf(DateTime(2026, 10, 6)), 3); // تلات
      expect(MonthGrid.columnOf(DateTime(2026, 10, 7)), 4); // أربع
      expect(MonthGrid.columnOf(DateTime(2026, 10, 8)), 5); // خميس
      expect(MonthGrid.columnOf(DateTime(2026, 10, 9)), 6); // جمعة
    });

    test('أول الشهر بياخد مكانه الصح مش أول خانة', () {
      // 1 أكتوبر 2026 خميس → خامس عمود. لو الحساب اتشال التقويم بيقول
      // إن الشهر بيبدأ سبت، وده كدب على طول الشهر.
      expect(MonthGrid.columnOf(DateTime(2026, 10, 1)), 5);
      // 1 سبتمبر 2026 تلات.
      expect(MonthGrid.columnOf(DateTime(2026, 9, 1)), 3);
      // 1 فبراير 2026 أحد.
      expect(MonthGrid.columnOf(DateTime(2026, 2, 1)), 1);
    });

    testWidgets('النقطة بتنزل تحت اليوم اللى فيه المواعيد', (tester) async {
      var picked = DateTime(2026, 10, 1);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: MonthGrid(
              month: DateTime(2026, 10, 1),
              selected: DateTime(2026, 10, 1),
              counts: const {'2026-10-14': 3},
              onSelect: (d) => picked = d,
              onMonthChange: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('14'), findsOneWidget);
      // دوسة على يوم بترجّع اليوم ده بالظبط.
      await tester.tap(find.text('14'));
      expect(picked, DateTime(2026, 10, 14));
    });
  });

  group('أرقام البنود', () {
    test('بند فاضى بيرجّع null بدل ما يقول صفر', () async {
      // الصفر بيتقرا كأنه حاجة اتحسبت. الفاضى مش نفس الحاجة.
      expect(await readingStat(), isNull);
      expect(await coursesStat(), isNull);
      expect(await quitStat(), isNull);
      expect(await relativesStat(), isNull);
      expect(await challengesStat(), isNull);
    });

    test('القراءة بتقول كام كتاب خلّصته والكتاب اللى بتقرا فيه', () async {
      final repo = ReadingRepo();
      await repo.save(Book(
          title: 'الرحيق المختوم',
          author: '',
          totalPages: 400,
          currentPage: 84,
          status: 'reading',
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(Book(
          title: 'كتاب خلص',
          author: '',
          totalPages: 100,
          currentPage: 100,
          status: 'done',
          createdAt: DateTime.now().toIso8601String()));

      final st = await readingStat();
      expect(st, isNotNull);
      expect(st!.big, '1'); // كتاب واحد خلص
      expect(st.sub, contains('الرحيق المختوم'));
      expect(st.sub, contains('84'));
    });

    test('صلة الرحم بترقّم **اللى فات** مش الإجمالى', () async {
      final repo = RelativesRepo();
      // واحد فات ميعاده بكتير، وواحد اتكلّمت معاه النهاردة.
      await repo.save(Relative(
          name: 'خالى',
          phone: '',
          intervalDays: 7,
          lastContacted: DateTime.now()
              .subtract(const Duration(days: 40))
              .toIso8601String()));
      await repo.save(Relative(
          name: 'عمى',
          phone: '',
          intervalDays: 30,
          lastContacted: DateTime.now().toIso8601String()));

      final st = await relativesStat();
      expect(st, isNotNull);
      // الرقم اللى بيخلّيك تفتح هو اللى فات — مش الاتنين.
      expect(st!.big, '1');
      expect(st.bigColor, isNotNull, reason: 'الفايت لازم يبان بلون مختلف');
    });

    test('عدّاد الإقلاع بيحسب الأيام والتوفير', () async {
      await QuitRepo().add(QuitCounter(
        name: 'السجاير',
        startDate: DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String()
            .substring(0, 10),
        dailySaving: 50,
      ));
      final st = await quitStat();
      expect(st!.big, '10');
      expect(st.sub, contains('500')); // 10 × 50
    });

    test('التحدى اللى خلص مابيتعدّش شغّال', () async {
      final repo = ChallengesRepo();
      await repo.add(Challenge(
          name: 'تحدى خلص',
          startDate: DateTime.now()
              .subtract(const Duration(days: 60))
              .toIso8601String()
              .substring(0, 10),
          days: 30));
      await repo.add(Challenge(
          name: 'تحدى شغّال',
          startDate: DateTime.now()
              .subtract(const Duration(days: 17))
              .toIso8601String()
              .substring(0, 10),
          days: 30));

      final st = await challengesStat();
      expect(st!.big, '1', reason: 'واحد بس لسه شغّال');
      expect(st.sub, contains('تحدى شغّال'));
      expect(st.sub, contains('18')); // اليوم الـ18
    });
  });

  group('أهدافى — الخطوة الجاية', () {
    test('أول معلم لسه ماخلصش هو الخطوة الجاية', () async {
      final repo = GoalsRepo();
      final id = await repo.save(Goal(
          title: 'أقرا 12 كتاب',
          createdAt: DateTime.now().toIso8601String()));
      final m1 = await repo.addMilestone(id, 'خلّص الكتاب الأول');
      await repo.addMilestone(id, 'ابدأ «الرحيق المختوم»');
      await repo.toggleMilestone(m1, true);

      final ms = await repo.milestones(id);
      final next = ms.where((m) => !m.done).map((m) => m.title).firstOrNull;
      expect(next, 'ابدأ «الرحيق المختوم»');

      final (done, total) = await repo.progress(id);
      expect(done, 1);
      expect(total, 2);
    });

    test('هدف من غير معالم مالوش خطوة جاية — والشاشة بتطلب منك تحدّدها',
        () async {
      final repo = GoalsRepo();
      final id = await repo.save(Goal(
          title: 'أحفظ جزء عمّ',
          createdAt: DateTime.now().toIso8601String()));
      final ms = await repo.milestones(id);
      expect(ms.where((m) => !m.done).map((m) => m.title).firstOrNull, isNull);
    });
  });
}
