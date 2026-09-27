// لقطات للشاشات **الحقيقية** بعد التحويل — مش موك.
// بتشتغل على قاعدة فى الذاكرة ببيانات مزروعة، وبترندر الشاشة نفسها من
// `lib/screens/`، فاللى تشوفه هو اللى هيطلع على الموبايل.
//
//   flutter test tool/screen_shots_test.dart
//   → build/design_shots/real_<الشاشة>.png
//
// ⚠️ databaseFactoryFfiNoIsolate مش databaseFactoryFfi — التانى بيشتغل فى
// isolate والـfuture بتاعه عمره ما بيخلص جوّه الزمن الوهمى بتاع testWidgets،
// فالشاشة تفضل لودينج وpumpAndSettle يقعد ١٠ دقايق لحد ما يعمل timeout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/data/appointments_repo.dart';
import 'package:my_assistant/data/meds_repo.dart';
import 'package:my_assistant/data/notes_repo.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/tasks_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:my_assistant/screens/today_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadShotFonts();
  });

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  testWidgets('تذكيراتى — الشكل الجديد', (tester) async {
    final repo = NotesRepo();
    final pinnedId = await repo.add('عندى بكره شغل الساعه 7:00 الصبح');
    await repo.setPinned(pinnedId, true);
    await repo.add('قائمة السوبر ماركت: زيت · رز · جبنة');
    await repo.add('رقم الفنى: 01223456789');
    await repo.add('فكرة: أعمل جدول مذاكرة للأولاد');

    final f = await shot(
      tester,
      'real_notes',
      shotApp(buildTheme(), const NotesScreen()),
      size: const Size(390, 860),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('تذكيراتى — فاضية', (tester) async {
    final f = await shot(
      tester,
      'real_notes_empty',
      shotApp(buildTheme(), const NotesScreen()),
      size: const Size(390, 760),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('الرئيسية — الشكل الجديد (بطل + خط اليوم)', (tester) async {
    final now = DateTime.now();
    DateTime at(int h, int m) =>
        DateTime(now.year, now.month, now.day, h, m);

    await AppointmentsRepo().save(Appointment(
        title: 'د. أحمد — أسنان',
        category: 'دكتور',
        when: at(18, 0),
        location: 'عيادة المهندسين'));
    await MedsRepo().save(const Medication(
        name: 'كونكور', dosage: '5 مج', times: ['08:00', '21:00']));
    await TasksRepo().save(Task(
        title: 'دفع فاتورة الغاز',
        dueAt: at(17, 0).toIso8601String(),
        createdAt: now.toIso8601String()));
    await HealthRepo().setWaterMl(dayKey(now), 750);

    final f = await shot(
      tester,
      'real_home',
      shotApp(buildTheme(), const TodayScreen()),
      size: const Size(390, 1100),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

}
