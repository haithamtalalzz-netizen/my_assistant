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
import 'package:my_assistant/core/privacy.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/data/appointments_repo.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/measurements_repo.dart';
import 'package:my_assistant/data/meds_repo.dart';
import 'package:my_assistant/screens/health/my_health_screen.dart';
import 'package:my_assistant/data/bills_repo.dart';
import 'package:my_assistant/data/income_repo.dart';
import 'package:my_assistant/data/money_repo.dart';
import 'package:my_assistant/data/savings_repo.dart';
import 'package:my_assistant/data/debts_repo.dart';
import 'package:my_assistant/data/wallets_repo.dart';
import 'package:my_assistant/data/wealth_history.dart';
import 'package:my_assistant/screens/money/money_screen.dart';
import 'package:my_assistant/screens/money/money_log_screen.dart';
import 'package:my_assistant/screens/money/fixed_monthly_screen.dart';
import 'package:my_assistant/screens/money/quick_expense_sheet.dart';
import 'package:my_assistant/screens/money/recurring_income_screen.dart';
import 'package:my_assistant/screens/money/fixed_bills_screen.dart';
import 'package:my_assistant/screens/money/wallets_screen.dart';
import 'package:my_assistant/screens/alerts_center_screen.dart';
import 'package:my_assistant/data/notes_repo.dart';
import 'package:my_assistant/data/wardrobe_repo.dart';

