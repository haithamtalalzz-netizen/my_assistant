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
import 'package:my_assistant/data/bills_repo.dart';
import 'package:my_assistant/data/income_repo.dart';
import 'package:my_assistant/data/money_repo.dart';
import 'package:my_assistant/screens/money/money_screen.dart';
import 'package:my_assistant/data/notes_repo.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/goals_repo.dart';
import 'package:my_assistant/data/tasks_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:my_assistant/screens/growth/goals_screen.dart';
import 'package:my_assistant/screens/schedule/schedule_screen.dart';
import 'package:my_assistant/screens/tasks/tasks_screen.dart';
import 'package:my_assistant/screens/today_screen.dart';
import 'package:my_assistant/screens/emergency_view.dart';
import 'package:my_assistant/screens/wardrobe/wardrobe_screen.dart';
import 'package:my_assistant/screens/worship/prayer_screen.dart';
import 'package:my_assistant/core/seed_demo_wardrobe.dart';
import 'package:my_assistant/data/settings_repo.dart';
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


  testWidgets('مواعيدى — الشكل الجديد', (tester) async {
    final now = DateTime.now();
    final repo = AppointmentsRepo();
    await repo.save(Appointment(
        title: 'د. أحمد — أسنان',
        category: 'دكتور',
        when: now.add(const Duration(hours: 3)),
        location: 'عيادة المهندسين'));
    await repo.save(Appointment(
        title: 'اجتماع الشغل',
        category: 'شغل',
        when: now.add(const Duration(days: 1, hours: 2))));
    await repo.save(Appointment(
        title: 'صيانة العربية',
        category: 'عربية',
        when: now.subtract(const Duration(days: 2))));

    final f = await shot(tester, 'real_schedule',
        shotApp(buildTheme(), const ScheduleScreen()),
        size: const Size(390, 1000), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('مهامى — الشكل الجديد', (tester) async {
    final now = DateTime.now();
    final repo = TasksRepo();
    final pid = await repo.saveProject(
        Project(name: 'تجهيز الشقة', color: 0xFF7C5CFF, createdAt: ''));
    final t1 = await repo.save(Task(
        title: 'دهان الأوضة',
        projectId: pid,
        priority: 2,
        dueAt: DateTime(now.year, now.month, now.day, 23, 0)
            .toIso8601String(),
        createdAt: ''));
    await repo.addSubtask(t1, 'شراء الدهانات');
    await repo.addSubtask(t1, 'تغطية العفش');
    await repo.save(Task(
        title: 'اتصل بشركة النت', createdAt: ''));
    await repo.save(Task(
        title: 'دفع فاتورة الغاز',
        dueAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        createdAt: ''));
    final done = await repo.save(Task(title: 'تجديد الباقة', createdAt: ''));
    await repo.setDone(done, true);

    final f = await shot(tester, 'real_tasks',
        shotApp(buildTheme(), const TasksScreen()),
        size: const Size(390, 1100), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('الأهداف — الشكل الجديد', (tester) async {
    final repo = GoalsRepo();
    final g1 = await repo.save(const Goal(title: 'أقرا 12 كتاب', createdAt: ''));
    for (var i = 0; i < 4; i++) {
      final m = await repo.addMilestone(g1, 'كتاب ${i + 1}');
      if (i < 3) await repo.toggleMilestone(m, true);
    }
    final g2 = await repo.save(const Goal(title: 'أوصل 80 كيلو', createdAt: ''));
    final m2 = await repo.addMilestone(g2, 'أول 5 كيلو');
    await repo.toggleMilestone(m2, true);
    await repo.addMilestone(g2, 'تانى 5 كيلو');
    await repo.save(const Goal(title: 'أحفظ جزء عمّ', createdAt: ''));

    final f = await shot(tester, 'real_goals',
        shotApp(buildTheme(), const GoalsScreen()),
        size: const Size(390, 900), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });


  testWidgets('صلاتى — الشكل الجديد', (tester) async {
    final f = await shot(tester, 'real_prayer',
        shotApp(buildTheme(), const PrayerScreen()),
        size: const Size(390, 1100), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('ملابسى — الشكل الجديد', (tester) async {
    await seedDemoWardrobe();
    final f = await shot(tester, 'real_wardrobe',
        shotApp(buildTheme(), const WardrobeScreen()),
        size: const Size(390, 1100), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('كارت الطوارئ — الشكل الجديد', (tester) async {
    final st = SettingsRepo();
    await st.set('emergency_blood', 'O+');
    await st.set('emergency_allergies', 'بنسلين');
    await st.set('emergency_conditions', 'ضغط');
    await st.set('emergency_contact_name', 'أحمد');
    await st.set('emergency_contact_phone', '01001234567');
    final f = await shot(tester, 'real_emergency',
        shotApp(buildTheme(), const EmergencyView()),
        size: const Size(390, 780), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('فلوسى — الشكل الجديد', (tester) async {
    final now = DateTime.now();
    String day(int d) =>
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final money = MoneyRepo();
    await money.add(Expense(amount: 1800, category: 'أكل', note: 'سوبر ماركت', day: day(3)));
    await money.add(Expense(amount: 1300, category: 'أكل', note: 'مطاعم', day: day(9)));
    await money.add(Expense(amount: 1450, category: 'مواصلات', note: 'بنزين', day: day(11)));
    await money.add(Expense(amount: 900, category: 'صحة', note: 'دوا', day: day(14)));
    await money.add(Expense(amount: 700, category: 'تسوق', note: 'صيانة', day: day(18)));

    await BillsRepo().save(const RecurringBill(
        name: 'كهربا', amount: 420, dayOfMonth: 5, category: 'فواتير'));
    await BillsRepo().save(const RecurringBill(
        name: 'نت', amount: 300, dayOfMonth: 10, category: 'فواتير'));
    await IncomeRepo().saveRecurring(const RecurringIncome(
        source: 'المرتب', amount: 11000, dayOfMonth: 1));

    final f = await shot(tester, 'real_money',
        shotApp(buildTheme(), const MoneyScreen()),
        size: const Size(390, 1200), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

}