import 'package:my_assistant/data/goals_repo.dart';
import 'package:my_assistant/data/tasks_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/group_hub_screen.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:my_assistant/screens/settings_screen.dart';
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

    // الرئيسية **مقفولة** — الصاحب يشوف شكل التطبيق مش بياناتك.
    Privacy.hidden.value = true;
    final hh = await shot(
      tester,
      'real_home_hidden',
      shotApp(buildTheme(), const TodayScreen()),
      size: const Size(390, 1100),
      pixelRatio: 2,
    );
    Privacy.hidden.value = false;
    expect(hh.lengthSync(), greaterThan(10000));
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
        size: const Size(390, 1100), pixelRatio: 2);
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

  testWidgets('ملابسى — قطع من غير صور (المربّع الملوّن)', (tester) async {
    // من غير صور عشان نشوف البديل: قبل كده كان مساحة بيضا فاضية.
    final repo = WardrobeRepo();
    for (final (n, c) in [
      ('قميص أزرق', 'top'),
      ('بنطلون جينز', 'bottom'),
      ('جاكيت شتوى', 'outer'),
      ('حذاء رياضى', 'shoes'),
      ('حزام جلد', 'accessory'),
      ('تيشيرت قطن', 'top'),
    ]) {
      await repo.save(ClothingItem(name: n, category: c, color: 'أزرق'));
    }
    final f0 = await shot(tester, 'real_wardrobe_nophoto',
        shotApp(buildTheme(), const WardrobeScreen()),
        size: const Size(390, 700), pixelRatio: 2);
    expect(f0.lengthSync(), greaterThan(10000));
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

  testWidgets('فلوسى — الشكل الجديد (محافظ + إجمالى)', (tester) async {
    final now = DateTime.now();
    String day(int d) =>
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final money = MoneyRepo();
    await money.add(Expense(amount: 320, category: 'أكل', note: 'سوبر ماركت', day: dayKey(now)));
    await money.add(Expense(amount: 250, category: 'مواصلات', note: 'بنزين', day: dayKey(now)));
    await money.add(Expense(amount: 85, category: 'صحة', note: 'دوا', day: dayKey(now)));
    await money.add(Expense(amount: 1300, category: 'أكل', note: 'مطاعم', day: day(9)));

    final w = WalletsRepo();
    await w.save(const Wallet(name: 'كاش', type: 'cash', openingBalance: 13055));
    await w.save(const Wallet(name: 'بنوك', type: 'bank', openingBalance: 72100));
    await w.save(const Wallet(
        name: 'شهادة الأهلى',
        type: 'bank',
        openingBalance: 100000,
        bankKind: 'certificate',
        monthlyInterest: 1750,
        maturity: '2029-03-01'));
    await w.save(const Wallet(
        name: 'ذهب', type: 'gold', grams: 68, karat: 21));
    await w.save(const Wallet(
        name: 'فضة', type: 'silver', grams: 300, karat: 925));
    await w.save(const Wallet(name: 'أصول', type: 'asset', openingBalance: 750000));
    await w.save(const Wallet(name: 'مواشى', type: 'livestock', openingBalance: 10000));
    await MetalPrices.set('gold', 5000);
    await MetalPrices.set('silver', 55);
    // مرجع أول الشهر أقل من الإجمالى → «زادت».
    await WealthHistory.recordIfNew(1200000);

    // ادخار ودين عشان الزرارين يبانوا بأرقامهم.
    await SavingsRepo().addGoal(const SavingsGoal(
        name: 'سفر الصيف', target: 40000, createdAt: '2026-01-01'));
    await DebtsRepo().add(Debt(
        person: 'أحمد',
        amount: 5000,
        direction: 'لى',
        createdAt: '2026-09-01'));
    await DebtsRepo().add(Debt(
        person: 'محل الموبايل',
        amount: 1800,
        direction: 'عليا',
        createdAt: '2026-09-10'));

    await BillsRepo().save(const RecurringBill(
        name: 'كهربا', amount: 420, dayOfMonth: 5, category: 'فواتير'));
    await BillsRepo().save(const RecurringBill(
        name: 'نت', amount: 300, dayOfMonth: 10, category: 'فواتير'));
    await BillsRepo().save(const RecurringBill(
        name: 'مدرسة', amount: 1380, dayOfMonth: 12, category: 'فواتير'));
    await IncomeRepo().saveRecurring(const RecurringIncome(
        source: 'المرتب', amount: 11000, dayOfMonth: 1));

    final f = await shot(tester, 'real_money',
        shotApp(buildTheme(), const MoneyScreen()),
        size: const Size(390, 1000), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));

    // نفس الشاشة **مقفولة** — الصورة هى اللى بتقول الضبابة كفاية ولا لأ.
    Privacy.hidden.value = true;
    final h = await shot(tester, 'real_money_hidden',
        shotApp(buildTheme(), const MoneyScreen()),
        size: const Size(390, 1000), pixelRatio: 2);
    Privacy.hidden.value = false;
    expect(h.lengthSync(), greaterThan(10000));
  });

  testWidgets('هَب المجموعة (صحتى) — قايمة بدل مربعات', (tester) async {
    final f = await shot(
      tester,
      'real_group_hub',
      shotApp(
        buildTheme(),
        GroupHubScreen(
          title: 'صحتى',
          onSelectTab: (_) {},
          items: const [
            GroupHubItem(Icons.dashboard_outlined, 'لوحة الصحة'),
            GroupHubItem(Icons.medication_outlined, 'الأدوية'),
            GroupHubItem(Icons.favorite_outline, 'الدورة الشهرية'),
            GroupHubItem(Icons.repeat, 'العادات'),
            GroupHubItem(Icons.mood, 'تتبّع المزاج'),
            GroupHubItem(Icons.medical_information_outlined, 'الملف الطبي'),
            GroupHubItem(Icons.local_pharmacy_outlined, 'صيدلية البيت'),
            GroupHubItem(Icons.fitness_center, 'الجيم'),
            GroupHubItem(Icons.restaurant_outlined, 'دليل الأكل'),
          ],
        ),
      ),
      size: const Size(390, 780),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('صحتى — لازم النهاردة وأرقامك', (tester) async {
    final meds = MedsRepo();
    await meds.save(Medication(
        name: 'كونكور 5', dosage: '', times: const ['08:00', '21:00']));
    final m = (await meds.all()).first;
    await meds.setTaken(m.id!, dayKey(DateTime.now()), '08:00', true);
    await HealthRepo().setWaterMl(dayKey(DateTime.now()), 1500);
    await HealthRepo().setSleep(dayKey(DateTime.now()), 6);
    final mr = MeasurementsRepo();
    // قياسين من كل نوع عشان السهم (الاتجاه) يبان — واحد مايكفيش.
    await mr.add(Measurement(
        day: dayKey(DateTime.now().subtract(const Duration(days: 6))),
        type: 'وزن',
        value: 82.8,
        unit: 'كجم'));
    await mr.add(Measurement(
        day: dayKey(DateTime.now()), type: 'وزن', value: 84, unit: 'كجم'));
    await mr.add(Measurement(
        day: dayKey(DateTime.now()),
        type: 'ضغط',
        value: 12,
        value2: 8,
        unit: ''));
    await mr.upsertSteps(dayKey(DateTime.now()), 2400);

    final f = await shot(
        tester,
        'real_health',
        shotApp(
            buildTheme(),
            MyHealthScreen(sections: [
              HealthSection(Icons.favorite_outline, 'الصحة',
                  'دورة · عادات · مزاج · أدوية · ملف طبى', Colors.pink,
                  () => const SizedBox()),
              HealthSection(Icons.fitness_center, 'الرياضة',
                  'جيم · مشى · تقدّم · تمارين', Colors.deepPurple,
                  () => const SizedBox()),
              HealthSection(Icons.restaurant_outlined, 'النظام الغذائي',
                  'وجبات · صيام · وصفات', Colors.green, () => const SizedBox()),
            ])),
        size: const Size(390, 1000),
        pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('الإعدادات — أيقونات ملوّنة', (tester) async {
    final f = await shot(tester, 'real_settings',
        shotApp(buildTheme(), const SettingsScreen()),
        size: const Size(390, 900), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('دخلك الثابت — البنود المضافة', (tester) async {
    final r = IncomeRepo();
    await r.saveRecurring(const RecurringIncome(
        source: 'راتب', amount: 11000, dayOfMonth: 1, note: 'الشغل'));
    await r.saveRecurring(const RecurringIncome(
        source: 'إيجار', amount: 3500, dayOfMonth: 5, note: 'شقة المعادى'));
    await r.saveRecurring(const RecurringIncome(
        source: 'عمل حر', amount: 1800, dayOfMonth: 20));
    final f = await shot(tester, 'real_income',
        shotApp(buildTheme(), const RecurringIncomeScreen()),
        size: const Size(390, 640), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('فواتير ثابتة — البنود المضافة', (tester) async {
    final b = BillsRepo();
    await b.save(const RecurringBill(
        name: 'كهربا', amount: 420, dayOfMonth: 5, category: 'فواتير'));
    await b.save(const RecurringBill(
        name: 'نت', amount: 300, dayOfMonth: 10, category: 'فواتير'));
    await b.save(const RecurringBill(
        name: 'مدرسة', amount: 1380, dayOfMonth: 12, category: 'فواتير'));
    final f = await shot(tester, 'real_bills',
        shotApp(buildTheme(), const FixedBillsScreen()),
        size: const Size(390, 640), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('المحافظ — ذهب وفضة وشهادة', (tester) async {
    final w = WalletsRepo();
    await w.save(const Wallet(name: 'كاش', type: 'cash', openingBalance: 13055));
    await w.save(const Wallet(
        name: 'شهادة الأهلى',
        type: 'bank',
        openingBalance: 100000,
        bankKind: 'certificate',
        monthlyInterest: 1750,
        maturity: '2029-03-01'));
    await w.save(const Wallet(
        name: 'ذهب الفرح',
        type: 'gold',
        grams: 50,
        karat: 21,
        gramPrice: 5000));
    await w.save(const Wallet(
        name: 'فضة',
        type: 'silver',
        grams: 300,
        karat: 925,
        gramPrice: 55));
    await w.save(const Wallet(
        name: 'شقة المعادى', type: 'asset', openingBalance: 750000));
    final f = await shot(tester, 'real_wallets',
        shotApp(buildTheme(), const WalletsScreen()),
        size: const Size(390, 720), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('مركز التنبيهات — مجموعات بالوقت', (tester) async {
    // فاتورة فات ميعادها + دوا قرّب يخلص → بندين على الأقل.
    await BillsRepo().save(const RecurringBill(
        name: 'الكهربا', amount: 420, dayOfMonth: 1, category: 'فواتير'));
    final f = await shot(tester, 'real_alerts',
        shotApp(buildTheme(), const AlertsCenterScreen()),
        size: const Size(390, 640), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('كارت الطوارئ — قايمة بمجموعات', (tester) async {
    final st = SettingsRepo();
    await st.set('emergency_blood', 'O+');
    await st.set('emergency_allergies', 'بنسلين');
    await st.set('emergency_conditions', 'ضغط مرتفع — كونكور 5 مج يومى');
    await st.set('emergency_contact_name', 'منى — الزوجة');
    await st.set('emergency_contact_phone', '0100 123 4567');
    final f = await shot(tester, 'real_emergency2',
        shotApp(buildTheme(), const EmergencyView()),
        size: const Size(390, 760), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('سجل صرفت إيه — مقسوم بالأيام', (tester) async {
    final now = DateTime.now();
    String d(int back) {
      final x = now.subtract(Duration(days: back));
      return '${x.year.toString().padLeft(4, '0')}-'
          '${x.month.toString().padLeft(2, '0')}-'
          '${x.day.toString().padLeft(2, '0')}';
    }

    final m = MoneyRepo();
    await m.add(Expense(amount: 320, category: 'أكل', note: 'سوبر ماركت', day: d(0)));
    await m.add(Expense(amount: 250, category: 'مواصلات', note: 'بنزين', day: d(0)));
    await m.add(Expense(amount: 85, category: 'صحة', note: 'دوا', day: d(1)));
    await m.add(Expense(amount: 1300, category: 'أكل', note: 'مطاعم', day: d(3)));
    await m.add(Expense(amount: 60, category: 'مواصلات', note: '', day: d(5)));

    final f = await shot(tester, 'real_log_spent',
        shotApp(buildTheme(), const MoneyLogScreen(kind: MoneyLogKind.spent)),
        size: const Size(390, 780), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('اللى ثابت كل شهر — بيجيلك وبيروح عليك', (tester) async {
    await IncomeRepo().saveRecurring(const RecurringIncome(
        source: 'راتب', amount: 11000, dayOfMonth: 1, note: 'الشغل'));
    await IncomeRepo().saveRecurring(const RecurringIncome(
        source: 'إيجار', amount: 3500, dayOfMonth: 5, note: 'شقة المعادى'));
    await BillsRepo().save(const RecurringBill(
        name: 'كهربا', amount: 420, dayOfMonth: 5, category: 'فواتير'));
    await BillsRepo().save(const RecurringBill(
        name: 'نت', amount: 300, dayOfMonth: 10, category: 'فواتير'));
    await BillsRepo().save(const RecurringBill(
        name: 'مدرسة', amount: 1380, dayOfMonth: 12, category: 'فواتير'));
    await WalletsRepo().save(const Wallet(
        name: 'شهادة الأهلى',
        type: 'bank',
        openingBalance: 100000,
        bankKind: 'certificate',
        monthlyInterest: 1750));

    final f = await shot(tester, 'real_fixed_monthly',
        shotApp(buildTheme(), const FixedMonthlyScreen()),
        size: const Size(390, 860), pixelRatio: 2);
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('مصروف جديد — صفحة كاملة', (tester) async {
    await WalletsRepo().save(
        const Wallet(name: 'كاش', type: 'cash', openingBalance: 5000));
    await WalletsRepo()
        .save(const Wallet(name: 'بنك', type: 'bank', openingBalance: 20000));
    final f = await shot(
      tester,
      'real_add_expense',
      shotApp(
        buildTheme(),
        Scaffold(
          appBar: AppBar(title: const Text('مصروف جديد')),
          body: const SingleChildScrollView(
            child: QuickExpenseForm(showTitle: false),
          ),
        ),
      ),
      size: const Size(390, 700),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

}
