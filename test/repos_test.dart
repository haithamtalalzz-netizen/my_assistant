import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/backup.dart';
import 'package:my_assistant/core/app_state.dart';
import 'package:my_assistant/core/contextual_tips.dart';
import 'package:my_assistant/core/day_close.dart';
import 'package:my_assistant/core/kcal_balance.dart';
import 'package:my_assistant/core/log.dart';
import 'package:my_assistant/core/morning_brief.dart';
import 'package:my_assistant/core/dashboard_stats.dart';
import 'package:my_assistant/core/data_export.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/usda_food_db.dart';
import 'package:my_assistant/core/egyptian_dishes.dart';
import 'package:my_assistant/core/attention.dart';
import 'package:my_assistant/widgets/day_glance.dart';
import 'package:my_assistant/widgets/reorderable_sections.dart';
import 'package:flutter/material.dart';
import 'package:my_assistant/core/food_db.dart';
import 'package:my_assistant/core/exercise_library.dart';
import 'package:my_assistant/core/countries.dart';
import 'package:my_assistant/core/diet_plans.dart';
import 'package:my_assistant/core/location_tracker.dart';
import 'package:my_assistant/data/activity_repo.dart';
import 'package:my_assistant/data/cycle_repo.dart';
import 'package:my_assistant/core/day_planner.dart';
import 'package:my_assistant/core/insights.dart';
import 'package:my_assistant/core/local_brain.dart';
import 'package:my_assistant/core/ocr.dart';
import 'package:my_assistant/core/prayers.dart';
import 'package:my_assistant/core/religion_data.dart';
import 'package:my_assistant/core/quran_data.dart';
import 'package:my_assistant/core/mawarith.dart';
import 'package:my_assistant/data/mushaf_repo.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/data/wallets_repo.dart';
import 'package:my_assistant/core/voice_parser.dart';
import 'package:my_assistant/data/appointments_repo.dart';
import 'package:my_assistant/data/day_log_repo.dart';
import 'package:my_assistant/data/docs_repo.dart';
import 'package:my_assistant/data/habits_repo.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/meds_repo.dart';
import 'package:my_assistant/data/meters_repo.dart';
import 'package:my_assistant/data/home_inventory_repo.dart';
import 'package:my_assistant/data/wardrobe_repo.dart';
import 'package:my_assistant/data/reading_repo.dart';
import 'package:my_assistant/data/gratitude_repo.dart';
import 'package:my_assistant/data/mood_repo.dart';
import 'package:my_assistant/data/wishlist_repo.dart';
import 'package:my_assistant/data/watchlist_repo.dart';
import 'package:my_assistant/data/vaccinations_repo.dart';
import 'package:my_assistant/data/lab_results_repo.dart';
import 'package:my_assistant/data/money_repo.dart';
import 'package:my_assistant/data/tasks_repo.dart';
import 'package:my_assistant/data/subscriptions_repo.dart';
import 'package:my_assistant/data/goals_repo.dart';
import 'package:my_assistant/data/cars_repo.dart';
import 'package:my_assistant/data/renewals_repo.dart';
import 'package:my_assistant/data/trips_repo.dart';
import 'package:my_assistant/data/courses_repo.dart';
import 'package:my_assistant/data/pets_repo.dart';
import 'package:my_assistant/data/passwords_repo.dart';
import 'package:my_assistant/data/symptoms_repo.dart';
import 'package:my_assistant/data/fasting_repo.dart';
import 'package:my_assistant/data/meal_plan_repo.dart';
import 'package:my_assistant/core/week_overview.dart';
import 'package:my_assistant/core/year_review.dart';
import 'package:my_assistant/core/streak_guard.dart';
import 'package:my_assistant/core/weather.dart';
import 'package:my_assistant/core/month_summary.dart';
import 'package:my_assistant/data/bills_repo.dart';
import 'package:my_assistant/data/debts_repo.dart';
import 'package:my_assistant/data/gameya_repo.dart';
import 'package:my_assistant/data/home_maintenance_repo.dart';
import 'package:my_assistant/data/inbox_repo.dart';
import 'package:my_assistant/data/income_repo.dart';
import 'package:my_assistant/data/meals_repo.dart';
import 'package:my_assistant/data/measurements_repo.dart';
import 'package:my_assistant/data/occasions_repo.dart';
import 'package:my_assistant/data/plants_repo.dart';
import 'package:my_assistant/data/worship_repo.dart';
import 'package:my_assistant/data/search_repo.dart';
import 'package:my_assistant/data/settings_repo.dart';
import 'package:my_assistant/data/weekly_repo.dart';
import 'package:my_assistant/data/workout_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/schedule/appointment_form.dart';
import 'package:my_assistant/screens/tour_screen.dart';
import 'package:my_assistant/screens/quick_actions_settings_screen.dart';
import 'package:my_assistant/core/l10n.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  group('أدوات العربي', () {
    test('أرقام العرض إنجليزية (لاتينية)', () {
      expect(arNum(123), '123');
      expect(arNum('4/8'), '4/8');
    });

    test('قراءة الأرقام العربية من الإدخال', () {
      expect(parseNumber('١٥٠'), 150);
      expect(parseNumber('٢٥،٥'), 25.5);
      expect(parseNumber('12.75'), 12.75);
      expect(parseNumber('كلام'), isNull);
    });

    test('مفتاح اليوم', () {
      expect(dayKey(DateTime(2026, 6, 12)), '2026-06-12');
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('عقل المدير المحلي (مجاني)', () {
    test('الترحيب بيرجّع مساعدة متعامل معاها', () async {
      final r = await LocalBrain.answer('ازيك');
      expect(r.handled, isTrue);
      expect(r.text.contains('مديرك'), isTrue);
    });

    test('السؤال الفاضي بيرجّع مساعدة', () async {
      final r = await LocalBrain.answer('');
      expect(r.handled, isTrue);
    });

    test('كلام مش مفهوم مابيتعاملش معاه (يروح للـ fallback)', () async {
      final r = await LocalBrain.answer('qwerty zxcv');
      expect(r.handled, isFalse);
    });

    test('سؤال الفلوس بيرد بالرصيد من المحافظ', () async {
      await WalletsRepo().save(const Wallet(name: 'كاش', openingBalance: 500));
      final r = await LocalBrain.answer('معايا كام فلوس؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('500'), isTrue);
    });

    test('سؤال الديون من غير ديون بيقول مفيش', () async {
      final r = await LocalBrain.answer('عليا ديون؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('مفيش'), isTrue);
    });

    test('صافي الثروة بيجمع المحافظ والأصول', () async {
      await WalletsRepo().save(const Wallet(name: 'كاش', openingBalance: 1000));
      final r = await LocalBrain.answer('صافي ثروتي؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('ثروت'), isTrue);
      expect(r.text.contains('1000'), isTrue);
    });

    test('مقارنة المصاريف بالشهر اللي فات', () async {
      final now = DateTime.now();
      final prev = DateTime(now.year, now.month - 1, 15);
      await MoneyRepo().add(Expense(
          amount: 200, category: 'أكل', day: dayKey(prev), note: ''));
      final r = await LocalBrain.answer('صرفت كام الشهر ده؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('الشهر اللي فات'), isTrue);
    });

    test('الملخص الشامل بيرجّع نظرة على اليوم', () async {
      final r = await LocalBrain.answer('طمني على يومي');
      expect(r.handled, isTrue);
      expect(r.text.contains('ملخص يومك'), isTrue);
    });

    test('قايمة المشتريات بترجع الحاجات غير المعلّمة', () async {
      await MealsRepo().addShoppingItem('عيش');
      final r = await LocalBrain.answer('لازم اشتري ايه؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('عيش'), isTrue);
    });

    test('قدرة الشراء: مبلغ أقل من الرصيد → تقدر', () async {
      await WalletsRepo().save(const Wallet(name: 'كاش', openingBalance: 1000));
      final r = await LocalBrain.answer('ينفع أصرف ٣٠٠؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('تقدر') || r.text.contains('هيتبقالك'), isTrue);
    });

    test('أكتر بند صرف بيرجّع الفئة الأعلى', () async {
      final now = DateTime.now();
      await MoneyRepo().add(Expense(
          amount: 500, category: 'أكل', day: dayKey(now), note: ''));
      final r = await LocalBrain.answer('أكتر بند صرفت عليه؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('أكل'), isTrue);
    });

    test('سؤال عن شخص بالاسم بيرجّع ديونه (مع السابقة «لأحمد»)', () async {
      await DebtsRepo().add(Debt(
          person: 'أحمد',
          amount: 300,
          direction: 'عليا',
          createdAt: dayKey(DateTime.now())));
      final r = await LocalBrain.answer('أنا مديون لأحمد بكام؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('أحمد'), isTrue);
      expect(r.text.contains('300'), isTrue);
    });

    test('«عليا ديون» ما تتلغبطش باسم شخص «علي»', () async {
      await DebtsRepo().add(Debt(
          person: 'علي',
          amount: 50,
          direction: 'عليا',
          createdAt: dayKey(DateTime.now())));
      final r = await LocalBrain.answer('عليا ديون؟');
      // لازم يرد بإجمالي الديون مش صفحة الشخص «علي»
      expect(r.handled, isTrue);
      expect(r.text.contains('الصافي'), isTrue);
    });

    test('«ذكّرني بـ…» بيضيف تذكير في صندوق الوارد', () async {
      final r = await LocalBrain.answer('ذكرني بشراء اللبن');
      expect(r.handled, isTrue);
      expect(r.text.contains('الوارد'), isTrue);
      expect(await InboxRepo().count(), 1);
    });

    test('اتجاه القياس بيقارن آخر قياسين', () async {
      final repo = MeasurementsRepo();
      await repo.add(const Measurement(day: '2026-07-01', type: 'وزن', value: 90));
      await repo.add(const Measurement(day: '2026-07-10', type: 'وزن', value: 88));
      final r = await LocalBrain.answer('وزني نزل؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('نزل'), isTrue);
    });

    test('التاريخ والوقت', () async {
      final r = await LocalBrain.answer('الساعة كام؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('الساعة'), isTrue);
    });

    test('صندوق الوارد الفاضي', () async {
      final r = await LocalBrain.answer('الوارد');
      expect(r.handled, isTrue);
      expect(r.text.contains('الوارد'), isTrue);
    });

    test('ورد القرآن من غير تسجيل', () async {
      final r = await LocalBrain.answer('وردي؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('ورد'), isTrue);
    });

    test('الترحيب الاستباقي بيرجّع رسالة', () async {
      final tip = await LocalBrain.proactiveTip();
      expect(tip.isNotEmpty, isTrue);
    });

    test('الاقتراحات السريعة فيها عناصر', () {
      expect(LocalBrain.suggestions().length, greaterThanOrEqualTo(3));
    });

    test('زرار «+ كوب مياه» بيزوّد المياه فعلاً', () async {
      final actions = await LocalBrain.quickActions('حالتي النهاردة');
      expect(actions.any((a) => a.kind == 'water+1'), isTrue);
      final day = dayKey(DateTime.now());
      final before = await HealthRepo().waterOn(day);
      final msg = await LocalBrain.runAction('water+1');
      expect(msg.contains('مياه'), isTrue);
      expect(await HealthRepo().waterOn(day), before + 1);
    });

    test('متابعة السياق: «وأمبارح» بعد سؤال المصاريف', () async {
      final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      await MoneyRepo().add(
          Expense(amount: 120, category: 'أكل', day: yesterday, note: ''));
      final r = await LocalBrain.answer('وأمبارح؟', previous: 'صرفت كام الشهر ده؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('امبارح'), isTrue);
      expect(r.text.contains('120'), isTrue);
    });

    test('زرار «علّم عادة» بيعلّمها فعلاً', () async {
      final id = await HabitsRepo().add('مشي');
      final actions = await LocalBrain.quickActions('عاداتي');
      expect(actions.any((a) => a.kind.startsWith('habit_done:')), isTrue);
      await LocalBrain.runAction('habit_done:$id');
      final done = await HabitsRepo().doneOn(dayKey(DateTime.now()));
      expect(done.contains(id), isTrue);
    });

    test('ملخص الأسبوع بيرجّع نظرة', () async {
      await MoneyRepo().add(Expense(
          amount: 50, category: 'أكل', day: dayKey(DateTime.now()), note: ''));
      final r = await LocalBrain.answer('ملخص الأسبوع');
      expect(r.handled, isTrue);
      expect(r.text.contains('أيام') || r.text.contains('صرفت'), isTrue);
    });

    test('متابعة السياق للمواعيد: «وبكرة» بعد سؤال المواعيد', () async {
      final tm = DateTime.now().add(const Duration(days: 1));
      await AppointmentsRepo().save(Appointment(
          title: 'كشف',
          category: 'دكتور',
          when: DateTime(tm.year, tm.month, tm.day, 17)));
      final r = await LocalBrain.answer('وبكرة؟', previous: 'مواعيدي إيه؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('كشف'), isTrue);
    });

    test('رد ودّي على الشكر', () async {
      final r = await LocalBrain.answer('شكرا');
      expect(r.handled, isTrue);
      expect(r.text.contains('العفو'), isTrue);
    });

    test('زرار «سجّل المصروف» بيسجّل مصروف فعلاً', () async {
      final actions = await LocalBrain.quickActions('ينفع أصرف ٢٠٠؟');
      expect(actions.any((a) => a.kind.startsWith('log_expense:')), isTrue);
      final day = dayKey(DateTime.now());
      final before = await MoneyRepo().totalForDay(day);
      await LocalBrain.runAction('log_expense:200');
      expect(await MoneyRepo().totalForDay(day), before + 200);
    });

    test('ملخص الشهر بيرجّع الصرف', () async {
      await MoneyRepo().add(Expense(
          amount: 300, category: 'أكل', day: dayKey(DateTime.now()), note: ''));
      final r = await LocalBrain.answer('ملخص الشهر');
      expect(r.handled, isTrue);
      expect(r.text.contains('صرفت'), isTrue);
    });

    test('بحث المستندات بالاسم (رخصتي ↔ رخصة)', () async {
      await DocsRepo().save(const DocItem(title: 'رخصة القيادة'));
      final r = await LocalBrain.answer('رخصتي فين؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('رخصة'), isTrue);
    });

    test('ميعاد المرتب الجاي', () async {
      await IncomeRepo().saveRecurring(
          const RecurringIncome(source: 'مرتب', amount: 5000, dayOfMonth: 28));
      final r = await LocalBrain.answer('امتى مرتبي؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('مرتب'), isTrue);
    });

    test('المركز المالي بيجمع الرصيد', () async {
      await WalletsRepo().save(const Wallet(name: 'كاش', openingBalance: 700));
      final r = await LocalBrain.answer('وضعي المالي');
      expect(r.handled, isTrue);
      expect(r.text.contains('700'), isTrue);
    });

    test('المركز الصحي بيعرض المياه', () async {
      await HealthRepo().addWater(dayKey(DateTime.now()), 2);
      final r = await LocalBrain.answer('وضعي الصحي');
      expect(r.handled, isTrue);
      expect(r.text.contains('مياه'), isTrue);
    });

    test('زرار مسح الوارد بيفضّيه', () async {
      await InboxRepo().add('حاجة');
      final actions = await LocalBrain.quickActions('الوارد');
      expect(actions.any((a) => a.kind == 'clear_inbox'), isTrue);
      await LocalBrain.runAction('clear_inbox');
      expect(await InboxRepo().count(), 0);
    });
  });

  group('المياه والنوم', () {
    test('عداد المياه يزيد وينقص ومايقلش عن صفر', () async {
      final repo = HealthRepo();
      expect(await repo.waterOn('2026-06-12'), 0);
      expect(await repo.addWater('2026-06-12', 1), 1);
      expect(await repo.addWater('2026-06-12', 1), 2);
      expect(await repo.addWater('2026-06-12', -1), 1);
      expect(await repo.addWater('2026-06-12', -5), 0);
    });

    test('النوم يتسجل ويتعدل', () async {
      final repo = HealthRepo();
      expect(await repo.sleepOn('2026-06-12'), isNull);
      await repo.setSleep('2026-06-12', 7);
      expect(await repo.sleepOn('2026-06-12'), 7);
      await repo.setSleep('2026-06-12', 5.5);
      expect(await repo.sleepOn('2026-06-12'), 5.5);
    });

    test('تقويم الصحة: أيام النشاط وملخّص اليوم', () async {
      final repo = HealthRepo();
      await repo.addWater('2026-09-05', 3);
      await repo.setSleep('2026-09-05', 6);
      await MeasurementsRepo()
          .add(const Measurement(day: '2026-09-05', type: 'وزن', value: 80));

      final days = await repo.activeDaysInMonth(2026, 9);
      expect(days.contains('2026-09-05'), isTrue);
      expect(days.contains('2026-09-06'), isFalse);

      final rep = await repo.dayReport('2026-09-05');
      expect(rep.water, 3);
      expect(rep.sleep, 6);
      expect(rep.measurements.length, 1);
      expect(rep.measurements.first.type, 'وزن');
      expect(rep.hasAny, isTrue);
      expect((await repo.dayReport('2026-09-06')).hasAny, isFalse);
    });
  });

  group('المواعيد', () {
    test('حفظ وقراءة مواعيد يوم معين', () async {
      final repo = AppointmentsRepo();
      await repo.save(Appointment(
          title: 'دكتور',
          category: 'صحة',
          when: DateTime(2026, 6, 12, 10, 30)));
      await repo.save(Appointment(
          title: 'اجتماع',
          category: 'شغل',
          when: DateTime(2026, 6, 13, 9, 0)));
      final today = await repo.forDay(DateTime(2026, 6, 12));
      expect(today.length, 1);
      expect(today.first.title, 'دكتور');
    });

    test('تم → يختفي من مواعيد اليوم', () async {
      final repo = AppointmentsRepo();
      final id = await repo.save(Appointment(
          title: 'دكتور',
          category: 'صحة',
          when: DateTime(2026, 6, 12, 10, 30)));
      await repo.setDone(id, true);
      expect(await repo.forDay(DateTime(2026, 6, 12)), isEmpty);
    });
  });

  group('الأدوية', () {
    test('تسجيل الجرعات المتاخدة والرجوع فيها', () async {
      final repo = MedsRepo();
      final id = await repo.save(const Medication(
          name: 'ضغط', dosage: 'قرص', times: ['08:00', '20:00']));
      await repo.setTaken(id, '2026-06-12', '08:00', true);
      expect(await repo.takenOn('2026-06-12'), {'$id|08:00'});
      await repo.setTaken(id, '2026-06-12', '08:00', false);
      expect(await repo.takenOn('2026-06-12'), isEmpty);
    });

    test('حذف الدواء يمسح سجلاته', () async {
      final repo = MedsRepo();
      final id = await repo.save(
          const Medication(name: 'ضغط', times: ['08:00']));
      await repo.setTaken(id, '2026-06-12', '08:00', true);
      await repo.delete(id);
      expect(await repo.all(), isEmpty);
      expect(await repo.takenOn('2026-06-12'), isEmpty);
    });
  });

  group('الفلوس', () {
    test('إجمالي الشهر وتقسيم الفئات', () async {
      final repo = MoneyRepo();
      await repo.add(const Expense(
          amount: 100, category: 'أكل', day: '2026-06-01'));
      await repo.add(const Expense(
          amount: 50, category: 'أكل', day: '2026-06-15'));
      await repo.add(const Expense(
          amount: 200, category: 'فواتير', day: '2026-06-10'));
      await repo.add(const Expense(
          amount: 999, category: 'أكل', day: '2026-05-30'));
      expect(await repo.totalForMonth(2026, 6), 350);
      final byCat = await repo.byCategory(2026, 6);
      expect(byCat['فواتير'], 200);
      expect(byCat['أكل'], 150);
      expect(byCat.keys.first, 'فواتير');
      expect(await repo.totalForDay('2026-06-15'), 50);
    });

    test('ميزانيات الفئات: حفظ وقراءة وحذف', () async {
      final s = SettingsRepo();
      await s.setCategoryBudget('أكل', 500);
      await s.setCategoryBudget('مواصلات', 300);
      var b = await s.categoryBudgets();
      expect(b['أكل'], 500);
      expect(b['مواصلات'], 300);
      await s.setCategoryBudget('أكل', 0); // حذف
      b = await s.categoryBudgets();
      expect(b.containsKey('أكل'), isFalse);
      expect(b['مواصلات'], 300);
    });

    test('تقويم الفلوس: أيام النشاط وملخّص اليوم', () async {
      final repo = MoneyRepo();
      await repo.add(const Expense(
          amount: 100, category: 'أكل', day: '2026-08-03'));
      await repo.add(const Expense(
          amount: 40, category: 'مواصلات', day: '2026-08-03'));
      await IncomeRepo().add(const Income(
          amount: 5000, source: 'مرتب', day: '2026-08-03', note: ''));
      await IncomeRepo().add(const Income(
          amount: 200, source: 'بيع', day: '2026-08-20', note: ''));

      final days = await repo.activeDaysInMonth(2026, 8);
      expect(days.contains('2026-08-03'), isTrue); // مصروف + دخل
      expect(days.contains('2026-08-20'), isTrue); // دخل بس
      expect(days.contains('2026-08-04'), isFalse);

      final rep = await repo.dayReport('2026-08-03');
      expect(rep.spent, 140);
      expect(rep.income, 5000);
      expect(rep.expenseCount, 2);
      expect(rep.byCategory['أكل'], 100);
      expect(rep.hasAny, isTrue);
      expect((await repo.dayReport('2026-08-04')).hasAny, isFalse);
    });
  });

  group('المستندات', () {
    test('اللي قرب يخلص بس هو اللي يظهر', () async {
      final repo = DocsRepo();
      final now = DateTime.now();
      await repo.save(DocItem(
          title: 'رخصة', expiry: dayKey(now.add(const Duration(days: 10)))));
      await repo.save(DocItem(
          title: 'جواز', expiry: dayKey(now.add(const Duration(days: 300)))));
      await repo.save(const DocItem(title: 'شهادة'));
      final soon = await repo.expiringSoon();
      expect(soon.length, 1);
      expect(soon.first.title, 'رخصة');
    });
  });

  group('العادات وسلسلة الإنجاز', () {
    Set<String> daysAgo(DateTime today, List<int> offsets) =>
        offsets.map((o) => dayKey(today.subtract(Duration(days: o)))).toSet();

    final today = DateTime(2026, 6, 12);

    test('سلسلة متواصلة', () {
      expect(computeStreak(daysAgo(today, [0, 1, 2, 3]), today), 4);
    });

    test('النهارده لسه ماتعملش — مايكسرش السلسلة', () {
      expect(computeStreak(daysAgo(today, [1, 2, 3]), today), 3);
    });

    test('يوم رحمة واحد مايكسرش السلسلة ومايتحسبش', () {
      // امبارح فايت، وقبله ٣ أيام متواصلة.
      expect(computeStreak(daysAgo(today, [0, 2, 3, 4]), today), 4);
    });

    test('يومين فايتين ورا بعض يكسروا السلسلة', () {
      expect(computeStreak(daysAgo(today, [0, 3, 4]), today), 1);
    });

    test('عادة جديدة من غير أي إنجاز = صفر', () {
      expect(computeStreak(<String>{}, today), 0);
    });

    test('التبديل بيسجل وبيمسح', () async {
      final repo = HabitsRepo();
      final id = await repo.add('قراءة');
      expect(await repo.toggle(id, '2026-06-12'), isTrue);
      expect(await repo.doneOn('2026-06-12'), {id});
      expect(await repo.toggle(id, '2026-06-12'), isFalse);
      expect(await repo.doneOn('2026-06-12'), isEmpty);
    });
  });

  group('الإعدادات', () {
    test('قيم افتراضية وقيم متخزنة', () async {
      final repo = SettingsRepo();
      // هدف المياه بقى بالملى (الافتراضى ٢٠٠٠ = ٨ أكواب توافقياً).
      expect(await repo.waterGoal(), 8);
      expect(await repo.waterGoalMl(), 2000);
      expect(await repo.monthlyBudget(), 0);
      await repo.setWaterGoalMl(2500);
      await repo.set('monthly_budget', '5000');
      expect(await repo.waterGoalMl(), 2500);
      expect(await repo.waterGoal(), 10); // ٢٥٠٠ ÷ ٢٥٠
      expect(await repo.monthlyBudget(), 5000);
    });

    test('إشعارات الأذان شغالة افتراضيًا وبتتقفل بـ 0', () async {
      final repo = SettingsRepo();
      expect(await repo.prayerNotificationsEnabled(), isTrue);
      await repo.set('prayer_notifications', '0');
      expect(await repo.prayerNotificationsEnabled(), isFalse);
      expect(await repo.appLockEnabled(), isFalse);
      expect(await repo.governorateName(), 'القاهرة');
    });
  });

  group('مواعيد الصلاة', () {
    test('ترتيب الصلوات منطقي', () {
      final day = DateTime(2026, 6, 12);
      final prayers = prayerTimesFor(day, governorateByName('القاهرة'));
      expect(prayers.fajr.isBefore(prayers.dhuhr), isTrue);
      expect(prayers.dhuhr.isBefore(prayers.asr), isTrue);
      expect(prayers.asr.isBefore(prayers.maghrib), isTrue);
      expect(prayers.maghrib.isBefore(prayers.isha), isTrue);
      expect(prayers.times.length, kPrayerNames.length);
    });

    test('الصلاة الجاية بتتحدد صح', () {
      final day = DateTime(2026, 6, 12);
      final prayers = prayerTimesFor(day, governorateByName('القاهرة'));
      expect(prayers.nextIndex(prayers.fajr.subtract(const Duration(hours: 1))), 0);
      expect(prayers.nextIndex(prayers.isha.add(const Duration(hours: 1))), isNull);
    });

    test('طريقة الحساب بتغيّر المواقيت (مصرية ≠ أم القرى)', () {
      final day = DateTime(2026, 6, 12);
      PrayerPrefs.method = 'egyptian';
      final egyptian = prayerTimesFor(day, governorateByName('القاهرة'));
      PrayerPrefs.method = 'ummAlQura';
      final umm = prayerTimesFor(day, governorateByName('القاهرة'));
      // أم القرى بتحسب العشا بفارق ثابت بعد المغرب → مختلفة عن المصرية.
      expect(egyptian.isha.isAtSameMomentAs(umm.isha), isFalse);
      // المذهب الحنفي بيأخّر العصر عن الجمهور.
      PrayerPrefs.method = 'egyptian';
      PrayerPrefs.madhab = 'hanafi';
      final hanafi = prayerTimesFor(day, governorateByName('القاهرة'));
      expect(hanafi.asr.isAfter(egyptian.asr), isTrue);
      PrayerPrefs.madhab = 'shafi'; // رجوع للافتراضي
    });

    test('محافظة غير معروفة ترجع القاهرة', () {
      expect(governorateByName('مش موجودة').name, 'القاهرة');
    });
  });

  group('العبادات — قبلة وتتبّع صلاة ومسبحة', () {
    test('اتجاه القبلة من القاهرة جنوب شرق', () {
      final b = qiblaBearing(30.0444, 31.2357);
      expect(b, greaterThan(110));
      expect(b, lessThan(160));
    });

    test('تتبّع الصلوات: تسجيل وإلغاء وعدّ', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      for (var i = 0; i < 5; i++) {
        await repo.togglePrayer(today, i, true);
      }
      expect((await repo.prayedToday()).length, 5);
      expect(await repo.fullDaysStreak(), 1);
      // إلغاء صلاة واحدة يكسر السلسلة الكاملة.
      await repo.togglePrayer(today, 2, false);
      expect((await repo.prayedToday()).length, 4);
      expect(await repo.fullDaysStreak(), 0);
    });

    test('المسبحة بتجمّع الإجمالى', () async {
      final repo = WorshipRepo();
      expect(await repo.tasbihTotal(), 0);
      await repo.addTasbih(33);
      await repo.addTasbih(1);
      expect(await repo.tasbihTotal(), 34);
      await repo.resetTasbih();
      expect(await repo.tasbihTotal(), 0);
    });

    test('تتبّع السنن: تسجيل وإلغاء', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      await repo.toggleSunnah(today, 'صلاة الوتر', true);
      await repo.toggleSunnah(today, 'صلاة الضحى', true);
      expect((await repo.sunnahDoneOn(today)).length, 2);
      await repo.toggleSunnah(today, 'صلاة الوتر', false);
      expect((await repo.sunnahDoneOn(today)).contains('صلاة الوتر'), isFalse);
      expect((await repo.sunnahDoneOn(today)).length, 1);
    });

    test('ختمة القرآن: بداية وتقدّم ومتوسّط ومتبقّى', () async {
      final repo = WorshipRepo();
      expect(await repo.activeKhatma(), isNull);
      await repo.startKhatma(dailyTarget: 4);
      await repo.logKhatmaRead(4);
      await repo.logKhatmaRead(6);
      final k = await repo.activeKhatma();
      expect(k, isNotNull);
      expect(k!.currentPage, 10);
      expect(k.remainingPages, 594);
      expect(await repo.khatmaAvgPerDay(), 10); // كله فى نفس اليوم = 10 صفحة
      expect(k.daysToFinish(10), 60); // 594/10 = 59.4 → 60
      await repo.resetKhatma();
      expect(await repo.activeKhatma(), isNull);
    });

    test('آية/حديث/دعاء اليوم ثابتة خلال اليوم', () {
      final now = DateTime(2026, 7, 12);
      expect(ayahOfDay(now), ayahOfDay(now));
      expect(hadithOfDay(now), hadithOfDay(now));
      expect(duaOfDay(now), isNotEmpty);
      expect(kNames99.length, 99);
    });

    test('المصحف: 114 سورة و6236 آية والفاتحة صحيحة', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final surahs = await QuranData.surahs();
      expect(surahs.length, 114);
      expect(surahs.map((s) => s.id).toList(), List.generate(114, (i) => i + 1));
      expect(surahs.fold<int>(0, (a, s) => a + s.verses.length), 6236);
      expect(surahs.first.verses.length, 7); // الفاتحة
      expect(surahs.last.verses.length, 6); // الناس
      expect(surahs.first.verses.first.text.startsWith('بِسۡمِ'), isTrue);
    });

    test('صفحات المصحف: 114 بداية سورة، متزايدة، 1..604', () {
      expect(kSurahStartPage.length, 114);
      expect(kSurahStartPage.first, 1);
      expect(kSurahStartPage.last, 604);
      for (var i = 0; i < 113; i++) {
        expect(kSurahStartPage[i] <= kSurahStartPage[i + 1], isTrue);
      }
      expect(surahStartPage(2), 2);
      expect(mushafPageUrl(1).endsWith('page001.png'), isTrue);
    });

    test('خريطة صفحات المصحف وبيانات السور', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(kSurahStartJuz.length, 114);
      expect(kSurahRevOrder.length, 114);
      expect(kSurahRevOrder.first, 5); // الفاتحة نزلت الخامسة
      final p1 = await QuranData.pageAyahs(1);
      expect(p1.length, 7); // الفاتحة كلها فى الصفحة الأولى
      expect(await QuranData.surahsStartingOn(2), contains(2)); // البقرة تبدأ صفحة 2
      // كل الآيات موزّعة على الصفحات = 6236
      var total = 0;
      for (var p = 1; p <= 604; p++) {
        total += (await QuranData.pageAyahs(p)).length;
      }
      expect(total, 6236);
    });

    test('الأجزاء + علامات المصحف + الصفحات المقروءة', () async {
      expect(kJuzStartPage.length, 30);
      expect(kJuzStartPage.first, 1);
      expect(pageJuz(1), 1);
      expect(pageJuz(22), 2);
      expect(pageJuz(604), 30);
      final repo = MushafRepo();
      await repo.addBookmark(50, 'آل عمران');
      final bms = await repo.bookmarks();
      expect(bms.length, 1);
      expect(bms.first.page, 50);
      await repo.markRead(1);
      await repo.markRead(1); // مكرّرة تُتجاهل
      await repo.markRead(2);
      expect(await repo.readCount(), 2);
    });

    test('سجل العبادات: ملخّص اليوم وأيام النشاط', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      await repo.togglePrayer(today, 0, true);
      await repo.togglePrayer(today, 1, true);
      await repo.markDhikrDone(today, 'morning');
      await repo.setFasted(today, true);
      final r = await repo.dayReport(today);
      expect(r.prayers.length, 2);
      expect(r.dhikr.contains('morning'), isTrue);
      expect(r.fasted, isTrue);
      expect(r.hasAny, isTrue);
      final days = await repo.worshipDaysInMonth(today.year, today.month);
      expect(days.contains(dayKey(today)), isTrue);
    });

    test('الوِرد اليومى: عدّ لكل ذِكر', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      await repo.setWird(today, 0, 33);
      await repo.setWird(today, 1, 100);
      final c = await repo.wirdCounts(today);
      expect(c[0], 33);
      expect(c[1], 100);
      expect(c[2], isNull);
    });

    test('سلسلة الأذكار وعدّ الصيام', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      await repo.markDhikrDone(today, 'morning');
      await repo.markDhikrDone(today, 'evening');
      expect((await repo.dhikrDoneOn(today)).length, 2);
      expect(await repo.dhikrStreak(), 1);
      await repo.setFasted(today, true);
      expect(await repo.fastedOn(today), isTrue);
      expect(await repo.fastCountLast(30), 1);
      await repo.setFasted(today, false);
      expect(await repo.fastedOn(today), isFalse);
    });
  });

  group('حاسبة المواريث', () {
    test('زوج + ابن: الزوج 1/4 والابن 3/4', () {
      final r = computeMawarith(
          const MawarithInput(estate: 1200, spouse: 'husband', sons: 1));
      final h = r.shares.firstWhere((s) => s.name == 'الزوج');
      final son = r.shares.firstWhere((s) => s.name == 'الأبناء');
      expect(h.fraction, closeTo(0.25, 1e-6));
      expect(son.fraction, closeTo(0.75, 1e-6));
      expect(h.amount, closeTo(300, 1e-6));
    });

    test('المسألة العُمرية: زوجة + أب + أم', () {
      final r = computeMawarith(
          const MawarithInput(estate: 2400, spouse: 'wife', father: true, mother: true));
      final w = r.shares.firstWhere((s) => s.name == 'الزوجة');
      final m = r.shares.firstWhere((s) => s.name == 'الأم');
      final f = r.shares.firstWhere((s) => s.name == 'الأب');
      expect(w.fraction, closeTo(0.25, 1e-6));
      expect(m.fraction, closeTo(0.25, 1e-6)); // ثلث الباقى
      expect(f.fraction, closeTo(0.5, 1e-6));
    });
  });

  group('مفتاح الأسبوع', () {
    test('الجمعة نفسها والأيام اللي بعدها', () {
      // 2026-06-12 يوم جمعة.
      expect(currentWeekKey(DateTime(2026, 6, 12)), '2026-06-12');
      expect(currentWeekKey(DateTime(2026, 6, 13)), '2026-06-12');
      expect(currentWeekKey(DateTime(2026, 6, 18)), '2026-06-12');
      expect(currentWeekKey(DateTime(2026, 6, 19)), '2026-06-19');
    });
  });

  group('كاشف التسويف', () {
    test('التأجيل لوقت أبعد بس هو اللي يزود العداد', () async {
      final repo = AppointmentsRepo();
      final id = await repo.save(Appointment(
          title: 'مهمة', category: 'شخصي', when: DateTime(2026, 6, 12, 10)));
      await repo.save(Appointment(
          id: id, title: 'مهمة', category: 'شخصي',
          when: DateTime(2026, 6, 13, 10)));
      await repo.save(Appointment(
          id: id, title: 'مهمة', category: 'شخصي',
          when: DateTime(2026, 6, 15, 10)));
      var saved = (await repo.all()).single;
      expect(saved.postponeCount, 2);
      // تقديم الميعاد مايتحسبش تأجيل.
      await repo.save(Appointment(
          id: id, title: 'مهمة', category: 'شخصي',
          when: DateTime(2026, 6, 14, 10)));
      saved = (await repo.all()).single;
      expect(saved.postponeCount, 2);
      expect(await repo.chronicallyPostponed(minTimes: 2), isNotEmpty);
      expect(await repo.chronicallyPostponed(), isEmpty);
    });
  });

  group('المراجعة الأسبوعية', () {
    test('حفظ وقراءة وتعديل', () async {
      final repo = WeeklyRepo();
      expect(await repo.forWeek('2026-06-12'), isNull);
      await repo.save(const WeeklyReview(
          weekKey: '2026-06-12',
          wentWell: 'التمرين',
          createdAt: '2026-06-12T10:00:00'));
      expect((await repo.forWeek('2026-06-12'))!.wentWell, 'التمرين');
      await repo.save(const WeeklyReview(
          weekKey: '2026-06-12',
          wentWell: 'النوم بدري',
          createdAt: '2026-06-12T11:00:00'));
      expect((await repo.forWeek('2026-06-12'))!.wentWell, 'النوم بدري');
    });

    test('إحصائيات آخر ٧ أيام بتحسب النطاق صح', () async {
      final now = DateTime(2026, 6, 12, 12);
      final money = MoneyRepo();
      await money.add(const Expense(
          amount: 100, category: 'أكل', day: '2026-06-10'));
      await money.add(const Expense(
          amount: 50, category: 'أكل', day: '2026-06-01'));
      await HealthRepo().setSleep('2026-06-11', 7);
      final stats = await WeeklyRepo().statsForLastWeek(now);
      expect(stats.totalSpent, 100);
      expect(stats.avgSleep, 7);
    });
  });

  group('ترقية قاعدة البيانات v1 ← v2', () {
    test('postpone_count بيضاف و weekly_reviews بتتعمل', () async {
      // singleInstance: false عشان ناخد قاعدة ذاكرة جديدة مش نسخة setUp.
      final v1 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v1.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'شخصي',
          when_at TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          remind_before_min INTEGER NOT NULL DEFAULT 60,
          done INTEGER NOT NULL DEFAULT 0
        )''');
      await v1.insert('appointments', {
        'title': 'قديم',
        'category': 'شخصي',
        'when_at': '2026-06-12T10:00:00.000',
      });
      await AppDb.upgradeSchema(v1, 1, 2);
      final rows = await v1.query('appointments');
      expect(rows.first['postpone_count'], 0);
      await v1.insert('weekly_reviews',
          {'week_key': '2026-06-12', 'created_at': 'x'});
      expect((await v1.query('weekly_reviews')).length, 1);
      await v1.close();
    });
  });

  group('النسخ الاحتياطي', () {
    test('إعادة كتابة مسار الصورة لمجلد الجهاز الحالي', () {
      final rewritten = rewrittenImagePath(
          '/data/user/0/old/doc_images/doc_123.jpg', r'C:\new\doc_images');
      expect(rewritten, p.join(r'C:\new\doc_images', 'doc_123.jpg'));
    });
  });

  group('المحلل الصوتي', () {
    final now = DateTime(2026, 7, 6, 10);

    test('مصروف بنزين بأرقام عربية', () {
      final actions = parseUtterance('صرفت ١٥٠ جنيه بنزين', now: now);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.expense);
      expect(actions.single.amount, 150);
      expect(actions.single.category, 'مواصلات');
    });

    test('دخل: قبضت مرتب', () {
      final actions = parseUtterance('قبضت ٥٠٠٠ مرتب', now: now);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.income);
      expect(actions.single.amount, 5000);
      expect(actions.single.category, 'مرتب');
    });

    test('جملة مركبة: مصروف أكل + مياه بواو العطف', () {
      final actions =
          parseUtterance('صرفت 80 اكل وشربت 3 كوبايات مياه', now: now);
      expect(actions.length, 2);
      final expense =
          actions.firstWhere((a) => a.type == VoiceActionType.expense);
      expect(expense.amount, 80);
      expect(expense.category, 'أكل');
      final water =
          actions.firstWhere((a) => a.type == VoiceActionType.water);
      expect(water.amount, 3);
    });

    test('شربت مية = كوباية واحدة مش ١٠٠', () {
      final actions = parseUtterance('شربت مية', now: now);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.water);
      expect(actions.single.amount, 1);
    });

    test('نوم بالساعات والنص', () {
      final actions = parseUtterance('نمت 7 ساعات ونص', now: now);
      expect(actions.single.type, VoiceActionType.sleep);
      expect(actions.single.amount, 7.5);
    });

    test('موعد دكتور بكرة الساعة ٥ → بعد الضهر تلقائيًا', () {
      final actions = parseUtterance('موعد دكتور بكرة الساعة 5', now: now);
      expect(actions.length, 1);
      final a = actions.single;
      expect(a.type, VoiceActionType.appointment);
      expect(a.title, 'دكتور');
      expect(a.category, 'صحة');
      expect(a.when, DateTime(2026, 7, 7, 17, 0));
    });

    test('موعد الساعة ٩ الصبح يفضل صبح', () {
      final actions =
          parseUtterance('موعد شغل بكرة الساعة 9 الصبح', now: now);
      expect(actions.single.when, DateTime(2026, 7, 7, 9, 0));
    });

    test('عادة بالاسم الفعلي', () {
      final actions = parseUtterance('خلصت ورد قرآن النهارده',
          now: now, habitNames: ['ورد قرآن', 'مشي نص ساعة']);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.habitDone);
      expect(actions.single.matchName, 'ورد قرآن');
    });

    test('دوا بالاسم الفعلي', () {
      final actions = parseUtterance('خدت دوا الضغط',
          now: now, medNames: ['دوا الضغط']);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.medTaken);
      expect(actions.single.matchName, 'دوا الضغط');
    });

    test('كلام من غير أوامر يرجع فاضي', () {
      expect(parseUtterance('الجو حلو النهارده', now: now), isEmpty);
      expect(parseUtterance('', now: now), isEmpty);
    });

    test('وجبة: اتغديت كشري', () {
      final actions = parseUtterance('اتغديت كشري', now: now);
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.meal);
      expect(actions.single.matchName, 'غدا');
      expect(actions.single.note, 'كشري');
    });

    test('أكلت من غير تحديد → استنتاج من الساعة', () {
      final morning = parseUtterance('أكلت فول وطعمية',
          now: DateTime(2026, 7, 6, 8));
      expect(morning.single.matchName, 'فطار');
      final evening = parseUtterance('أكلت سندوتش',
          now: DateTime(2026, 7, 6, 20));
      expect(evening.single.matchName, 'عشا');
    });

    test('اتمرنت → تمرين اتعمل', () {
      final actions = parseUtterance('اتمرنت النهارده', now: now);
      expect(actions.single.type, VoiceActionType.workoutDone);
    });
  });

  group('الوجبات والتسوق', () {
    test('تسجيل وجبات اليوم وحذفها', () async {
      final repo = MealsRepo();
      final id = await repo.add(const Meal(
          day: '2026-07-06', slot: 'غدا', description: 'كشري', calories: 600));
      await repo.add(const Meal(
          day: '2026-07-05', slot: 'عشا', description: 'فول'));
      final today = await repo.forDay('2026-07-06');
      expect(today.length, 1);
      expect(today.single.calories, 600);
      await repo.delete(id);
      expect(await repo.forDay('2026-07-06'), isEmpty);
    });

    test('قائمة التسوق: إضافة وتشيك ومسح المتشال', () async {
      final repo = MealsRepo();
      final id1 = await repo.addShoppingItem('رز');
      await repo.addShoppingItem('زيت');
      await repo.setChecked(id1, true);
      expect((await repo.shoppingItems()).length, 2);
      await repo.clearChecked();
      final left = await repo.shoppingItems();
      expect(left.length, 1);
      expect(left.single.name, 'زيت');
    });
  });

  group('التمرين', () {
    test('حفظ الخطة وتسجيل الإنجاز', () async {
      final repo = WorkoutRepo();
      await repo.savePlan({1: 'صدر', 3: 'ظهر', 5: ''});
      final plan = await repo.plan();
      expect(plan.length, 2);
      expect(plan[1], 'صدر');
      await repo.setDone('2026-07-06', true, title: 'صدر');
      expect(await repo.doneOn('2026-07-06'), isTrue);
      await repo.setDone('2026-07-06', false);
      expect(await repo.doneOn('2026-07-06'), isFalse);
    });

    test('اقتراح تعويض تمرين امبارح الفايت', () async {
      final repo = WorkoutRepo();
      // 2026-07-06 إثنين → امبارح أحد (weekday 7).
      final now = DateTime(2026, 7, 6, 10);
      await repo.savePlan({7: 'جري'});
      expect(await repo.missedYesterdaySuggestion(now), 'جري');
      // لو اتعمل امبارح مفيش اقتراح.
      await repo.setDone('2026-07-05', true, title: 'جري');
      expect(await repo.missedYesterdaySuggestion(now), isNull);
    });

    test('مفيش اقتراح لو النهارده فيه تمرين أصلًا', () async {
      final repo = WorkoutRepo();
      final now = DateTime(2026, 7, 6, 10);
      await repo.savePlan({7: 'جري', 1: 'صدر'});
      expect(await repo.missedYesterdaySuggestion(now), isNull);
    });
  });

  group('المناسبات', () {
    test('أقرب حدوث: السنة دي أو الجاية', () {
      const o = Occasion(title: 'عيد ميلاد', month: 3, day: 15);
      expect(o.nextOccurrence(DateTime(2026, 7, 6)), DateTime(2027, 3, 15));
      expect(o.nextOccurrence(DateTime(2026, 2, 1)), DateTime(2026, 3, 15));
      expect(o.nextOccurrence(DateTime(2026, 3, 15)), DateTime(2026, 3, 15));
    });

    test('اللي جوه نافذة التذكير بس', () async {
      final repo = OccasionsRepo();
      final now = DateTime(2026, 7, 6);
      await repo.save(const Occasion(
          title: 'قريب', month: 7, day: 8, remindDays: 3));
      await repo.save(const Occasion(
          title: 'بعيد', month: 12, day: 25, remindDays: 3));
      final soon = await repo.upcomingWithinWindow(now);
      expect(soon.length, 1);
      expect(soon.single.title, 'قريب');
    });
  });

  group('محرك الرؤى', () {
    test('بيرسون: علاقة طردية وعكسية كاملة', () {
      expect(pearson([1, 2, 3, 4], [2, 4, 6, 8]), closeTo(1, 0.001));
      expect(pearson([1, 2, 3, 4], [8, 6, 4, 2]), closeTo(-1, 0.001));
      expect(pearson([1, 1, 1], [2, 3, 4]), isNull); // مفيش تباين
      expect(pearson([1], [2]), isNull); // بيانات مش كفاية
    });

    test('ارتباط نوم قليل = صرف أكتر بيطلع في الرؤى', () {
      final days = <DailyMetrics>[];
      final base = DateTime(2026, 5, 1);
      for (var i = 0; i < 30; i++) {
        final sleep = 5 + (i % 4).toDouble(); // 5..8
        days.add(DailyMetrics(
          day: '2026-05-${(i + 1).toString().padLeft(2, '0')}',
          sleep: sleep,
          spend: (9 - sleep) * 100, // نوم أقل = صرف أعلى
        ));
      }
      // نستخدم base عشان التحذير — مش مؤثر.
      expect(base.month, 5);
      final insights = buildInsights(InsightData(days: days));
      expect(
          insights.any((i) =>
              i.kind == InsightKind.correlation &&
              i.text.contains('نومك فيها قليل')),
          isTrue);
    });

    test('مفيش بيانات → رسالة اجمع بيانات', () {
      final insights = buildInsights(const InsightData(days: []));
      expect(insights.length, 1);
      expect(insights.single.kind, InsightKind.info);
    });

    test('احتفال بأطول سلسلة', () {
      final insights = buildInsights(InsightData(
        days: const [],
        habitStreaks: const {'قراءة': 12, 'مشي': 3},
      ));
      expect(
          insights.any((i) =>
              i.kind == InsightKind.celebration && i.text.contains('قراءة')),
          isTrue);
    });
  });

  group('مخطط اليوم', () {
    test('البنود المقترحة بتتحط في الفراغات من غير تعارض', () {
      final now = DateTime(2026, 7, 6, 14, 0);
      final plan = buildDayPlan(PlanInput(
        now: now,
        dayEnd: DateTime(2026, 7, 6, 22, 30),
        appointments: [(DateTime(2026, 7, 6, 16, 0), 'اجتماع')],
        prayers: [(DateTime(2026, 7, 6, 15, 30), 'العصر')],
        overdue: const ['مشوار البنك'],
        pendingHabits: const ['قراءة'],
      ));
      // كل البنود جوه النطاق ومرتبة ومن غير تداخل مع الاجتماع.
      for (var i = 1; i < plan.length; i++) {
        expect(
            plan[i].start.isAfter(plan[i - 1].start) ||
                plan[i].start.isAtSameMomentAs(plan[i - 1].start),
            isTrue);
      }
      expect(plan.any((p) => p.title.contains('مشوار البنك')), isTrue);
      expect(plan.any((p) => p.title.contains('قراءة')), isTrue);
      final overdueItem =
          plan.firstWhere((p) => p.kind == PlanKind.overdue);
      final meeting =
          plan.firstWhere((p) => p.kind == PlanKind.appointment);
      final overlaps = overdueItem.start.isBefore(meeting.end) &&
          meeting.start.isBefore(overdueItem.end);
      expect(overlaps, isFalse);
    });

    test('يوم فاضي بالكامل يرجع البنود المقترحة بس', () {
      final plan = buildDayPlan(PlanInput(
        now: DateTime(2026, 7, 6, 20, 0),
        dayEnd: DateTime(2026, 7, 6, 22, 30),
        pendingHabits: const ['ورد قرآن'],
      ));
      expect(plan.length, 1);
      expect(plan.single.kind, PlanKind.habit);
    });
  });

  group('استخراج OCR', () {
    test('إجمالي الفاتورة من سطر total', () {
      const text = 'Market ABC\nItem 1  25.50\nItem 2  30\nTOTAL  55.50\nCash 100';
      expect(extractReceiptTotal(text), 55.50);
    });

    test('إجمالي بأرقام عربية وكلمة اجمالي', () {
      const text = 'سوبر ماركت\nصنف ٤٥\nالاجمالي ١٢٠.٥٠';
      expect(extractReceiptTotal(text), 120.50);
    });

    test('من غير كلمة مفتاحية → أكبر رقم', () {
      const text = 'شحن 12\n56.75\n8';
      expect(extractReceiptTotal(text), 56.75);
    });

    test('استخراج تاريخ انتهاء مستقبلي', () {
      const text = 'License\nIssue 01/03/2024\nExpiry 15/09/2028';
      final best = bestExpiryDate(text, DateTime(2026, 7, 6));
      expect(best, DateTime(2028, 9, 15));
    });

    test('تواريخ عربية الأرقام بتتقري', () {
      const text = 'ينتهي في ٢٠/١١/٢٠٢٧';
      expect(extractDates(text), contains(DateTime(2027, 11, 20)));
    });
  });

  group('القياسات', () {
    test('صوت: ضغطي ١٢٠ على ٨٠', () {
      final actions = parseUtterance('ضغطي 120 على 80',
          now: DateTime(2026, 7, 6));
      expect(actions.length, 1);
      final a = actions.single;
      expect(a.type, VoiceActionType.measurement);
      expect(a.matchName, 'ضغط');
      expect(a.amount, 120);
      expect(a.amount2, 80);
    });

    test('صوت: وزني وسكري', () {
      final w = parseUtterance('وزني 95', now: DateTime(2026, 7, 6));
      expect(w.single.matchName, 'وزن');
      expect(w.single.amount, 95);
      final s = parseUtterance('سكري 110', now: DateTime(2026, 7, 6));
      expect(s.single.matchName, 'سكر');
    });

    test('تسجيل وقراءة القياسات والخطوات', () async {
      final repo = MeasurementsRepo();
      await repo.add(const Measurement(
          day: '2026-07-06', type: 'ضغط', value: 120, value2: 80));
      await repo.add(const Measurement(
          day: '2026-07-05', type: 'وزن', value: 95, unit: 'كجم'));
      final recent = await repo.recent();
      expect(recent.length, 2);
      expect(recent.first.display(), '120/80');
      await repo.upsertSteps('2026-07-06', 5000);
      await repo.upsertSteps('2026-07-06', 7000);
      expect(await repo.stepsSince('2026-07-01'), {'2026-07-06': 7000});
    });
  });

  group('الفواتير الدورية', () {
    test('الاستحقاق: اليوم جه والشهر لسه مااتدفعش', () {
      const bill = RecurringBill(
          name: 'كهربا', amount: 350, dayOfMonth: 5);
      expect(bill.isDue(DateTime(2026, 7, 6)), isTrue);
      expect(bill.isDue(DateTime(2026, 7, 3)), isFalse);
      const paid = RecurringBill(
          name: 'كهربا',
          amount: 350,
          dayOfMonth: 5,
          lastPaidMonth: '2026-07');
      expect(paid.isDue(DateTime(2026, 7, 6)), isFalse);
      expect(paid.isDue(DateTime(2026, 8, 10)), isTrue);
    });

    test('اتدفعت = مصروف متسجل + ختم الشهر + مش بتتكرر', () async {
      final bills = BillsRepo();
      final id = await bills.save(const RecurringBill(
          name: 'نت', amount: 400, dayOfMonth: 1));
      final now = DateTime(2026, 7, 6);
      await bills.markPaid(id, now: now);
      final expenses = await MoneyRepo().forMonth(2026, 7);
      expect(expenses.length, 1);
      expect(expenses.single.amount, 400);
      expect(expenses.single.note, 'نت');
      // دفعة تانية في نفس الشهر متتسجلش.
      await bills.markPaid(id, now: now);
      expect((await MoneyRepo().forMonth(2026, 7)).length, 1);
      expect((await bills.due(now)), isEmpty);
    });
  });

  group('حماية السلاسل', () {
    test('العادات المعرضة للكسر: سلسلة ≥٧ ومش متعملة النهارده', () {
      final habits = [
        const Habit(id: 1, name: 'قراءة', createdAt: '2026-01-01'),
        const Habit(id: 2, name: 'مشي', createdAt: '2026-01-01'),
        const Habit(id: 3, name: 'ورد', createdAt: '2026-01-01'),
      ];
      final risky = StreakGuard.atRisk(
        habits: habits,
        streaks: {1: 12, 2: 3, 3: 8},
        doneToday: {3},
      );
      expect(risky, ['قراءة']);
    });
  });

  group('صندوق الوارد', () {
    test('إضافة وحذف وعد', () async {
      final repo = InboxRepo();
      expect(await repo.count(), 0);
      final id = await repo.add('  أجيب شاحن جديد  ');
      await repo.add('أكلم أحمد');
      expect(await repo.count(), 2);
      final all = await repo.all();
      expect(all.last.text, 'أجيب شاحن جديد'); // trimmed
      await repo.delete(id);
      expect(await repo.count(), 1);
    });

    test('صوت: افتكرلي', () {
      final actions = parseUtterance('افتكرلي أجيب شاحن للعربية',
          now: DateTime(2026, 7, 6));
      expect(actions.length, 1);
      expect(actions.single.type, VoiceActionType.inboxNote);
      expect(actions.single.note, 'أجيب شاحن للعربية');
    });
  });

  group('كورسات الدوا', () {
    test('daysLeft بيحسب صح والمستمر null', () {
      final now = DateTime(2026, 7, 6);
      const continuous = Medication(name: 'ضغط', times: ['08:00']);
      expect(continuous.daysLeft(now), isNull);
      const course = Medication(
          name: 'مضاد', times: ['08:00'], endDate: '2026-07-08');
      expect(course.daysLeft(now), 3);
      const ended = Medication(
          name: 'قديم', times: ['08:00'], endDate: '2026-07-05');
      expect(ended.daysLeft(now)! <= 0, isTrue);
    });

    test('الكورس المنتهي بيتوقف تلقائيًا', () async {
      final repo = MedsRepo();
      final yesterday =
          dayKey(DateTime.now().subtract(const Duration(days: 1)));
      await repo.save(Medication(
          name: 'مضاد حيوي', times: const ['08:00'], endDate: yesterday));
      await repo.save(const Medication(name: 'مستمر', times: ['09:00']));
      await repo.deactivateExpiredCourses();
      final active = await repo.all(activeOnly: true);
      expect(active.length, 1);
      expect(active.single.name, 'مستمر');
    });
  });

  group('اقتراح الميزانية', () {
    test('متوسط الشهور اللي فيها بيانات', () async {
      final money = MoneyRepo();
      final now = DateTime.now();
      final m1 = DateTime(now.year, now.month - 1);
      final m2 = DateTime(now.year, now.month - 2);
      await money.add(Expense(
          amount: 3000,
          category: 'أكل',
          day: dayKey(DateTime(m1.year, m1.month, 10))));
      await money.add(Expense(
          amount: 5000,
          category: 'فواتير',
          day: dayKey(DateTime(m2.year, m2.month, 10))));
      final suggested = await MonthSummary.suggestedBudget();
      expect(suggested, 4000);
    });

    test('مفيش بيانات كفاية → null', () async {
      expect(await MonthSummary.suggestedBudget(), isNull);
    });
  });

  group('الديون والسلف', () {
    test('صافي: ليك ناقص عليك', () async {
      final repo = DebtsRepo();
      await repo.add(Debt(
          person: 'أحمد',
          amount: 200,
          direction: 'لى',
          createdAt: 'x'));
      await repo.add(Debt(
          person: 'محمد',
          amount: 500,
          direction: 'عليا',
          createdAt: 'x'));
      await repo.add(Debt(
          person: 'علي', amount: 100, direction: 'لى', createdAt: 'x'));
      final (owed, iOwe) = await repo.totals();
      expect(owed, 300);
      expect(iOwe, 500);
    });

    test('التسديد بيشيلها من الصافي', () async {
      final repo = DebtsRepo();
      final id = await repo.add(Debt(
          person: 'أحمد', amount: 200, direction: 'لى', createdAt: 'x'));
      await repo.setSettled(id, true);
      final (owed, _) = await repo.totals();
      expect(owed, 0);
      expect((await repo.all()).isEmpty, isTrue);
    });

    test('صوت: سلفت أحمد ٢٠٠', () {
      final actions = parseUtterance('سلفت أحمد 200',
          now: DateTime(2026, 7, 7));
      expect(actions.length, 1);
      final a = actions.single;
      expect(a.type, VoiceActionType.debt);
      expect(a.category, 'لى');
      expect(a.matchName, 'أحمد');
      expect(a.amount, 200);
    });

    test('صوت: خدت من محمد ٥٠٠', () {
      final actions = parseUtterance('خدت من محمد 500',
          now: DateTime(2026, 7, 7));
      expect(actions.length, 1);
      expect(actions.single.category, 'عليا');
      expect(actions.single.matchName, 'محمد');
      expect(actions.single.amount, 500);
    });
  });

  group('الجمعية', () {
    test('رقم الشهر ودورك', () {
      const g = Gameya(
          name: 'الشغل',
          amount: 1000,
          totalMonths: 10,
          myTurn: 4,
          startMonth: '2026-05');
      expect(g.monthIndex(DateTime(2026, 7, 15)), 3); // مايو=1، يوليو=3
      expect(g.monthsUntilMyTurn(DateTime(2026, 7, 15)), 1);
      expect(g.isActive(DateTime(2026, 7, 15)), isTrue);
      expect(g.isActive(DateTime(2027, 5, 1)), isFalse); // بعد ١٠ شهور
      expect(g.payout, 10000);
    });

    test('تسجيل قسط الشهر', () async {
      final repo = GameyaRepo();
      final id = await repo.save(const Gameya(
          name: 'العيلة',
          amount: 500,
          totalMonths: 6,
          myTurn: 2,
          startMonth: '2026-07'));
      await repo.setPaid(id, '2026-07', true);
      expect(await repo.paidMonths(id), {'2026-07'});
      await repo.setPaid(id, '2026-07', false);
      expect(await repo.paidMonths(id), isEmpty);
    });
  });

  group('صيانة البيت', () {
    test('الاستحقاق بيتحسب من آخر مرة + المدة', () {
      const m = HomeMaintenance(
          name: 'فلتر المياه', intervalMonths: 6, lastDone: '2026-01-10');
      expect(m.nextDue(), DateTime(2026, 7, 10));
      expect(m.isDue(DateTime(2026, 7, 11)), isTrue);
      expect(m.isDue(DateTime(2026, 6, 1)), isFalse);
    });

    test('اتعملت بتصفّر العداد', () async {
      final repo = HomeMaintenanceRepo();
      final id = await repo.save(const HomeMaintenance(
          name: 'التكييف', intervalMonths: 6, lastDone: '2025-01-01'));
      expect((await repo.due(DateTime.now())).length, 1);
      await repo.markDone(id);
      expect((await repo.due(DateTime.now())), isEmpty);
    });
  });

  group('البيانات التجريبية', () {
    test('بتتضاف لكل البنود من غير أخطاء', () async {
      final count = await seedDemoData();
      expect(count, greaterThan(30));
      expect((await WalletsRepo().all()).length, 3);
      expect((await PlantsRepo().all()).length, 2);
    });
  });

  group('نباتات البيت', () {
    test('الاستحقاق بيتحسب من آخر ري + المدة', () {
      const p =
          Plant(name: 'صبار', waterIntervalDays: 7, lastWatered: '2026-01-10');
      expect(p.nextWater(), DateTime(2026, 1, 17));
      expect(p.isDue(DateTime(2026, 1, 18)), isTrue);
      expect(p.isDue(DateTime(2026, 1, 12)), isFalse);
    });

    test('سقيت بتصفّر عداد الري', () async {
      final repo = PlantsRepo();
      await repo.save(const Plant(
          name: 'الفل', waterIntervalDays: 3, lastWatered: '2025-01-01'));
      expect((await repo.due(DateTime.now())).length, 1);
      await repo.markWatered((await repo.all()).first);
      expect(await repo.due(DateTime.now()), isEmpty);
    });
  });

  group('الطقس', () {
    test('النصيحة بتتغير حسب الحرارة', () {
      expect(const WeatherToday(42, 28, 0).summaryLine(), contains('حر شديد'));
      expect(const WeatherToday(10, 5, 0).summaryLine(), contains('برد'));
      expect(const WeatherToday(20, 15, 61).condition, 'مطر');
    });
  });

  group('البحث العام', () {
    test('بيلاقي المصروف بالملاحظة', () async {
      await MoneyRepo().add(Expense(
          amount: 50, category: 'أكل', note: 'كشري', day: '2026-07-07'));
      final hits = await SearchRepo().search('كشري');
      expect(hits.any((h) => h.kind == 'expense' && h.title == 'كشري'), true);
    });

    test('أقل من حرفين مبيرجعش نتائج', () async {
      final hits = await SearchRepo().search('ك');
      expect(hits, isEmpty);
    });
  });

  group('تقويم النتيجة', () {
    test('بيجمّع نشاط اليوم من الجداول المختلفة', () async {
      await MoneyRepo()
          .add(Expense(amount: 100, category: 'أكل', day: '2026-07-07'));
      final database = await AppDb.instance;
      await database.insert('appointments', {
        'title': 'دكتور',
        'category': 'صحة',
        'when_at': '2026-07-07T17:00:00',
      });
      final repo = DayLogRepo();
      final days = await repo.daysWithActivity(2026, 7);
      expect(days.contains('2026-07-07'), true);
      final events = await repo.forDay('2026-07-07');
      expect(events.length >= 2, true);
    });
  });

  group('المواعيد المتكررة', () {
    test('nextOccurrence بيلف لقدّام ويعدّي دلوقتي', () {
      final past = DateTime.now().subtract(const Duration(days: 10));
      final daily = Appointment(
          title: 'x', category: 'شخصي', when: past, repeat: 'daily');
      expect(daily.nextOccurrence().isAfter(DateTime.now()), isTrue);

      final weekly = Appointment(
          title: 'x', category: 'شخصي', when: past, repeat: 'weekly');
      final n = weekly.nextOccurrence();
      expect(n.isAfter(DateTime.now()), isTrue);
      // نفس ساعة/دقيقة الموعد الأصلي.
      expect(n.hour, past.hour);
      expect(n.minute, past.minute);
    });

    test('monthly بيزوّد شهر ويحافظ على اليوم', () {
      // تاريخ في المستقبل عشان مايلفّش أكتر من خطوة واحدة.
      final base = DateTime(DateTime.now().year + 1, 1, 15, 9, 30);
      final m = Appointment(
          title: 'x', category: 'شخصي', when: base, repeat: 'monthly');
      final n = m.nextOccurrence(base);
      expect(n.month, 2);
      expect(n.day, 15);
      expect(n.hour, 9);
    });

    test('isRecurring صح لغير none', () {
      final base = DateTime(2026, 1, 1, 8);
      expect(
          Appointment(title: 'x', category: 'شخصي', when: base).isRecurring,
          isFalse);
      expect(
          Appointment(
                  title: 'x', category: 'شخصي', when: base, repeat: 'weekly')
              .isRecurring,
          isTrue);
    });
  });

  group('ترقية قاعدة البيانات v26 ← v27', () {
    test('جدول دفعات الصيدلية بيتعمل', () async {
      final v26 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v26, 26, 27);
      await v26.insert('pharmacy_batches',
          {'item_id': 1, 'quantity': 3, 'expiry': '2027-01-01'});
      final rows = await v26.query('pharmacy_batches');
      expect(rows.length, 1);
      expect((rows.first['quantity'] as num).toInt(), 3);
      await v26.close();
    });
  });

  group('ترقية قاعدة البيانات v28 ← v29', () {
    test('جدول جلسات النشاط بيتعمل', () async {
      final v28 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v28, 28, 29);
      await v28.insert('activity_sessions', {
        'day': '2026-07-12',
        'type': 'run',
        'distance_km': 5.0,
        'duration_sec': 1800,
        'calories': 350,
        'steps': 6900,
        'created_at': DateTime.now().toIso8601String(),
      });
      final rows = await v28.query('activity_sessions');
      expect(rows.length, 1);
      expect(rows.first['type'], 'run');
      expect((rows.first['distance_km'] as num).toDouble(), 5.0);
      await v28.close();
    });
  });

  group('قائمة الدول', () {
    test('مصر موجودة والبحث بالكود شغّال', () {
      expect(countryByCode('EG')?.ar, 'مصر');
      expect(countryByCode('eg')?.en, 'Egypt'); // غير حسّاس لحالة الأحرف
      expect(countryByCode('ZZ'), null);
      expect(countryByCode(''), null);
    });

    test('كل الأكواد فريدة وحرفين', () {
      final codes = kCountries.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length, reason: 'مفيش كود متكرر');
      expect(kCountries.every((c) => c.code.length == 2), true);
      expect(kCountries.length > 100, true);
    });
  });

  group('ترقية قاعدة البيانات v29 ← v30', () {
    test('جدول الدورة الشهرية بيتعمل', () async {
      final v29 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v29, 29, 30);
      await v29.insert('cycle_logs', {
        'start_day': '2026-06-01',
        'period_days': 5,
        'notes': '',
        'created_at': DateTime.now().toIso8601String(),
      });
      final rows = await v29.query('cycle_logs');
      expect(rows.length, 1);
      expect(rows.first['start_day'], '2026-06-01');
      await v29.close();
    });
  });

  group('ترقية قاعدة البيانات v30 ← v31', () {
    test('جدول التسجيل اليومي للدورة بيتعمل', () async {
      final v30 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v30, 30, 31);
      await v30.insert('cycle_days', {
        'day': '2026-06-05',
        'mood': 'calm',
        'symptoms': 'cramps',
        'flow': 'light',
        'weight': 60.0,
        'note': '',
      });
      final rows = await v30.query('cycle_days');
      expect(rows.length, 1);
      expect(rows.first['mood'], 'calm');
      await v30.close();
    });
  });

  group('ترقية قاعدة البيانات v31 ← v32', () {
    test('جدول حبوب منع الحمل بيتعمل', () async {
      final v31 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v31, 31, 32);
      await v31.insert('pill_logs',
          {'day': '2026-06-07', 'created_at': DateTime.now().toIso8601String()});
      final rows = await v31.query('pill_logs');
      expect(rows.length, 1);
      expect(rows.first['day'], '2026-06-07');
      await v31.close();
    });
  });

  group('ترقية قاعدة البيانات v32 ← v33', () {
    test('عمود العلاقة بيضاف لـcycle_days (آمن ضد التكرار)', () async {
      final v32 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v32.execute('''
        CREATE TABLE cycle_days(
          day TEXT PRIMARY KEY, mood TEXT NOT NULL DEFAULT '',
          symptoms TEXT NOT NULL DEFAULT '', flow TEXT NOT NULL DEFAULT '',
          weight REAL, note TEXT NOT NULL DEFAULT '')''');
      await AppDb.upgradeSchema(v32, 32, 33);
      await v32.insert('cycle_days', {'day': '2026-06-01', 'intimacy': 1});
      final row = (await v32.query('cycle_days')).first;
      expect((row['intimacy'] as num).toInt(), 1);
      await AppDb.upgradeSchema(v32, 32, 33); // تكرار مايكسرش
      await v32.close();
    });
  });

  group('الدورة الشهرية', () {
    test('حساب متوسط الدورة والدورة الجاية والتبويض', () async {
      final repo = CycleRepo();
      final now = DateTime.now().toIso8601String();
      await repo.add(CycleLog(startDay: '2026-05-01', createdAt: now));
      await repo.add(CycleLog(startDay: '2026-05-29', createdAt: now)); // +28
      await repo.add(CycleLog(startDay: '2026-06-26', createdAt: now)); // +28
      final p = await repo.predict();
      expect(p.avgCycleLength, 28);
      expect(p.lastStart, DateTime(2026, 6, 26));
      expect(p.nextStart, DateTime(2026, 7, 24)); // +28
      expect(p.ovulation, DateTime(2026, 7, 10)); // الدورة الجاية − 14
      expect(p.loggedCount, 3);
    });

    test('من غير تسجيل مفيش توقّعات', () async {
      final p = await CycleRepo().predict();
      expect(p.hasData, false);
      expect(p.avgCycleLength, 28);
    });

    test('التسجيل اليومي: مزاج/أعراض/وزن round-trip + مسح لو فاضي', () async {
      final repo = CycleRepo();
      await repo.saveDay(const CycleDay(
        day: '2026-06-10',
        mood: 'tired',
        symptoms: 'cramps,headache',
        flow: 'medium',
        weight: 62.5,
        note: 'تعب',
      ));
      final d = await repo.dayLog('2026-06-10');
      expect(d, isNotNull);
      expect(d!.mood, 'tired');
      expect(d.symptomList, ['cramps', 'headache']);
      expect(d.weight, 62.5);
      // حفظ يوم فاضي بيمسحه.
      await repo.saveDay(const CycleDay(day: '2026-06-10'));
      expect(await repo.dayLog('2026-06-10'), isNull);
    });

    test('أنماط المراحل بتجمّع الأعراض والمزاج حسب المرحلة', () async {
      final repo = CycleRepo();
      final now = DateTime.now().toIso8601String();
      await repo.add(CycleLog(startDay: '2026-06-01', createdAt: now));
      // يوم 2 = فترة الدورة
      await repo.saveDay(
          const CycleDay(day: '2026-06-02', mood: 'tired', symptoms: 'cramps'));
      final ins = await repo.phaseInsights();
      final period = ins.firstWhere((i) => i.phase == 'period');
      expect(period.topMood, 'tired');
      expect(period.topSymptoms.first.key, 'cramps');
    });

    test('فروق الدورات + تعديل مدة الدورة', () async {
      final repo = CycleRepo();
      final now = DateTime.now().toIso8601String();
      final id = await repo.add(CycleLog(startDay: '2026-05-01', createdAt: now));
      await repo.add(CycleLog(startDay: '2026-05-29', createdAt: now)); // +28
      await repo.add(CycleLog(startDay: '2026-06-30', createdAt: now)); // +32
      expect(await repo.cycleIntervals(), [28, 32]);
      await repo.updatePeriodLength(id, 6);
      final log = (await repo.all()).firstWhere((l) => l.id == id);
      expect(log.periodDays, 6);
    });

    test('حبوب منع الحمل: أخذ + streak متتالي', () async {
      final repo = CycleRepo();
      final today = dayKey(DateTime.now());
      final yesterday =
          dayKey(DateTime.now().subtract(const Duration(days: 1)));
      expect(await repo.pillTakenOn(today), false);
      await repo.setPillTaken(yesterday, true);
      await repo.setPillTaken(today, true);
      expect(await repo.pillTakenOn(today), true);
      expect(await repo.pillStreak(), 2);
      await repo.setPillTaken(today, false);
      expect(await repo.pillStreak(), 0); // النهاردة اتشال → السلسلة اتقطعت
    });

    test('شدة الأعراض + التوافق مع الصيغة القديمة', () {
      const d = CycleDay(day: 'x', symptoms: 'cramps:3,headache:1');
      expect(d.symptomMap, {'cramps': 3, 'headache': 1});
      expect(d.symptomList, ['cramps', 'headache']);
      const old = CycleDay(day: 'x', symptoms: 'cramps,headache');
      expect(old.symptomMap['cramps'], 2); // بدون شدة = متوسط
      expect(CycleDay.encodeSymptoms({'cramps': 3}), 'cramps:3');
    });

    test('متوسط مدة النزول من period_days', () async {
      final repo = CycleRepo();
      final now = DateTime.now().toIso8601String();
      await repo.add(
          CycleLog(startDay: '2026-05-01', periodDays: 4, createdAt: now));
      await repo.add(
          CycleLog(startDay: '2026-05-29', periodDays: 6, createdAt: now));
      final p = await repo.predict();
      expect(p.avgPeriodLength, 5); // (4+6)/2
    });
  });

  group('نشاط الـGPS (مشي/جري)', () {
    test('حفظ جلسة وحساب إجمالي اليوم', () async {
      final repo = ActivityRepo();
      final day = dayKey(DateTime.now());
      await repo.add(ActivitySession(
        day: day,
        type: 'walk',
        distanceKm: 2.0,
        durationSec: 1500,
        calories: 90,
        steps: 2800,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await repo.add(ActivitySession(
        day: day,
        type: 'run',
        distanceKm: 3.0,
        durationSec: 1200,
        calories: 210,
        steps: 4100,
        createdAt: DateTime.now().toIso8601String(),
      ));
      final totals = await repo.todayTotals(day);
      expect(totals.distanceKm, 5.0);
      expect(totals.calories, 300);
      expect((await repo.forDay(day)).length, 2);
    });

    test('تقدير السعرات: الجري أعلى من المشي لنفس المسافة', () {
      final walk = estimateCalories(distanceKm: 5, weightKg: 80, running: false);
      final run = estimateCalories(distanceKm: 5, weightKg: 80, running: true);
      expect(run > walk, true);
      expect(walk > 0, true);
    });

    test('تقدير الخطوات من المسافة', () {
      // 720 متر / 0.72 = 1000 خطوة
      expect(estimateSteps(720), 1000);
      expect(estimateSteps(0), 0);
    });
  });

  group('ترقية قاعدة البيانات v27 ← v28', () {
    test('أعمدة الماكروز بتتضاف لجدول الوجبات', () async {
      final v27 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v27.execute('''
        CREATE TABLE meals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day TEXT NOT NULL,
          slot TEXT NOT NULL,
          description TEXT NOT NULL,
          calories REAL
        )''');
      await AppDb.upgradeSchema(v27, 27, 28);
      await v27.insert('meals', {
        'day': '2026-07-12',
        'slot': 'غدا',
        'description': 'فراخ ورز',
        'calories': 500.0,
        'protein': 40.0,
        'carbs': 55.0,
        'fat': 12.0,
        'grams': 300.0,
      });
      final row = (await v27.query('meals')).first;
      expect((row['protein'] as num).toDouble(), 40.0);
      expect((row['carbs'] as num).toDouble(), 55.0);
      expect((row['fat'] as num).toDouble(), 12.0);
      expect((row['grams'] as num).toDouble(), 300.0);
      // آمن ضد التكرار: ترقية تانية مش بترمي خطأ.
      await AppDb.upgradeSchema(v27, 27, 28);
      await v27.close();
    });
  });

  group('قاعدة الأكل والماكروز', () {
    test('البحث بيلاقي الأصناف بالعربي غير حسّاس للهمزات', () {
      expect(searchFoods('فراخ').isNotEmpty, true);
      expect(searchFoods('أرز').isNotEmpty, true); // بهمزة
      expect(searchFoods('رز').isNotEmpty, true); // بدون همزة
      expect(searchFoods('chicken').isNotEmpty, true);
    });

    test('حساب القيم بيتناسب مع الكمية', () {
      final chicken = kFoods.firstWhere((f) => f.en == 'Grilled chicken breast');
      final n = chicken.forQty(200); // ضعف الـ100 جم
      expect(n.kcal.round(), (chicken.kcal * 2).round());
      expect(n.protein.round(), (chicken.protein * 2).round());
    });

    test('جمع القيم الغذائية بيشتغل', () {
      const a = Nutrients(kcal: 100, protein: 10, carbs: 5, fat: 2);
      const b = Nutrients(kcal: 50, protein: 4, carbs: 8, fat: 1);
      final s = a + b;
      expect(s.kcal, 150);
      expect(s.protein, 14);
      expect(s.carbs, 13);
      expect(s.fat, 3);
    });
  });

  group('مكتبة التمارين', () {
    test('فيه تمارين لكل عضلة', () {
      for (final m in kMuscles) {
        expect(filterExercises(muscle: m).isNotEmpty, true,
            reason: 'العضلة $m لازم يكون ليها تمارين');
      }
    });

    test('فلتر «بدون معدّات» بيرجّع تمارين وزن الجسم بس', () {
      final noGear = filterExercises(equipment: 'none');
      expect(noGear.isNotEmpty, true);
      expect(noGear.every((e) => e.equipment == eBody), true);
    });

    test('فلتر معدّة معيّنة بيرجّع نوعها بس', () {
      final dumbbell = filterExercises(equipment: eDumbbell);
      expect(dumbbell.isNotEmpty, true);
      expect(dumbbell.every((e) => e.equipment == eDumbbell), true);
    });
  });

  group('الأنظمة الغذائية', () {
    test('التنشيف عجز والتضخيم فائض عن الحفاظ', () {
      final cut = dietPlanById('cutting')!;
      final bulk = dietPlanById('bulking')!;
      const weight = 80.0; // حفاظ ≈ 2400
      expect(cut.targetCalories(weight) < cut.maintenanceCalories(weight), true);
      expect(bulk.targetCalories(weight) > bulk.maintenanceCalories(weight), true);
    });

    test('توزيع الماكروز بيجمع 100% وجراماته بتطلع بالسعرات', () {
      for (final p in kDietPlans) {
        expect(p.proteinPct + p.carbsPct + p.fatPct, 100,
            reason: 'نظام ${p.id} لازم مجموع نسبه 100');
      }
      final plan = dietPlanById('balanced')!;
      final macros = plan.targetMacros(2000);
      // 30% بروتين من 2000 = 600 سعرة / 4 = 150 جم
      expect(macros.protein.round(), 150);
      // 40% كارب = 800 / 4 = 200 جم
      expect(macros.carbs.round(), 200);
      // 30% دهون = 600 / 9 ≈ 67 جم
      expect(macros.fat.round(), 67);
    });

    test('السعرات مش بتنزل تحت 1200', () {
      final cut = dietPlanById('cutting')!;
      expect(cut.targetCalories(30) >= 1200, true); // وزن صغير جدًا
    });
  });

  group('ترقية قاعدة البيانات v25 ← v26', () {
    test('عمودي form و unit بيتضافوا للأدوية', () async {
      final v25 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v25.execute('''
        CREATE TABLE medications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          times TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1
        )''');
      await AppDb.upgradeSchema(v25, 25, 26);
      await v25.insert('medications', {
        'name': 'بانادول',
        'times': '08:00',
        'form': 'أقراص',
        'unit': 'شريط',
      });
      final row = (await v25.query('medications')).first;
      expect(row['form'], 'أقراص');
      expect(row['unit'], 'شريط');
      await v25.close();
    });
  });

  group('ترقية قاعدة البيانات v24 ← v25', () {
    test('جدول النباتات بيتعمل', () async {
      final v24 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v24, 24, 25);
      await v24.insert('plants', {
        'name': 'صبار',
        'location': 'بلكونة',
        'water_interval_days': 7,
        'last_watered': '2026-07-01',
      });
      final rows = await v24.query('plants');
      expect(rows.length, 1);
      expect((rows.first['water_interval_days'] as num).toInt(), 7);
      await v24.close();
    });
  });

  group('ترقية قاعدة البيانات v23 ← v24', () {
    test('جدول الأصول بيتعمل', () async {
      final v23 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v23, 23, 24);
      await v23.insert('assets',
          {'name': 'دهب', 'type': 'gold', 'value': 50000.0, 'note': ''});
      final rows = await v23.query('assets');
      expect(rows.length, 1);
      expect((rows.first['value'] as num).toDouble(), 50000.0);
      await v23.close();
    });
  });

  group('ترقية قاعدة البيانات v22 ← v23', () {
    test('عمود repeat بيتضاف للمواعيد', () async {
      final v22 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v22.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'شخصي',
          when_at TEXT NOT NULL,
          done INTEGER NOT NULL DEFAULT 0
        )''');
      await AppDb.upgradeSchema(v22, 22, 23);
      await v22.insert('appointments', {
        'title': 'دكتور',
        'when_at': '2026-07-10T10:00:00.000',
        'repeat': 'weekly',
      });
      expect((await v22.query('appointments')).first['repeat'], 'weekly');
      await v22.close();
    });
  });

  group('ترقية قاعدة البيانات v21 ← v22', () {
    test('جداول المحافظ والتحويلات + عمود wallet_id بتتعمل', () async {
      final v21 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      // الجداول اللي الترقية بتعدّل عليها لازم تكون موجودة الأول.
      await v21.execute('''
        CREATE TABLE expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          day TEXT NOT NULL
        )''');
      await v21.execute('''
        CREATE TABLE income(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          source TEXT NOT NULL,
          note TEXT NOT NULL DEFAULT '',
          day TEXT NOT NULL
        )''');
      await AppDb.upgradeSchema(v21, 21, 22);
      final wid = await v21.insert('wallets',
          {'name': 'كاش', 'type': 'cash', 'opening_balance': 500.0});
      await v21.insert('wallet_transfers', {
        'from_wallet': wid,
        'to_wallet': wid,
        'amount': 50.0,
        'day': '2026-07-08',
      });
      await v21.insert('expenses', {
        'amount': 30.0,
        'category': 'food',
        'note': '',
        'day': '2026-07-08',
        'wallet_id': wid,
      });
      await v21.insert('income', {
        'amount': 100.0,
        'source': 'salary',
        'note': '',
        'day': '2026-07-08',
        'wallet_id': wid,
      });
      expect((await v21.query('wallets')).length, 1);
      expect((await v21.query('wallet_transfers')).length, 1);
      expect((await v21.query('expenses')).first['wallet_id'], wid);
      expect((await v21.query('income')).first['wallet_id'], wid);
      await v21.close();
    });
  });

  group('ترقية قاعدة البيانات v20 ← v21', () {
    test('جداول اليوميات والوصفات بتتعمل', () async {
      final v20 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v20, 20, 21);
      await v20.insert('diaries',
          {'day': '2026-07-08', 'text': 'يوم كويس', 'created_at': 'x'});
      await v20.insert('recipes',
          {'name': 'كشري', 'ingredients': 'رز\nعدس', 'steps': 'اسلق'});
      expect((await v20.query('diaries')).length, 1);
      expect((await v20.query('recipes')).length, 1);
      await v20.close();
    });
  });

  group('ترقية قاعدة البيانات v19 ← v20', () {
    test('جداول الأقارب والتحديات والكبسولة + عمود travel_min بتتعمل', () async {
      final v19 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      // نعمل جدول appointments قديم عشان الـ ALTER يلاقيه.
      await v19.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'شخصي',
          when_at TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          remind_before_min INTEGER NOT NULL DEFAULT 60,
          done INTEGER NOT NULL DEFAULT 0,
          postpone_count INTEGER NOT NULL DEFAULT 0
        )''');
      await AppDb.upgradeSchema(v19, 19, 20);
      await v19.insert('relatives', {'name': 'عمي', 'interval_days': 14});
      await v19.insert('challenges',
          {'name': 'شهر بلا سكر', 'start_date': '2026-07-01', 'days': 30});
      await v19.insert('time_capsules',
          {'message': 'خير', 'open_date': '2027-07-07', 'created_at': 'x'});
      await v19.insert('appointments',
          {'title': 'دكتور', 'when_at': '2026-07-08T17:00:00', 'travel_min': 30});
      expect((await v19.query('relatives')).length, 1);
      expect((await v19.query('challenges')).length, 1);
      expect((await v19.query('time_capsules')).length, 1);
      expect((await v19.query('appointments')).first['travel_min'], 30);
      await v19.close();
    });
  });

  group('ترقية قاعدة البيانات v18 ← v19', () {
    test('جداول القرآن والملاحظات السرية وعدّاد الإقلاع بتتعمل', () async {
      final v18 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v18, 18, 19);
      await v18.insert('quran_reviews', {'portion': 'البقرة'});
      await v18.insert('secret_notes',
          {'title': 'الحساب', 'body': '123', 'created_at': 'x'});
      await v18.insert('quit_counters',
          {'name': 'سجائر', 'start_date': '2026-07-01', 'daily_saving': 30});
      expect((await v18.query('quran_reviews')).length, 1);
      expect((await v18.query('secret_notes')).length, 1);
      expect((await v18.query('quit_counters')).length, 1);
      await v18.close();
    });
  });

  group('ترقية قاعدة البيانات v15 ← v18', () {
    test('جداول الصيدلية والضمانات والعدادات بتتعمل', () async {
      final v15 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v15, 15, 18);
      await v15.insert('home_pharmacy', {
        'name': 'بانادول',
        'quantity': 2,
        'expiry': '2027-01-01',
      });
      await v15.insert('warranties', {
        'item_name': 'تلاجة',
        'purchase_date': '2026-01-01',
        'warranty_months': 24,
      });
      await v15.insert('meter_readings', {
        'meter_type': 'electricity',
        'reading': 12345,
        'day': '2026-07-07',
      });
      expect((await v15.query('home_pharmacy')).length, 1);
      expect((await v15.query('warranties')).length, 1);
      expect((await v15.query('meter_readings')).length, 1);
      await v15.close();
    });
  });

  group('ترقية قاعدة البيانات v14 ← v15', () {
    test('جدول الواجبات الاجتماعية بيتعمل', () async {
      final v14 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v14, 14, 15);
      await v14.insert('social_obligations', {
        'person': 'أحمد',
        'type': 'naqoot',
        'direction': 'received',
        'amount': 500,
        'day': '2026-07-07',
      });
      final rows = await v14.query('social_obligations');
      expect(rows.length, 1);
      expect(rows.first['person'], 'أحمد');
      await v14.close();
    });
  });

  group('ترقية قاعدة البيانات v13 ← v14', () {
    test('جدول التقدّم البدني بيتعمل', () async {
      final v13 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v13, 13, 14);
      await v13.insert('body_progress', {
        'day': '2026-07-07',
        'weight': 90,
        'waist': 95,
      });
      final rows = await v13.query('body_progress');
      expect(rows.length, 1);
      expect((rows.first['weight'] as num).toDouble(), 90);
      await v13.close();
    });
  });

  group('ترقية قاعدة البيانات v12 ← v13', () {
    test('جداول الادخار (أهداف ومساهمات) بتتعمل', () async {
      final v12 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v12, 12, 13);
      final gid = await v12.insert('savings_goals', {
        'name': 'موبايل',
        'target': 15000,
        'created_at': '2026-07-07T00:00:00',
      });
      await v12.insert('savings_contributions', {
        'goal_id': gid,
        'amount': 2000,
        'day': '2026-07-07',
      });
      expect((await v12.query('savings_goals')).length, 1);
      expect((await v12.query('savings_contributions')).length, 1);
      await v12.close();
    });
  });

  group('ترقية قاعدة البيانات v11 ← v12', () {
    test('جدول الملابس بيتعمل', () async {
      final v11 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v11, 11, 12);
      await v11.insert('clothes', {
        'name': 'قميص أزرق',
        'category': 'top',
        'season': 'summer',
        'formality': 'formal',
      });
      final rows = await v11.query('clothes');
      expect(rows.length, 1);
      expect(rows.first['name'], 'قميص أزرق');
      await v11.close();
    });
  });

  group('ترقية قاعدة البيانات v10 ← v11', () {
    test('جداول الجيم (جلسات ومجموعات) بتتعمل', () async {
      final v10 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v10, 10, 11);
      final sid = await v10.insert('gym_sessions', {
        'day': '2026-07-07',
        'program': 'دفع',
      });
      await v10.insert('gym_sets', {
        'session_id': sid,
        'exercise': 'بنش برس',
        'reps': 10,
        'weight': 60,
        'set_index': 1,
      });
      expect((await v10.query('gym_sessions')).length, 1);
      expect((await v10.query('gym_sets')).length, 1);
      await v10.close();
    });
  });

  group('ترقية قاعدة البيانات v9 ← v10', () {
    test('جدول السجلات الطبية بيتعمل', () async {
      final v9 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v9, 9, 10);
      await v9.insert('medical_records', {
        'type': 'lab',
        'day': '2026-07-07',
        'title': 'صورة دم',
        'cost': 250,
      });
      final rows = await v9.query('medical_records');
      expect(rows.length, 1);
      expect(rows.first['title'], 'صورة دم');
      await v9.close();
    });
  });

  group('ترقية قاعدة البيانات v8 ← v9', () {
    test('جداول الدخل والدخل الدوري بتتعمل', () async {
      final v8 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v8, 8, 9);
      await v8.insert('income', {
        'amount': 5000,
        'source': 'مرتب',
        'day': '2026-07-01',
      });
      await v8.insert('recurring_income', {
        'source': 'مرتب',
        'amount': 5000,
        'day_of_month': 1,
      });
      expect((await v8.query('income')).length, 1);
      expect((await v8.query('recurring_income')).length, 1);
      await v8.close();
    });
  });

  group('ترقية قاعدة البيانات v7 ← v8', () {
    test('جدول fitness_logs بيتعمل والـ upsert بيحافظ على القيم الموجودة',
        () async {
      final v7 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v7, 7, 8);
      // كتابة السعرات بس.
      await v7.rawInsert(
          'INSERT INTO fitness_logs (day, calories, distance_km) VALUES (?, ?, ?) '
          'ON CONFLICT(day) DO UPDATE SET calories = COALESCE(excluded.calories, calories), '
          'distance_km = COALESCE(excluded.distance_km, distance_km)',
          ['2026-07-07', 300, null]);
      // بعدين كتابة المسافة بس — المفروض السعرات تفضل زي ما هي.
      await v7.rawInsert(
          'INSERT INTO fitness_logs (day, calories, distance_km) VALUES (?, ?, ?) '
          'ON CONFLICT(day) DO UPDATE SET calories = COALESCE(excluded.calories, calories), '
          'distance_km = COALESCE(excluded.distance_km, distance_km)',
          ['2026-07-07', null, 4.2]);
      final rows = await v7.query('fitness_logs');
      expect(rows.length, 1);
      expect(rows.first['calories'], 300);
      expect((rows.first['distance_km'] as num).toDouble(), 4.2);
      await v7.close();
    });
  });

  group('ترقية قاعدة البيانات v6 ← v7', () {
    test('جداول الديون والجمعية والصيانة بتتعمل', () async {
      final v6 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v6, 6, 7);
      await v6.insert('debts', {
        'person': 'أحمد',
        'amount': 200,
        'direction': 'لى',
        'created_at': 'x',
      });
      await v6.insert('gameya', {
        'name': 'ج',
        'amount': 500,
        'total_months': 6,
        'my_turn': 2,
        'start_month': '2026-07',
      });
      await v6.insert('home_maintenance', {
        'name': 'فلتر',
        'interval_months': 6,
        'last_done': '2026-01-01',
      });
      expect((await v6.query('debts')).length, 1);
      expect((await v6.query('gameya')).length, 1);
      expect((await v6.query('home_maintenance')).length, 1);
      await v6.close();
    });
  });

  group('ترقية قاعدة البيانات v5 ← v6', () {
    test('inbox_notes بيتعمل و end_date بيضاف', () async {
      final v5 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v5.execute('''
        CREATE TABLE medications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          dosage TEXT NOT NULL DEFAULT '',
          times TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          active INTEGER NOT NULL DEFAULT 1
        )''');
      await AppDb.upgradeSchema(v5, 5, 6);
      await v5.insert('inbox_notes',
          {'text': 'فكرة', 'created_at': '2026-07-06'});
      await v5.insert('medications', {
        'name': 'مضاد',
        'times': '08:00',
        'end_date': '2026-07-10',
      });
      expect((await v5.query('inbox_notes')).length, 1);
      expect(
          (await v5.query('medications')).first['end_date'], '2026-07-10');
      await v5.close();
    });
  });

  group('ترقية قاعدة البيانات v4 ← v5', () {
    test('جدول الفواتير الدورية بيتعمل', () async {
      final v4 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v4, 4, 5);
      await v4.insert('recurring_bills',
          {'name': 'كهربا', 'amount': 350, 'day_of_month': 5});
      expect((await v4.query('recurring_bills')).length, 1);
      await v4.close();
    });
  });

  group('ترقية قاعدة البيانات v3 ← v4', () {
    test('جداول القياسات والخطوات بتتعمل', () async {
      final v3 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v3, 3, 4);
      await v3.insert('measurements',
          {'day': '2026-07-06', 'type': 'سكر', 'value': 110});
      await v3.insert('steps_logs', {'day': '2026-07-06', 'steps': 4000});
      expect((await v3.query('measurements')).length, 1);
      expect((await v3.query('steps_logs')).length, 1);
      await v3.close();
    });
  });

  group('المهام والاشتراكات والأهداف (v39)', () {
    test('ترقية v38 ← v39 بتعمل الجداول', () async {
      final v38 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v38, 38, 39);
      await v38.insert('projects',
          {'name': 'شغل', 'created_at': '2026-07-14'});
      await v38.insert('tasks',
          {'title': 'مهمة', 'created_at': '2026-07-14'});
      await v38.insert('subscriptions',
          {'name': 'نتفليكس', 'amount': 200, 'created_at': '2026-07-14'});
      await v38.insert('goals', {'title': 'هدف', 'created_at': '2026-07-14'});
      await v38.insert('goal_milestones', {'goal_id': 1, 'title': 'معلم'});
      expect((await v38.query('tasks')).length, 1);
      expect((await v38.query('subscriptions')).length, 1);
      expect((await v38.query('goal_milestones')).length, 1);
      await v38.close();
    });

    test('TasksRepo: حفظ/إنجاز/فلترة بالمشروع', () async {
      final repo = TasksRepo();
      final pid = await repo.saveProject(
          Project(name: 'مشروع', createdAt: DateTime.now().toIso8601String()));
      await repo.save(Task(
          title: 'أ', projectId: pid, priority: 2,
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(Task(
          title: 'ب', createdAt: DateTime.now().toIso8601String()));
      expect((await repo.tasks()).length, 2);
      expect((await repo.tasks(projectId: pid)).length, 1);
      expect((await repo.tasks(projectId: -1)).length, 1); // بدون مشروع
      final open = await repo.tasks(openOnly: true);
      await repo.setDone(open.first.id!, true);
      expect(await repo.openCount(), 1);
    });

    test('SubscriptionsRepo: الإجمالى الشهرى (السنوى ÷ ١٢)', () async {
      final repo = SubscriptionsRepo();
      await repo.save(Subscription(
          name: 'شهرى', amount: 100, cycle: 'monthly',
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(Subscription(
          name: 'سنوى', amount: 1200, cycle: 'yearly',
          createdAt: DateTime.now().toIso8601String()));
      expect(await repo.monthlyTotal(), 200); // 100 + 1200/12
    });

    test('GoalsRepo: معالم + نسبة التقدّم', () async {
      final repo = GoalsRepo();
      final gid = await repo.save(
          Goal(title: 'هدف', createdAt: DateTime.now().toIso8601String()));
      await repo.addMilestone(gid, 'واحد');
      final m2 = await repo.addMilestone(gid, 'اتنين');
      await repo.toggleMilestone(m2, true);
      final (done, total) = await repo.progress(gid);
      expect(done, 1);
      expect(total, 2);
    });
  });

  group('السيارة والتجديدات (v40)', () {
    test('ترقية v39 ← v40 بتعمل الجداول', () async {
      final v39 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v39, 39, 40);
      await v39.insert('cars', {'name': 'عربيتي', 'created_at': '2026-07-14'});
      await v39.insert('car_events',
          {'car_id': 1, 'type': 'fuel', 'day': '2026-07-14', 'created_at': '2026-07-14'});
      await v39.insert('renewals',
          {'title': 'رخصة', 'expiry': '2027-01-01', 'created_at': '2026-07-14'});
      expect((await v39.query('cars')).length, 1);
      expect((await v39.query('car_events')).length, 1);
      expect((await v39.query('renewals')).length, 1);
      await v39.close();
    });

    test('CarsRepo: كفاءة الوقود من فرق العدّادات', () async {
      final repo = CarsRepo();
      final id = await repo.saveCar(
          Car(name: 'س', createdAt: DateTime.now().toIso8601String()));
      // تعبئة أولى عند 1000 كم، تانية عند 1400 كم بـ 40 لتر → 400/40 = 10 كم/ل.
      await repo.saveEvent(CarEvent(
          carId: id, type: 'fuel', day: '2026-07-01', odometer: 1000,
          liters: 35, createdAt: DateTime.now().toIso8601String()));
      await repo.saveEvent(CarEvent(
          carId: id, type: 'fuel', day: '2026-07-10', odometer: 1400,
          liters: 40, createdAt: DateTime.now().toIso8601String()));
      expect(await repo.fuelEconomy(id), 10);
      expect(await repo.totalSpent(id), 0);
    });

    test('RenewalsRepo: قرب الانتهاء', () async {
      final repo = RenewalsRepo();
      final soon = DateTime.now().add(const Duration(days: 10));
      await repo.save(Renewal(
          title: 'بطاقة',
          expiry: dayKey(soon),
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(Renewal(
          title: 'جواز',
          expiry: dayKey(DateTime.now().add(const Duration(days: 400))),
          createdAt: DateTime.now().toIso8601String()));
      final due = await repo.dueSoon(days: 45);
      expect(due.length, 1);
      expect(due.first.title, 'بطاقة');
    });
  });

  group('السفر والتعلّم والحيوانات وكلمات السر (v41)', () {
    test('ترقية v40 ← v41 بتعمل الجداول', () async {
      final v40 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v40, 40, 41);
      await v40.insert('trips', {'title': 'إسكندرية', 'created_at': '2026-07-14'});
      await v40.insert('trip_items', {'trip_id': 1, 'kind': 'packing', 'text': 'شاحن'});
      await v40.insert('courses', {'title': 'فلاتر', 'created_at': '2026-07-14'});
      await v40.insert('pets', {'name': 'مشمش', 'created_at': '2026-07-14'});
      await v40.insert('pet_events',
          {'pet_id': 1, 'type': 'vaccine', 'day': '2026-07-14', 'created_at': '2026-07-14'});
      await v40.insert('passwords', {'label': 'جيميل', 'created_at': '2026-07-14'});
      expect((await v40.query('trip_items')).length, 1);
      expect((await v40.query('courses')).length, 1);
      expect((await v40.query('pet_events')).length, 1);
      expect((await v40.query('passwords')).length, 1);
      await v40.close();
    });

    test('TripsRepo: عناصر مصنّفة + إكمال', () async {
      final repo = TripsRepo();
      final id = await repo.save(
          Trip(title: 'رحلة', createdAt: DateTime.now().toIso8601String()));
      await repo.addItem(id, 'packing', 'جواز');
      final it = await repo.addItem(id, 'todo', 'حجز فندق');
      await repo.toggleItem(it, true);
      final items = await repo.items(id);
      expect(items.length, 2);
      expect(items.where((i) => i.done).length, 1);
    });

    test('CoursesRepo: تقدّم بالوحدات + اكتمال', () async {
      final repo = CoursesRepo();
      final id = await repo.save(Course(
          title: 'ك', totalUnits: 2,
          createdAt: DateTime.now().toIso8601String()));
      var c = (await repo.all()).firstWhere((x) => x.id == id);
      await repo.bumpProgress(c, 2);
      c = (await repo.all()).firstWhere((x) => x.id == id);
      expect(c.doneUnits, 2);
      expect(c.status, 'done');
      expect(c.progress, 1);
    });

    test('PetsRepo + PasswordsRepo: حفظ أساسى', () async {
      final pets = PetsRepo();
      final pid = await pets.savePet(
          Pet(name: 'ريكس', createdAt: DateTime.now().toIso8601String()));
      await pets.saveEvent(PetEvent(
          petId: pid, type: 'vet', day: '2026-07-14',
          createdAt: DateTime.now().toIso8601String()));
      expect((await pets.events(pid)).length, 1);

      final pw = PasswordsRepo();
      await pw.save(PasswordEntry(
          label: 'بنك', secret: '123',
          createdAt: DateTime.now().toIso8601String()));
      expect((await pw.all()).length, 1);
    });
  });

  group('مفكرة الأعراض والتزام الدواء (v42)', () {
    test('ترقية v41 ← v42 بتعمل جدول الأعراض', () async {
      final v41 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v41, 41, 42);
      await v41.insert('symptom_logs',
          {'day': '2026-07-14', 'symptom': 'صداع', 'severity': 4, 'created_at': '2026-07-14'});
      expect((await v41.query('symptom_logs')).length, 1);
      await v41.close();
    });

    test('SymptomsRepo: حفظ + أكثر الأعراض تكرارًا', () async {
      final repo = SymptomsRepo();
      await repo.save(SymptomLog(
          day: '2026-07-10', symptom: 'صداع', severity: 3,
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(SymptomLog(
          day: '2026-07-12', symptom: 'صداع', severity: 4,
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(SymptomLog(
          day: '2026-07-13', symptom: 'مغص', severity: 2,
          createdAt: DateTime.now().toIso8601String()));
      expect((await repo.recent()).length, 3);
      final top = await repo.topSymptoms();
      expect(top.first.symptom, 'صداع');
      expect(top.first.count, 2);
      expect((await repo.since('2026-07-12')).length, 2);
    });

    test('MedsRepo: نسبة الالتزام', () async {
      final repo = MedsRepo();
      final today = dayKey(DateTime.now());
      final id = await repo.save(Medication(
          name: 'دوا', times: ['08:00', '20:00'], active: true));
      // جرعتين/يوم × ٧ أيام = ١٤ متوقّعة؛ ناخد جرعة واحدة النهاردة.
      await repo.setTaken(id, today, '08:00', true);
      final pct = await repo.adherencePercent(days: 7);
      expect(pct, ((1 / 14) * 100).round());
    });
  });

  group('الصيام المتقطّع ومخطّط الوجبات (v43)', () {
    test('ترقية v42 ← v43 بتعمل الجداول', () async {
      final v42 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v42, 42, 43);
      await v42.insert('if_fasts',
          {'start_at': '2026-07-14T08:00:00.000', 'target_hours': 16, 'created_at': '2026-07-14'});
      await v42.insert('meal_plan', {'weekday': 6, 'slot': 'غدا', 'text': 'فراخ'});
      expect((await v42.query('if_fasts')).length, 1);
      expect((await v42.query('meal_plan')).length, 1);
      await v42.close();
    });

    test('FastingRepo: بدء وإنهاء صيام', () async {
      final repo = FastingRepo();
      expect(await repo.current(), isNull);
      await repo.start(targetHours: 16);
      final cur = await repo.current();
      expect(cur, isNotNull);
      expect(cur!.ongoing, isTrue);
      expect(cur.targetHours, 16);
      await repo.stop();
      expect(await repo.current(), isNull);
      expect((await repo.recent()).length, 1);
    });

    test('MealPlanRepo: حفظ خانة + حذف بالنص الفاضى', () async {
      final repo = MealPlanRepo();
      await repo.setItem(6, 'غدا', 'كشري');
      var m = await repo.weekMap();
      expect(m['6|غدا'], 'كشري');
      expect((await repo.allTexts()).contains('كشري'), isTrue);
      await repo.setItem(6, 'غدا', ''); // حذف
      m = await repo.weekMap();
      expect(m.containsKey('6|غدا'), isFalse);
    });
  });

  group('العقل المحلي — بنود جديدة', () {
    test('المهام: بيرجّع عدد المفتوحة', () async {
      await TasksRepo().save(Task(
          title: 'مهمة برين',
          createdAt: DateTime.now().toIso8601String()));
      final r = await LocalBrain.answer('كام مهمة عليا؟');
      expect(r.handled, isTrue);
      expect(r.text.contains('مهمة'), isTrue);
    });

    test('الاشتراكات: بيرجّع الإجمالي الشهري', () async {
      await SubscriptionsRepo().save(Subscription(
          name: 'نتفليكس', amount: 200, cycle: 'monthly',
          createdAt: DateTime.now().toIso8601String()));
      final r = await LocalBrain.answer('اشتراكاتي');
      expect(r.handled, isTrue);
      expect(r.text.contains('نتفليكس'), isTrue);
    });

    test('الصيام: بيقول مش صايم لو مفيش', () async {
      final r = await LocalBrain.answer('انا صايم؟');
      expect(r.handled, isTrue);
    });
  });

  group('جرد الممتلكات واستهلاك العدادات (v44)', () {
    test('ترقية v43 ← v44 بتعمل جدول الجرد', () async {
      final v43 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v43, 43, 44);
      await v43.insert('home_inventory',
          {'name': 'تلاجة', 'value': 15000, 'created_at': '2026-07-14'});
      expect((await v43.query('home_inventory')).length, 1);
      await v43.close();
    });

    test('HomeInventoryRepo: إجمالي القيمة', () async {
      final repo = HomeInventoryRepo();
      await repo.save(HomeInventoryItem(
          name: 'لابتوب', value: 20000,
          createdAt: DateTime.now().toIso8601String()));
      await repo.save(HomeInventoryItem(
          name: 'مكتب', value: 5000,
          createdAt: DateTime.now().toIso8601String()));
      expect(await repo.totalValue(), 25000);
      expect((await repo.all()).length, 2);
    });

    test('MetersRepo: استهلاك + تقدير الفاتورة', () async {
      final repo = MetersRepo();
      await repo.add(const MeterReading(
          meterType: 'electricity', reading: 1000, day: '2026-05-01'));
      await repo.add(const MeterReading(
          meterType: 'electricity', reading: 1200, day: '2026-06-01'));
      await repo.add(const MeterReading(
          meterType: 'electricity', reading: 1500, day: '2026-07-01'));
      final cons = await repo.consumptions('electricity');
      expect(cons.length, 2); // 200 ثم 300
      expect(cons.first.delta, 200);
      expect(cons.last.delta, 300);
      await repo.setRate('electricity', 2); // ٢ ج.م/وحدة
      // المتوسط = 250 × 2 = 500
      expect(await repo.estimateBill('electricity'), 500);
    });
  });

  group('تتبّع الغسيل (v45)', () {
    test('ترقية v44 ← v45 بتضيف عمود needs_wash', () async {
      final v44 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      // نعمل جدول الملابس القديم (من غير needs_wash) قبل الترقية.
      await v44.execute('''CREATE TABLE clothes(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        category TEXT NOT NULL, color TEXT NOT NULL DEFAULT '',
        season TEXT NOT NULL DEFAULT 'all', formality TEXT NOT NULL DEFAULT 'casual',
        photo TEXT NOT NULL DEFAULT '', last_worn TEXT,
        favorite INTEGER NOT NULL DEFAULT 0)''');
      await AppDb.upgradeSchema(v44, 44, 45);
      await v44.insert('clothes',
          {'name': 'قميص', 'category': 'top', 'needs_wash': 1});
      expect((await v44.query('clothes')).first['needs_wash'], 1);
      await v44.close();
    });

    test('WardrobeRepo: سلة الغسيل + غسلت الكل', () async {
      final repo = WardrobeRepo();
      final id = await repo.save(const ClothingItem(name: 'ت', category: 'top'));
      await repo.save(const ClothingItem(name: 'ب', category: 'bottom'));
      expect(await repo.laundryCount(), 0);
      await repo.setNeedsWash(id, true);
      expect(await repo.laundryCount(), 1);
      expect((await repo.laundry()).first.name, 'ت');
      await repo.washAll();
      expect(await repo.laundryCount(), 0);
    });
  });

  group('التسوق: تصنيفات وأسعار وأساسيات (v46)', () {
    test('ترقية v45 ← v46 بتضيف الأعمدة وجدول الأساسيات', () async {
      final v45 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v45.execute('''CREATE TABLE shopping_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        checked INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)''');
      await AppDb.upgradeSchema(v45, 45, 46);
      await v45.insert('shopping_items',
          {'name': 'رز', 'category': 'بقالة', 'price': 30, 'created_at': 'x'});
      await v45.insert('shopping_staples', {'name': 'زيت', 'created_at': 'x'});
      expect((await v45.query('shopping_items')).first['price'], 30);
      expect((await v45.query('shopping_staples')).length, 1);
      await v45.close();
    });

    test('MealsRepo: إجمالي السعر + الأساسيات للقائمة', () async {
      final repo = MealsRepo();
      await repo.addShoppingItem('رز', category: 'بقالة', price: 30);
      await repo.addShoppingItem('لحمة', category: 'لحوم', price: 200);
      expect(await repo.shoppingTotal(), 230);
      await repo.addStaple('زيت');
      await repo.addStaple('رز'); // موجود بالفعل في القائمة
      final added = await repo.addStaplesToList();
      expect(added, 1); // زيت بس (رز موجود)
    });
  });

  group('القراءة والامتنان والتحليلات (v47)', () {
    test('ترقية v46 ← v47 بتعمل الجداول', () async {
      final v46 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v46, 46, 47);
      await v46.insert('books',
          {'title': 'كتاب', 'total_pages': 100, 'created_at': 'x'});
      await v46.insert('gratitude',
          {'day': '2026-07-14', 'text': 'الصحة', 'created_at': 'x'});
      expect((await v46.query('books')).length, 1);
      expect((await v46.query('gratitude')).length, 1);
      await v46.close();
    });

    test('ReadingRepo: تقدّم صفحات + اكتمال', () async {
      final repo = ReadingRepo();
      final id = await repo.save(Book(
          title: 'ك', totalPages: 100,
          createdAt: DateTime.now().toIso8601String()));
      var b = (await repo.all()).firstWhere((x) => x.id == id);
      await repo.setPage(b, 100);
      b = (await repo.all()).firstWhere((x) => x.id == id);
      expect(b.currentPage, 100);
      expect(b.status, 'done');
      expect(await repo.finishedCount(), 1);
    });

    test('GratitudeRepo: حفظ + عدد الأيام', () async {
      final repo = GratitudeRepo();
      await repo.add('نعمة', day: DateTime(2026, 7, 10));
      await repo.add('نعمة تانية', day: DateTime(2026, 7, 10));
      await repo.add('نعمة', day: DateTime(2026, 7, 11));
      expect((await repo.recent()).length, 3);
      expect(await repo.daysCount(), 2); // يومين مختلفين
    });

    test('HabitsRepo: تحليلات (سلسلة + التزام)', () async {
      final repo = HabitsRepo();
      final id = await repo.add('مشي');
      final today = dayKey(DateTime.now());
      await repo.toggle(id, today);
      final stats = await repo.analytics();
      final mine = stats.firstWhere((s) => s.habit.id == id);
      expect(mine.streak >= 1, isTrue);
      expect(mine.recentDone >= 1, isTrue);
    });
  });

  group('المزاج والأمنيات والمشاهدة (v48)', () {
    test('ترقية v47 ← v48 بتعمل الجداول', () async {
      final v47 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v47, 47, 48);
      await v47.insert('mood_logs',
          {'day': '2026-07-14', 'score': 4, 'created_at': 'x'});
      await v47.insert('wishlist', {'name': 'موبايل', 'price': 9000, 'created_at': 'x'});
      await v47.insert('watchlist', {'title': 'فيلم', 'created_at': 'x'});
      expect((await v47.query('mood_logs')).length, 1);
      expect((await v47.query('wishlist')).length, 1);
      expect((await v47.query('watchlist')).length, 1);
      await v47.close();
    });

    test('MoodRepo: صف واحد لليوم + متوسط', () async {
      final repo = MoodRepo();
      await repo.setToday(3);
      await repo.setToday(5); // بيحدّث نفس اليوم مش يضيف
      expect((await repo.recent()).length, 1);
      expect((await repo.forDay(dayKey(DateTime.now())))!.score, 5);
      expect(await repo.average(), 5);
    });

    test('WishlistRepo: إجمالي المعلّق', () async {
      final repo = WishlistRepo();
      await repo.save(WishItem(name: 'أ', price: 100, createdAt: 'x'));
      final id = await repo.save(WishItem(name: 'ب', price: 50, createdAt: 'x'));
      expect(await repo.pendingTotal(), 150);
      await repo.setBought(id, true);
      expect(await repo.pendingTotal(), 100); // المشترى مايتحسبش
    });

    test('WatchlistRepo: حفظ + تغيير حالة', () async {
      final repo = WatchlistRepo();
      final id = await repo.save(WatchItem(title: 'ف', kind: 'series', createdAt: 'x'));
      await repo.setStatus(id, 'done');
      expect((await repo.all()).first.status, 'done');
    });
  });

  group('المراجعة السنوية', () {
    test('بتجمّع مصاريف ومهام السنة', () async {
      final year = DateTime.now().year;
      await MoneyRepo().add(Expense(
          amount: 100, category: 'أكل', day: '$year-03-01'));
      await MoneyRepo().add(Expense(
          amount: 999, category: 'أكل', day: '${year - 1}-03-01')); // سنة تانية
      final stats = await collectYearReview(year);
      final spent = stats.firstWhere((s) => s.label.contains('صرفت'));
      // مصاريف السنة دي بس (100) مش اللى قبلها.
      expect(spent.value.contains('100'), isTrue);
      expect(spent.value.contains('999'), isFalse);
      expect(stats.length >= 8, isTrue);
    });
  });

  group('نظرة الأسبوع (الرئيسية)', () {
    test('بتجمّع مهمة ليها موعد فى الأسبوع الجاى', () async {
      final due = DateTime.now().add(const Duration(days: 2));
      await TasksRepo().save(Task(
          title: 'مهمة الأسبوع',
          dueAt: due.toIso8601String(),
          createdAt: DateTime.now().toIso8601String()));
      final week = await collectWeekOverview();
      expect(week.any((w) => w.text == 'مهمة الأسبوع'), isTrue);
      // مهمة موعدها بعد شهر ما تظهرش.
      await TasksRepo().save(Task(
          title: 'مهمة بعيدة',
          dueAt: DateTime.now().add(const Duration(days: 40)).toIso8601String(),
          createdAt: DateTime.now().toIso8601String()));
      final week2 = await collectWeekOverview();
      expect(week2.any((w) => w.text == 'مهمة بعيدة'), isFalse);
    });
  });

  group('ترقية قاعدة البيانات v2 ← v3', () {
    test('جداول الوجبات والتمرين والمناسبات بتتعمل', () async {
      final v2 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v2, 2, 3);
      await v2.insert('meals',
          {'day': '2026-07-06', 'slot': 'غدا', 'description': 'كشري'});
      await v2.insert('workout_plan', {'weekday': 1, 'title': 'صدر'});
      await v2.insert('occasions', {'title': 'عيد', 'month': 3, 'day': 15});
      await v2.insert('shopping_items',
          {'name': 'رز', 'created_at': '2026-07-06'});
      expect((await v2.query('meals')).length, 1);
      expect((await v2.query('occasions')).length, 1);
      await v2.close();
    });
  });

  group('الرئيسية: «محتاج منك دلوقتي»', () {
    test('بيلمّ المتأخر من كل الأقسام ويرتّبه بالإلحاح', () async {
      final now = DateTime(2026, 7, 15, 14, 0);
      final iso = now.toIso8601String();

      // فاتورة مستحقة (إلحاح ٠)
      await BillsRepo().save(RecurringBill(
          name: 'كهربا', amount: 250, dayOfMonth: 1, category: 'مرافق'));
      // مهمة متأخرة (إلحاح ٠)
      await TasksRepo().save(Task(
          title: 'مهمة فاتت',
          dueAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
          createdAt: iso));
      // موعد بعد ٦ ساعات (إلحاح ٣ — مش قريّب)
      await AppointmentsRepo().save(Appointment(
          title: 'دكتور',
          category: 'صحة',
          when: now.add(const Duration(hours: 6))));
      // نبات محتاج مياه (إلحاح ٦ — أقل أهمية)
      await PlantsRepo().save(Plant(
          name: 'نعناع',
          waterIntervalDays: 2,
          lastWatered: dayKey(now.subtract(const Duration(days: 5)))));

      final items = await collectAttention(now);
      expect(items, isNotEmpty);
      // مرتّب تصاعدياً بالإلحاح: الأهم الأول.
      for (var i = 1; i < items.length; i++) {
        expect(items[i - 1].urgency, lessThanOrEqualTo(items[i].urgency));
      }
      final kinds = items.map((i) => i.kind).toList();
      expect(kinds, contains(AttentionKind.bill));
      expect(kinds, contains(AttentionKind.task));
      expect(kinds, contains(AttentionKind.plant));
      // الفاتورة والمهمة المتأخرة (٠) قبل النبات (٦).
      expect(items.first.urgency, 0);
      expect(items.last.kind, AttentionKind.plant);
      // البنود اللى ليها إجراء فورى ليها نص زرار.
      final bill = items.firstWhere((i) => i.kind == AttentionKind.bill);
      expect(bill.actionLabel, isNotNull);
    });

    test('يوم نضيف = قايمة فاضية (شريط «كله تمام»)', () async {
      final items = await collectAttention(DateTime(2026, 7, 15, 14));
      expect(items, isEmpty);
    });
  });

  group('الرئيسية: ترتيب الأقسام', () {
    Section s(String id) => Section(id, const SizedBox.shrink());

    test('بيطبّق الترتيب المحفوظ', () {
      final ordered = applySectionOrder(
          [s('a'), s('b'), s('c')], ['c', 'a', 'b']);
      expect(ordered.map((x) => x.id).toList(), ['c', 'a', 'b']);
    });

    test('قسم جديد بيفضل مكانه الافتراضى مش بينطّ للآخر', () {
      // الترتيب المحفوظ ماعندوش 'new' — لازم يفضل بعد 'a' زى ما هو.
      final ordered =
          applySectionOrder([s('a'), s('new'), s('b')], ['b', 'a']);
      expect(ordered.map((x) => x.id).toList(), ['b', 'a', 'new']);
      // ولو الترتيب المحفوظ فاضى، بيرجّع نفس الترتيب الأصلى.
      final same = applySectionOrder([s('a'), s('b')], []);
      expect(same.map((x) => x.id).toList(), ['a', 'b']);
    });
  });

  group('الرئيسية: القايمة القابلة للترتيب بترسم فعلاً', () {
    testWidgets('بترسم الهيدر والأقسام من غير أخطاء تخطيط', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReorderableSections(
            storageKey: 'test_home',
            header: const Text('الترحيب'),
            sections: const [
              Section('a', SizedBox(height: 80, child: Text('قسم أ'))),
              Section('b', SizedBox(height: 80, child: Text('قسم ب'))),
              Section('c', SizedBox(height: 80, child: Text('قسم ج'))),
            ],
          ),
        ),
      ));
      // الترتيب بيتحمّل async -> نستنى.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('الترحيب'), findsOneWidget);
      expect(find.text('قسم أ'), findsOneWidget);
      expect(find.text('قسم ج'), findsOneWidget);
    });

    testWidgets('قايمة فاضية = الهيدر لوحده من غير كراش', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReorderableSections(
            storageKey: 'test_empty',
            header: const Text('كله تمام'),
            sections: const [],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('كله تمام'), findsOneWidget);
    });
  });

  group('الرئيسية: يومك فى سطر', () {
    test('الحلقة بتحسب النسبة وتتجاهل اللى مالوش هدف', () {
      const rings = [
        GlanceRing(
            icon: Icons.abc, label: 'صلوات', done: 3, total: 5, color: Colors.green),
        GlanceRing(
            icon: Icons.abc, label: 'مياه', done: 8, total: 8, color: Colors.blue),
        // مفيش أدوية -> total=0 -> مش بتتعرض
        GlanceRing(
            icon: Icons.abc, label: 'أدوية', done: 0, total: 0, color: Colors.pink),
      ];
      expect(rings[0].fraction, closeTo(0.6, 0.001));
      expect(rings[0].complete, isFalse);
      expect(rings[1].complete, isTrue);
      expect(rings[2].fraction, 0); // مفيش قسمة على صفر
      // الملخص بيعدّ اللى ليها هدف بس (٢) واللى خلصت (١).
      // ملحوظة: arNum بيرجّع أرقام لاتينية بقرار سابق فى المشروع.
      expect(glanceSummary(rings), '1 من 2 خلصت');
    });
  });

  group('قاعدة الأكل USDA', () {
    // عيّنة بنفس شكل الأصل الحقيقى (assets/food/usda_foods.json).
    const sample = '''[
      {"id":1,"en":"Chicken, breast, meat only, cooked, roasted","ar":"فراخ صدور — مشوى فى الفرن",
       "cat":"دواجن","kcal":165,"p":31.02,"c":0,"f":3.57,"chol":85,"sodium":74,"prep":"roasted","g":7,
       "pl":"1 cup, chopped","pg":140},
      {"id":2,"en":"Chicken, breast, meat only, cooked, fried","ar":"فراخ صدور — مقلى",
       "cat":"دواجن","kcal":187,"p":33.44,"c":0.51,"f":4.71,"prep":"fried","g":7},
      {"id":3,"en":"Chicken, breast, meat only, cooked, stewed","ar":"فراخ صدور — مسبّك",
       "cat":"دواجن","kcal":151,"p":28.98,"c":0,"f":3.03,"prep":"stewed","g":7},
      {"id":4,"en":"Apples, raw, with skin","ar":"تفاح — نيّئ","cat":"فواكه وعصائر",
       "kcal":52,"p":0.26,"c":13.81,"f":0.17,"fiber":2.4,"sugar":10.39}
    ]''';

    setUp(() => UsdaDb.loadForTests(sample));
    tearDown(UsdaDb.reset);

    test('البحث بالعربى والإنجليزى (ومع اختلاف الهمزات)', () async {
      expect((await UsdaDb.search('فراخ')).length, 3);
      // البحث بيتجاهل الهمزة: «تفاح» و«الأ/ا».
      expect((await UsdaDb.search('تفاح')).single.id, 4);
      expect((await UsdaDb.search('chicken')).length, 3);
      // حرف واحد مابيرجّعش نتايج.
      expect(await UsdaDb.search('ف'), isEmpty);
    });

    test('طرق الطهى: نفس الصنف بيرجّع بدائله مرتّبة بالسعرات', () async {
      final fried = (await UsdaDb.search('مقلى')).single;
      final variants = await UsdaDb.variants(fried);
      // مسبّك ١٥١ < مشوى ١٦٥ < مقلى ١٨٧ — أرقام USDA الحقيقية.
      expect(variants.map((v) => v.kcal).toList(), [151, 165, 187]);
      expect(variants.map((v) => v.prep).toList(),
          ['stewed', 'roasted', 'fried']);
      // صنف من غير مجموعة مالوش بدائل.
      final apple = (await UsdaDb.search('تفاح')).single;
      expect(await UsdaDb.variants(apple), isEmpty);
    });

    test('الحساب بالكمية خطى وبيحافظ على أرقام USDA', () async {
      final roasted = (await UsdaDb.search('مشوى')).single;
      expect(roasted.kcal, 165); // ١٠٠ جم = قيمة USDA زى ما هى
      final n = roasted.forGrams(200);
      expect(n.kcal, closeTo(330, 0.01));
      expect(n.protein, closeTo(62.04, 0.01));
      // العناصر اللى USDA ماعندهاش قيمة ليها بتفضل null — مش صفر مخترع.
      expect(roasted.fiber, isNull);
      expect(n.fiber, isNull);
      expect(n.chol, closeTo(170, 0.01));
    });

    test('التحويل لتسجيل الوجبات بينقل أرقام USDA زى ما هى', () async {
      final roasted = (await UsdaDb.search('مشوى')).single;
      final item = roasted.toFoodItem();
      // الأرقام مانتغيرتش ولا اتقرّبت.
      expect(item.kcal, 165);
      expect(item.protein, 31.02);
      expect(item.carbs, 0);
      expect(item.fat, 3.57);
      // الاسم العربى + الحصة من USDA.
      expect(item.ar, 'فراخ صدور — مشوى فى الفرن');
      expect(item.portion, 140);
      expect(item.unit, 'جم');
      // والحساب بالكمية زى ما بيحصل فى تسجيل الوجبة.
      final n = item.forQty(200);
      expect(n.kcal, closeTo(330, 0.01));
      expect(n.protein, closeTo(62.04, 0.01));
    });

    test('الحصة المنزلية بتيجى من USDA', () async {
      final roasted = (await UsdaDb.search('مشوى')).single;
      expect(roasted.portionLabel, '1 cup, chopped');
      expect(roasted.portionGrams, 140);
      expect(roasted.defaultGrams, 140);
      // صنف من غير حصة -> ١٠٠ جم
      final fried = (await UsdaDb.search('مقلى')).single;
      expect(fried.defaultGrams, 100);
    });
  });

  group('قفل اليوم', () {
    test('بيجمع الناقص وبيقل مع التسجيل', () async {
      final now = DateTime.now();
      final day = dayKey(now);
      // عادة + ٣ صلوات + شوية مياه.
      final hid = await HabitsRepo().add('قراءة');
      for (var i = 0; i < 3; i++) {
        await WorshipRepo().togglePrayer(now, i, true);
      }
      await HealthRepo().setWaterMl(day, 500);
      await SettingsRepo().setWaterGoalMl(2000);

      final s1 = await collectDayClose(now);
      expect(s1.missedPrayers, [3, 4]);
      expect(s1.remainingWaterMl, 1500);
      expect(s1.pendingHabits.length, 1);
      expect(s1.allDone, isFalse);
      // ٢ صلاة + ١ عادة + ١ مياه = ٤ بنود.
      expect(s1.pendingCount, 4);

      // نقفل كل حاجة.
      await WorshipRepo().togglePrayer(now, 3, true);
      await WorshipRepo().togglePrayer(now, 4, true);
      await HabitsRepo().toggle(hid, day);
      await HealthRepo().setWaterMl(day, 2000);
      final s2 = await collectDayClose(now);
      expect(s2.allDone, isTrue);
      expect(s2.pendingCount, 0);
    });
  });

  group('الموجز الصباحى', () {
    test('بيبنى نص فيه التحية والمواعيد والمهام', () async {
      final now = DateTime.now();
      await SettingsRepo().set('user_name', 'أحمد');
      await AppointmentsRepo().save(Appointment(
          title: 'دكتور',
          category: 'صحة',
          when: DateTime(now.year, now.month, now.day, 23, 50)));
      await TasksRepo().save(
          Task(title: 'مهمة', dueAt: now.toIso8601String(),
              createdAt: now.toIso8601String()));
      final brief = await buildMorningBrief(now);
      expect(brief, contains('أحمد'));
      expect(brief, contains('دكتور'));
      expect(brief, contains('مهمة مستحقة'));
      expect(brief.trim().isNotEmpty, isTrue);
    });
  });

  group('مفضّلة الوجبات', () {
    test('frequentMeals بترتّب بالتكرار وlastMeal بترجّع الأحدث', () async {
      final repo = MealsRepo();
      // «فول» ×٣ و«كشرى» ×١.
      for (var i = 0; i < 3; i++) {
        await repo.add(Meal(
            day: '2026-07-1${i + 1}', slot: 'فطار', description: 'فول',
            calories: 300));
      }
      await repo.add(Meal(
          day: '2026-07-16', slot: 'غدا', description: 'كشرى', calories: 711));
      final freq = await repo.frequentMeals(limit: 5);
      expect(freq.first.description, 'فول');
      expect(freq.map((m) => m.description).toSet(), {'فول', 'كشرى'});
      // آخر وجبة = الكشرى (الأحدث id) بقيمها.
      final last = await repo.lastMeal();
      expect(last!.description, 'كشرى');
      expect(last.calories, 711);
    });
  });

  group('المياه بالملى (v51)', () {
    test('ترقية v50 ← v51 بتضيف عمود ml وبتحافظ على الأكواب القديمة', () async {
      final v50 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      // جدول بالشكل القديم (glasses بس) + بيانات قديمة.
      await v50.execute(
          'CREATE TABLE water_logs(day TEXT PRIMARY KEY, glasses INTEGER NOT NULL DEFAULT 0)');
      await v50.insert('water_logs', {'day': '2026-07-10', 'glasses': 6});
      await AppDb.upgradeSchema(v50, 50, 51);
      // العمود اتضاف والبيانات القديمة فضلت.
      final row = (await v50.query('water_logs')).first;
      expect(row['glasses'], 6);
      expect(row['ml'], 0);
      await v50.close();
    });

    test('HealthRepo: تسجيل بالملى + توافق الأكواب + تحويل القديم', () async {
      final repo = HealthRepo();
      const day = '2026-07-16';
      // إضافة بالملى.
      expect(await repo.addWaterMl(day, 300), 300);
      expect(await repo.addWaterMl(day, 250), 550);
      // القراءة بالأكواب (توافق) = ٥٥٠/٢٥٠ مقرّبة.
      expect(await repo.waterOn(day), 2);
      // تحديد الإجمالى مباشرة.
      expect(await repo.setWaterMl(day, 1200), 1200);
      expect(await repo.waterMlOn(day), 1200);
      // بيانات قديمة (أكواب من غير ml) بتتحوّل ×٢٥٠.
      final db = await AppDb.instance;
      await db.insert('water_logs', {'day': '2026-07-01', 'glasses': 4, 'ml': 0},
          conflictAlgorithm: ConflictAlgorithm.replace);
      expect(await repo.waterMlOn('2026-07-01'), 1000);
      // الهدف بالملى + توافقه بالأكواب.
      await SettingsRepo().setWaterGoalMl(2500);
      expect(await SettingsRepo().waterGoalMl(), 2500);
      expect(await SettingsRepo().waterGoal(), 10);
    });
  });

  group('تسجيل الأخطاء (core/log.dart)', () {
    test('logError/logInfo بيعدّوا على debugPrint بعلامات ثابتة', () {
      // الاعتراض ده بيثبت المسار: الدالتين بتنادوا debugPrint فعلًا (وده
      // اللى اتأكد على الجهاز إنه بيوصل logcat فى الريليز — عكس dev.log).
      final captured = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) captured.add(message);
      };
      try {
        logInfo('فتح الرئيسية: 100ms');
        logError('فشل جلب الطقس', Exception('boom'));
      } finally {
        debugPrint = original;
      }
      expect(captured.length, 2);
      expect(captured[0], 'ℹ️ فتح الرئيسية: 100ms');
      expect(captured[1], startsWith('❌ فشل جلب الطقس: '),
          reason: 'العلامة ثابتة عشان الـgrep');
      expect(captured[1], contains('boom'), reason: 'الاستثناء نفسه بيتطبع');
    });

    test('ملف اللوج: بيتكتب بختم وقت وبيتدوّر لما يكبر', () async {
      final tmp = await Directory.systemTemp.createTemp('mylog');
      final f = File('${tmp.path}/app.log');
      AppLog.useFileForTests(f);
      try {
        logInfo('سطر أول');
        logError('فشل حاجة', Exception('boom'));
        await AppLog.flushForTests();
        final text = await AppLog.read();
        expect(text, contains('ℹ️ سطر أول'));
        expect(text, contains('❌ فشل حاجة'));
        expect(RegExp(r'^\[\d\d-\d\d \d\d:\d\d:\d\d\] ').hasMatch(text), true,
            reason: 'كل سطر بختم وقت');
        expect(await AppLog.fileForShare(), isNotNull);

        // التدوير: ملف أكبر من الحد بيتقص لآخر نصه (الأحدث بيفضل).
        await f.writeAsString('X' * 200 * 1024);
        AppLog.append('السطر الأحدث');
        await AppLog.flushForTests();
        expect(await f.length(), lessThan(140 * 1024),
            reason: 'اتدوّر فماكبرش للأبد');
        expect(await AppLog.read(), contains('السطر الأحدث'));

        // المسح بيرجّع كل حاجة لأول السطر.
        await AppLog.clear();
        expect(await AppLog.read(), '');
        expect(await AppLog.fileForShare(), isNull,
            reason: 'ملف فاضى مايتشاركش');
      } finally {
        AppLog.resetForTests();
        await tmp.delete(recursive: true);
      }
    });

    test('الكتابة بتحصل لوحدها من غير flush يدوى (مسار الـTimer الحقيقى)',
        () async {
      // التست ده بيجرّب اللى بيحصل فى التطبيق فعلًا: سطر بيتسجّل والكتابة
      // بتتأجّل للـTimer — من غير أى نداء يدوى لـflush.
      final tmp = await Directory.systemTemp.createTemp('mylog_timer');
      final f = File('${tmp.path}/app.log');
      AppLog.useFileForTests(f);
      try {
        logInfo('سطر بيتكتب لوحده');
        await Future<void>.delayed(const Duration(seconds: 3));
        expect(await f.exists(), true,
            reason: 'الـTimer المفروض كتب الملف من غير نداء يدوى');
        expect(await f.readAsString(), contains('سطر بيتكتب لوحده'));
      } finally {
        AppLog.resetForTests();
        await tmp.delete(recursive: true);
      }
    });

    test('اللوجر مايرميش استثناء لو الملف مش متاح', () async {
      AppLog.resetForTests(); // مفيش ملف — زى قبل init أو لو فشل
      expect(() {
        logInfo('من غير ملف');
        logError('خطأ من غير ملف', Exception('x'));
      }, returnsNormally, reason: 'اللوجر عمره ما يكسر التطبيق');
      expect(await AppLog.read(), '');
    });
  });

  group('تعميق المهام والعادات (v52)', () {
    test('ترقية v51 ← v52 بتضيف الأعمدة والجداول الجديدة', () async {
      final v51 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      // جداول بالشكل القديم (قبل repeat_rule / target_per_day / count).
      await v51.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          "project_id INTEGER, title TEXT NOT NULL, notes TEXT NOT NULL DEFAULT '', "
          'due_at TEXT, priority INTEGER NOT NULL DEFAULT 1, '
          'done INTEGER NOT NULL DEFAULT 0, done_at TEXT, created_at TEXT NOT NULL)');
      await v51.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0, '
          'created_at TEXT NOT NULL)');
      await v51.execute(
          'CREATE TABLE habit_logs(habit_id INTEGER NOT NULL, day TEXT NOT NULL, '
          'PRIMARY KEY(habit_id, day))');
      await v51.insert('habits', {'name': 'قراءة', 'created_at': '2026-07-01'});
      await v51.insert('habit_logs', {'habit_id': 1, 'day': '2026-07-01'});
      await AppDb.upgradeSchema(v51, 51, 52);
      // الأعمدة الجديدة بقيمها الافتراضية والبيانات القديمة سليمة.
      final h = (await v51.query('habits')).first;
      expect(h['target_per_day'], 1);
      final l = (await v51.query('habit_logs')).first;
      expect(l['count'], 1);
      // الجداول الجديدة اتعملت وبتقبل صفوف.
      await v51.insert('subtasks', {'task_id': 1, 'title': 'خطوة'});
      await v51.insert('focus_sessions',
          {'minutes': 25, 'day': '2026-07-16', 'created_at': 'x'});
      await v51.close();
    });

    test('nextOccurrence: يومى/أسبوعى/شهرى + اللحاق بموعد فات', () {
      final base = DateTime(2026, 7, 10, 9);
      final now = DateTime(2026, 7, 16, 8);
      expect(TasksRepo.nextOccurrence(base, 'daily', now),
          DateTime(2026, 7, 16, 9));
      expect(TasksRepo.nextOccurrence(base, 'weekly', now),
          DateTime(2026, 7, 17, 9));
      expect(TasksRepo.nextOccurrence(base, 'monthly', now),
          DateTime(2026, 8, 10, 9));
    });

    test('مهمة متكررة: تمامها بيرحّلها لموعدها الجاى ومش بيقفلها', () async {
      final repo = TasksRepo();
      final due = DateTime.now().add(const Duration(hours: 2));
      final id = await repo.save(Task(
          title: 'رياضة',
          dueAt: due.toIso8601String(),
          repeatRule: 'daily',
          createdAt: DateTime.now().toIso8601String()));
      // مهمة فرعية متعلّمة — المفروض ترجع فاضية للدورة الجاية.
      final sid = await repo.addSubtask(id, 'إحماء');
      await repo.setSubtaskDone(sid, true);
      await repo.setDone(id, true);
      final t = (await repo.tasks()).firstWhere((x) => x.id == id);
      expect(t.done, false, reason: 'المتكررة بتترحّل مش بتتقفل');
      expect(t.due!.isAfter(due), true);
      expect((await repo.subtasks(id)).single.done, false);
      // المهمة العادية بتتقفل عادى.
      final id2 = await repo.save(
          Task(title: 'مرة واحدة', createdAt: DateTime.now().toIso8601String()));
      await repo.setDone(id2, true);
      expect((await repo.tasks()).firstWhere((x) => x.id == id2).done, true);
    });

    test('المهام الفرعية: إضافة/تعليم/تقدّم/بتتمسح مع المهمة', () async {
      final repo = TasksRepo();
      final id = await repo.save(
          Task(title: 'مشروع', createdAt: DateTime.now().toIso8601String()));
      await repo.addSubtask(id, 'أ');
      final b = await repo.addSubtask(id, 'ب');
      await repo.setSubtaskDone(b, true);
      expect(await repo.subtaskProgress(id), (1, 2));
      expect((await repo.subtaskProgressAll())[id], (1, 2));
      await repo.delete(id);
      expect(await repo.subtasks(id), isEmpty);
    });

    test('جلسات التركيز بتتجمع باليوم', () async {
      final repo = TasksRepo();
      await repo.logFocus(minutes: 25);
      await repo.logFocus(minutes: 15);
      expect(await repo.focusMinutesOn(dayKey(DateTime.now())), 40);
    });

    test('عادة معدودة: اليوم بيتحسب لما العدّاد يوصل للهدف بس', () async {
      final repo = HabitsRepo();
      final id = await repo.add('مياه دوا', targetPerDay: 3);
      final day = dayKey(DateTime.now());
      expect(await repo.increment(id, day), 1);
      expect(await repo.increment(id, day), 2);
      expect((await repo.doneOn(day)).contains(id), false,
          reason: '٢ من ٣ لسه مش متعملة');
      expect(await repo.increment(id, day), 3);
      expect((await repo.doneOn(day)).contains(id), true);
      expect((await repo.daysFor(id)).contains(day), true,
          reason: 'اليوم الكامل بيتحسب فى السلسلة');
      // النقصان بيرجعها ناقصة.
      expect(await repo.decrement(id, day), 2);
      expect((await repo.daysFor(id)).contains(day), false);
      // markDone بيكمّلها على طول (زى شاشة قفل اليوم).
      await repo.markDone(id, day);
      expect(await repo.countOn(id, day), 3);
      // العادة العادية (هدف ١) شغالة toggle زى ما هى.
      final id2 = await repo.add('قراءة');
      expect(await repo.toggle(id2, day), true);
      expect((await repo.doneOn(day)).contains(id2), true);
    });

    test('إحصائية صلاة الشهر: عدّ لكل صلاة + الأيام الكاملة + النسبة', () async {
      final repo = WorshipRepo();
      // يومين كاملين + يوم فيه الفجر بس، والشهر عدّى منه ١٠ أيام.
      for (var d = 1; d <= 2; d++) {
        for (var p = 0; p < 5; p++) {
          await repo.togglePrayer(DateTime(2026, 7, d), p, true);
        }
      }
      await repo.togglePrayer(DateTime(2026, 7, 3), 0, true);
      final m = await repo.monthlyPrayerStats(DateTime(2026, 7, 10));
      expect(m.perPrayer[0], 3, reason: 'الفجر اتسجّل ٣ مرات');
      expect(m.perPrayer[4], 2);
      expect(m.fullDays, 2);
      expect(m.totalLogged, 11);
      expect(m.elapsedDays, 10);
      expect(m.percent, 22, reason: '١١ من ٥٠ صلاة ممكنة');
    });

    test('ميزان السعرات: متوسط الأيام المتسجّلة بس + العجز عن الهدف', () {
      const k = KcalBalance(
        days: [
          ('d1', 1800),
          ('d2', 0),
          ('d3', 2200),
          ('d4', 0),
          ('d5', 2000),
          ('d6', 0),
          ('d7', 0),
        ],
        goal: 2200,
        weightWeeklyRate: -0.5,
      );
      expect(k.loggedDays.length, 3, reason: 'يوم من غير تسجيل مش «صفر أكل»');
      expect(k.avgIntake, 2000);
      expect(k.dailyBalance, -200);
      // من غير هدف مفيش حكم عجز/فائض.
      const k2 =
          KcalBalance(days: [('d1', 1800)], goal: 0, weightWeeklyRate: null);
      expect(k2.dailyBalance, isNull);
    });
  });

  group('ذكاء محلى — تحاليل وتطعيمات وأطباق واقتراحات سياقية', () {
    test('«آخر سكر صائم كام» بيجاوب من التحاليل المتسجلة + الاتجاه', () async {
      final repo = LabResultsRepo();
      await repo.save(const LabResult(
          name: 'سكر صائم', value: 110, unit: 'mg/dL', date: '2026-06-01',
          refLow: '70', refHigh: '100', createdAt: 'x'));
      await repo.save(const LabResult(
          name: 'سكر صائم', value: 95, unit: 'mg/dL', date: '2026-07-01',
          refLow: '70', refHigh: '100', createdAt: 'x'));
      final r = await LocalBrain.answer('آخر سكر صائم كام؟');
      expect(r.handled, true);
      expect(r.text, contains('سكر صائم'));
      expect(r.text, contains(arNum('95')), reason: 'آخر قيمة');
      expect(r.text, contains(tr('نازل', 'Down')), reason: 'الاتجاه عن اللى قبلها');
      // «تحاليلي» العامة بترجّع القائمة.
      final all = await LocalBrain.answer('تحاليلي');
      expect(all.handled, true);
      expect(all.text, contains('سكر صائم'));
    });

    test('«التطعيمات» بيرجّع آخر جرعة والجرعات الجاية', () async {
      final due = dayKey(DateTime.now().add(const Duration(days: 3)));
      await VaccinationsRepo().save(Vaccination(
          name: 'تيتانوس', person: 'أنا', date: '2026-01-10',
          nextDue: due, createdAt: 'x'));
      final r = await LocalBrain.answer('التطعيمات');
      expect(r.handled, true);
      expect(r.text, contains('تيتانوس'));
      expect(r.text, contains(due));
    });

    test('«الكشرى فيه كام سعرة» بيحسب من أرقام USDA الحقيقية', () async {
      UsdaDb.reset();
      UsdaDb.loadForTests(
          File('assets/food/usda_foods.json').readAsStringSync());
      final r = await LocalBrain.answer('الكشرى فيه كام سعرة؟');
      expect(r.handled, true);
      expect(r.text, contains('كشرى'));
      expect(r.text, contains(tr('سعرات', 'Calories')));
      expect(r.text, contains(tr('بروتين', 'Protein')));
      UsdaDb.reset();
    });

    test('الاقتراحات السياقية: فاتورة مستحقة + تحليل خارج النطاق', () async {
      final now = DateTime.now();
      await BillsRepo().save(RecurringBill(
          name: 'الكهربا', amount: 300, dayOfMonth: now.day.clamp(1, 28)));
      await LabResultsRepo().save(const LabResult(
          name: 'فيتامين د', value: 12, unit: 'ng/mL', date: '2026-07-01',
          refLow: '30', refHigh: '100', createdAt: 'x'));
      final tips = await contextualTips(at: now);
      expect(tips.any((t) => t.contains('الكهربا')), true,
          reason: 'الفاتورة المستحقة تظهر');
      expect(tips.any((t) => t.contains(tr('خارج النطاق', 'out of range'))),
          true);
      expect(tips.length, lessThanOrEqualTo(3));
      // بتتحقن فى الموجز الصباحى (من غير الإيموجى).
      final brief = await buildMorningBrief();
      expect(brief, contains('الكهربا'));
      expect(brief.contains('🧾'), false, reason: 'الإيموجى بيتشال للـTTS');
    });
  });

  group('تعديل صلوات يوم فائت', () {
    test('صلاة اتسجّلت بأثر رجعى بتتحسب فى سلسلة الأيام الكاملة', () async {
      final repo = WorshipRepo();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      // النهارده كامل، وامبارح ناقص العشا (اتصلّت بعد ١٢ وما اتسجّلتش).
      for (var i = 0; i < 5; i++) {
        await repo.togglePrayer(today, i, true);
      }
      for (var i = 0; i < 4; i++) {
        await repo.togglePrayer(yesterday, i, true);
      }
      expect(await repo.fullDaysStreak(), 1, reason: 'امبارح لسه ناقص');
      // التعديل بأثر رجعى — زى شيت «تعديل يوم فائت».
      await repo.togglePrayer(yesterday, 4, true);
      expect((await repo.prayedOn(yesterday)).length, 5);
      expect(await repo.fullDaysStreak(), 2,
          reason: 'العشا اتسجّلت فى يومها فاليومين بقوا كاملين');
    });
  });

  group('الأكلات المصرية (محسوبة من USDA)', () {
    // عيّنة أصل صغيرة بمكوّنات كشرى — نفس شكل الأصل الحقيقى.
    const sample = '''[
      {"id":168880,"en":"Rice, white, medium-grain, enriched, cooked","ar":"رز أبيض",
       "cat":"حبوب ومكرونة","kcal":130,"p":2.38,"c":28.59,"f":0.21},
      {"id":169737,"en":"Pasta, cooked, enriched, without added salt","ar":"مكرونة",
       "cat":"حبوب ومكرونة","kcal":158,"p":5.8,"c":30.86,"f":0.93},
      {"id":172421,"en":"Lentils, cooked, boiled, without salt","ar":"عدس مسلوق",
       "cat":"بقوليات","kcal":116,"p":9.02,"c":20.13,"f":0.38,"fiber":7.9},
      {"id":173800,"en":"Chickpeas, canned","ar":"حمص","cat":"بقوليات",
       "kcal":139,"p":7.05,"c":22.5,"f":2.83},
      {"id":170054,"en":"Tomato products, canned, sauce","ar":"صلصة طماطم",
       "cat":"خضار","kcal":24,"p":1.2,"c":5.3,"f":0.3},
      {"id":170000,"en":"Onions, raw","ar":"بصل — نيّئ","cat":"خضار",
       "kcal":40,"p":1.1,"c":9.34,"f":0.1},
      {"id":171411,"en":"Oil, soybean","ar":"زيت نباتى","cat":"دهون وزيوت",
       "kcal":884,"p":0,"c":0,"f":100}
    ]''';

    setUp(() => UsdaDb.loadForTests(sample));
    tearDown(UsdaDb.reset);

    test('كشرى بتتحسب من مكوّناته بأرقام USDA (مش مكتوبة بالإيد)', () async {
      final koshari =
          kEgyptianDishes.firstWhere((d) => d.ar == 'كشرى');
      final n = await dishNutrients(koshari);
      expect(n, isNotNull);
      // الحساب اليدوى المتوقّع من نفس الأرقام (٧١١ سعرة تقريباً).
      expect(n!.kcal, closeTo(711, 3));
      // البروتين والكارب برضه محسوبين.
      expect(n.protein, greaterThan(20));
      expect(n.carbs, greaterThan(100));
      // الألياف اتجمعت من العدس (المكوّن الوحيد اللى ليه fiber).
      expect(n.fiber, isNotNull);
      expect(n.fiber, greaterThan(0));
    });

    test('لو مكوّن مفقود بترجّع null (مايخترعش رقم)', () async {
      // أصل ناقص فيه الرز بس.
      UsdaDb.loadForTests(
          '[{"id":168880,"en":"Rice","cat":"","kcal":130,"p":2,"c":28,"f":0}]');
      final koshari = kEgyptianDishes.firstWhere((d) => d.ar == 'كشرى');
      expect(await dishNutrients(koshari), isNull);
    });

    test('تسجيل طبق كوجبة بينقل القيم المحسوبة زى ما هى', () async {
      // نبنى وجبة بنفس اللى بيعمله زرار «سجّلها كوجبة» — القيم من dishNutrients.
      final koshari = kEgyptianDishes.firstWhere((d) => d.ar == 'كشرى');
      final n = await dishNutrients(koshari);
      expect(n, isNotNull);
      const plates = 2.0;
      await MealsRepo().add(Meal(
        day: '2026-07-16',
        slot: 'غدا',
        description: koshari.ar,
        calories: n!.kcal * plates,
        protein: n.protein * plates,
        carbs: n.carbs * plates,
        fat: n.fat * plates,
        grams: koshari.servingGrams * plates,
      ));
      final meals = await MealsRepo().forDay('2026-07-16');
      expect(meals.length, 1);
      // القيمة المسجّلة = المحسوبة × عدد الأطباق (١٤٢٢ ≈ ٧١١×٢).
      expect(meals.first.calories, closeTo(711 * 2, 6));
      expect(meals.first.description, 'كشرى');
      // وبتتجمّع فى إجمالى اليوم.
      final tot = await MealsRepo().dayNutrients('2026-07-16');
      expect(tot.kcal, closeTo(711 * 2, 6));
    });

    test('البحث بيلاقى الأكلة بالعربى', () {
      expect(searchDishes('كشرى').isNotEmpty, isTrue);
      expect(searchDishes('كشري').isNotEmpty, isTrue); // بالياء برضه
      expect(searchDishes('فول').any((d) => d.ar == 'فول مدمس'), isTrue);
      expect(searchDishes('محشى').length, greaterThanOrEqualTo(3)); // ورق/كرنب/فلفل
      expect(searchDishes('حاجة مش موجودة'), isEmpty);
    });

    test('كل fdcId فى كل الوصفات موجود فى الأصل المشحون الحقيقى', () async {
      // مايستعملش loadForTests — بيقرا assets/food/usda_foods.json الفعلى.
      UsdaDb.reset();
      final raw = File('assets/food/usda_foods.json').readAsStringSync();
      final ids = {
        for (final m in jsonDecode(raw) as List) (m as Map)['id'] as int
      };
      final missing = <String>[];
      for (final dish in kEgyptianDishes) {
        for (final part in dish.parts) {
          if (!ids.contains(part.fdcId)) {
            missing.add('${dish.ar} → ${part.fdcId}');
          }
        }
      }
      expect(missing, isEmpty,
          reason: 'مكوّنات مش موجودة فى القاعدة (هتخلى الأكلة ترجّع null): '
              '${missing.join(", ")}');
    });
  });

  group('اللوحة الشاملة', () {
    test('بتطلّع أرقام حية للأقسام اللى فيها بيانات وتتخطى الفاضية', () async {
      final now = DateTime.now();
      // لوحة فاضية: الأقسام الاختيارية مالهاش كروت.
      final empty = await collectDashboard(now);
      final emptyKeys = empty.map((s) => s.key).toSet();
      expect(emptyKeys.contains('debts'), isFalse, reason: 'مفيش ديون');
      expect(emptyKeys.contains('subs'), isFalse, reason: 'مفيش اشتراكات');
      // المهام كارت دايم (حتى لو صفر) عشان بند أساسى.
      expect(emptyKeys.contains('tasks'), isTrue);

      // نضيف بيانات حقيقية.
      final iso = now.toIso8601String();
      await DebtsRepo().add(Debt(
          person: 'أحمد', amount: 300, direction: 'عليا', createdAt: iso));
      await SubscriptionsRepo().save(Subscription(
          name: 'نتفليكس', amount: 200, createdAt: iso));
      await TasksRepo().save(Task(title: 'مهمة', createdAt: iso));

      final full = await collectDashboard(now);
      final byKey = {for (final s in full) s.key: s};
      // الديون ظهرت بالصافى الصحيح.
      expect(byKey.containsKey('debts'), isTrue);
      expect(byKey['debts']!.value.contains('300'), isTrue);
      expect(byKey['debts']!.sub, contains('عليك'));
      // الاشتراكات ظهرت.
      expect(byKey.containsKey('subs'), isTrue);
      expect(byKey['subs']!.value.contains('200'), isTrue);
      // المهام عدّت.
      expect(byKey['tasks']!.value, arNum(1));
      // كل كارت لازم يبقى ليه عنوان وقيمة (مفيش كارت فاضى).
      for (final s in full) {
        expect(s.title.trim().isNotEmpty, isTrue);
        expect(s.value.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('نصوص الرئيسية مش مقصوصة (عربى + إنجليزى)', () {
    // بنقيس عرض كل نص بالفعل بـTextPainter عند نفس المقاسات اللى فى الشاشة،
    // ونتأكد إن `FittedBox(scaleDown)` مش هيصغّر الخط لدرجة مش مقروءة.
    double textWidth(String s, double fontSize) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: fontSize)),
        textDirection: TextDirection.rtl,
        maxLines: 1,
      )..layout();
      return tp.width;
    }

    /// نسبة التصغير اللى FittedBox هيعملها (١ = مفيش تصغير).
    double shrink(String s, double fontSize, double available) {
      final w = textWidth(s, fontSize);
      return w <= available ? 1.0 : available / w;
    }

    tearDown(() => AppState.locale.value = const Locale('ar'));

    test('بنود شيت الإضافة بتبان كاملة فى اللغتين (٣ فى الصف، سطرين)', () {
      // ٣ فى الصف على أضيق شاشة شائعة (٣٢٠dp) ناقص هوامش الشيت والبند.
      // البند بيلف على سطرين، فاللى بيحدد أقل عرض هو **أطول كلمة** مش النص كله.
      const available = (320 - 24) / 3 - 8;
      for (final locale in ['ar', 'en']) {
        AppState.locale.value = Locale(locale);
        for (final a in quickActionCatalog()) {
          final longest = a.label
              .split(' ')
              .reduce((x, y) => textWidth(x, 13) >= textWidth(y, 13) ? x : y);
          final f = shrink(longest, 13, available);
          expect(f, greaterThan(0.8),
              reason: 'البند «${a.label}» ($locale): أطول كلمة «$longest» '
                  'هتتصغّر لـ${(f * 100).round()}% — يبقى مش مقروء');
        }
      }
    });

    test('أزرار صف الرئيسية الـ٥ بتبان كاملة فى اللغتين', () {
      // ٥ أزرار على شاشة ٣٢٠dp ناقص هوامش الكارت — سطر واحد، فالأسماء لازم
      // تفضل قصيرة (عشان كده «Appointments» بقت «Agenda»).
      const available = (320 - 32) / 5 - 4;
      for (final locale in ['ar', 'en']) {
        AppState.locale.value = Locale(locale);
        final labels = [
          tr('إضافة', 'Add'),
          tr('الفلوس', 'Money'),
          tr('مواعيد', 'Agenda'),
          tr('المهام', 'Tasks'),
          tr('صوت', 'Voice'),
        ];
        for (final l in labels) {
          final f = shrink(l, 11, available);
          expect(f, greaterThan(0.8),
              reason: 'زرار «$l» ($locale) هيتصغّر لـ${(f * 100).round()}%');
        }
      }
    });
  });

  group('الجولة التعريفية', () {
    test('الشرايح مكتملة (عنوان + شرح لكل واحدة)', () {
      final slides = tourSlides();
      expect(slides.length, greaterThanOrEqualTo(5));
      for (final s in slides) {
        expect(s.title.trim().isNotEmpty, isTrue);
        expect(s.body.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('البحث الموحّد الموسّع', () {
    test('بيلاقى البنود الجديدة (مهام/تطعيمات/تحاليل/اشتراكات)', () async {
      final now = DateTime.now().toIso8601String();
      await TasksRepo().save(Task(title: 'مهمة الأسد', createdAt: now));
      await VaccinationsRepo()
          .save(Vaccination(name: 'تطعيم الأسد', createdAt: now));
      await LabResultsRepo()
          .save(LabResult(name: 'تحليل الأسد', value: 5, createdAt: now));
      await SubscriptionsRepo().save(Subscription(
          name: 'اشتراك الأسد', amount: 100, createdAt: now));

      final hits = await SearchRepo().search('الأسد');
      final kinds = hits.map((h) => h.kind).toSet();
      expect(kinds.containsAll({'task', 'vaccination', 'lab', 'subscription'}),
          isTrue,
          reason: 'البحث لازم يغطى البنود الجديدة كمان');
      // كلمة حرف واحد مابترجّعش نتايج.
      expect(await SearchRepo().search('ا'), isEmpty);
    });
  });

  group('تأجيل تذكير الموعد', () {
    test('byId بترجّع الموعد (اللى زرار «أجّل ساعة» بيعيد جدولته)', () async {
      final repo = AppointmentsRepo();
      final id = await repo.save(Appointment(
        title: 'دكتور',
        category: 'صحة',
        when: DateTime.now().add(const Duration(hours: 3)),
      ));
      final got = await repo.byId(id);
      expect(got, isNotNull);
      expect(got!.title, 'دكتور');
      expect(got.done, isFalse);
      // id مش موجود → null (الـsnooze بيقف من غير ما يكسر).
      expect(await repo.byId(999999), isNull);
    });
  });

  group('مؤشرات التحاليل (v50)', () {
    test('ترقية v49 ← v50 بتعمل جدول التحاليل', () async {
      final v49 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await AppDb.upgradeSchema(v49, 49, 50);
      await v49.insert('lab_results', {
        'name': 'سكر صائم',
        'value': 95,
        'created_at': DateTime.now().toIso8601String(),
      });
      expect((await v49.query('lab_results')).length, 1);
      await v49.close();
    });

    test('LabResultsRepo: اتجاه + خارج النطاق + آخر نتيجة لكل تحليل', () async {
      final repo = LabResultsRepo();
      final now = DateTime.now().toIso8601String();
      await repo.save(LabResult(
          name: 'سكر صائم',
          value: 90,
          unit: 'mg/dL',
          date: '2026-01-01',
          refLow: '70',
          refHigh: '100',
          createdAt: now));
      await repo.save(LabResult(
          name: 'سكر صائم',
          value: 130, // فوق النطاق
          unit: 'mg/dL',
          date: '2026-03-01',
          refLow: '70',
          refHigh: '100',
          createdAt: now));
      await repo.save(LabResult(
          name: 'فيتامين د',
          value: 20, // تحت النطاق
          date: '2026-02-01',
          refLow: '30',
          refHigh: '100',
          createdAt: now));

      // forName مرتّب تصاعدياً بالتاريخ (للرسم).
      final sugar = await repo.forName('سكر صائم');
      expect(sugar.map((r) => r.value).toList(), [90, 130]);
      // آخر نتيجة لكل تحليل.
      final latest = await repo.latestPerName();
      expect(latest.length, 2);
      final latestSugar = latest.firstWhere((r) => r.name == 'سكر صائم');
      expect(latestSugar.value, 130);
      expect(latestSugar.status, 1); // فوق
      // عدد التحاليل خارج النطاق فى آخر قراءة = السكر (فوق) + فيتامين د (تحت).
      expect(await repo.outOfRangeCount(), 2);
    });
  });

  group('سجل التطعيمات (v49)', () {
    test('ترقية v48 ← v49 بتعمل الجدول وتضيف عمود موقع الموعد', () async {
      // نبدأ من قاعدة فاضية بجدول مواعيد قديم (من غير location) — زى نسخة 48.
      final v48 = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false));
      await v48.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'شخصي',
          when_at TEXT NOT NULL
        )''');
      await AppDb.upgradeSchema(v48, 48, 49);
      // الجدول الجديد اتعمل.
      await v48.insert('vaccinations', {
        'name': 'تيتانوس',
        'created_at': DateTime.now().toIso8601String(),
      });
      expect((await v48.query('vaccinations')).length, 1);
      // عمود location اتضاف على المواعيد القديمة.
      await v48.insert('appointments', {
        'title': 'دكتور',
        'category': 'صحة',
        'when_at': DateTime.now().toIso8601String(),
        'location': 'مستشفى',
      });
      final appt = (await v48.query('appointments')).first;
      expect(appt['location'], 'مستشفى');
      await v48.close();
    });

    test('VaccinationsRepo: حفظ + جرعة قربت (dueSoon) + daysLeft', () async {
      final repo = VaccinationsRepo();
      final soon = DateTime.now().add(const Duration(days: 10));
      await repo.save(Vaccination(
        name: 'إنفلونزا',
        nextDue:
            '${soon.year}-${soon.month.toString().padLeft(2, '0')}-${soon.day.toString().padLeft(2, '0')}',
        createdAt: DateTime.now().toIso8601String(),
      ));
      await repo.save(Vaccination(
        name: 'قديم بدون جرعة جاية',
        createdAt: DateTime.now().toIso8601String(),
      ));
      final all = await repo.all();
      expect(all.length, 2);
      // اللى ليها جرعة جاية بتطلع الأول.
      expect(all.first.name, 'إنفلونزا');
      final due = await repo.dueSoon(days: 30);
      expect(due.length, 1);
      expect(due.first.daysLeft, inInclusiveRange(9, 10));
    });
  });

  group('خطة سداد الديون (كرة الثلج)', () {
    test('بترتّب اللى عليك من الأصغر للأكبر وتتجاهل اللى ليك', () async {
      final repo = DebtsRepo();
      final now = DateTime.now().toIso8601String();
      await repo.add(Debt(
          person: 'أحمد', amount: 500, direction: 'عليا', createdAt: now));
      await repo.add(Debt(
          person: 'سعيد', amount: 100, direction: 'عليا', createdAt: now));
      await repo.add(Debt(
          person: 'منى', amount: 300, direction: 'عليا', createdAt: now));
      // دين ليك (عند حد) — لازم يتستبعد من خطة السداد.
      await repo.add(Debt(
          person: 'خالد', amount: 50, direction: 'لى', createdAt: now));

      final plan = await repo.payoffPlan();
      expect(plan.map((d) => d.person).toList(), ['سعيد', 'منى', 'أحمد']);
      expect(plan.every((d) => d.direction == 'عليا'), isTrue);
      expect(plan.fold<double>(0, (s, d) => s + d.amount), 900);
    });
  });

  group('قوالب المواعيد', () {
    test('كل قالب نوعه ووقت تذكيره صالحين', () {
      for (final t in kApptTemplates) {
        expect(kApptCategories.contains(t.category), isTrue,
            reason: 'نوع القالب ${t.key} لازم يكون من الأنواع المعروفة');
        expect(remindOptions().containsKey(t.remind), isTrue,
            reason: 'وقت تذكير القالب ${t.key} لازم يكون من الخيارات');
        expect(t.title.trim().isNotEmpty, isTrue);
      }
      // فيه على الأقل قالب دكتور وشغل.
      final keys = kApptTemplates.map((t) => t.key).toSet();
      expect(keys.containsAll({'doctor', 'work'}), isTrue);
    });
  });

  group('تصدير كل البيانات CSV', () {
    test('بيبنى CSV لكل جدول فيه بيانات ويتخطى الفاضى وخزنة كلمات السر', () async {
      // نضيف بيانات فى جدولين + صف فى خزنة كلمات السر (لازم تتستبعد).
      await TasksRepo().save(Task(
          title: 'مهمة, فيها فاصلة',
          createdAt: DateTime.now().toIso8601String()));
      await BillsRepo().save(RecurringBill(
          name: 'كهربا', amount: 250, dayOfMonth: 10, category: 'مرافق'));
      await PasswordsRepo().save(PasswordEntry(
          label: 'إيميل',
          username: 'me',
          secret: 'sekrit',
          createdAt: DateTime.now().toIso8601String()));

      final csvs = await DataExport.buildCsvs();
      final names = csvs.map((c) => c.name).toSet();
      expect(names.contains('tasks'), isTrue);
      expect(names.contains('recurring_bills'), isTrue);
      // خزنة كلمات السر مستبعدة من التصدير الصريح.
      expect(names.contains('passwords'), isFalse);

      // أول سطر = أسماء الأعمدة؛ القيمة اللى فيها فاصلة تتحاط فى quotes.
      final tasksCsv = csvs.firstWhere((c) => c.name == 'tasks').csv;
      expect(tasksCsv.split('\r\n').first.contains('title'), isTrue);
      expect(tasksCsv.contains('"مهمة, فيها فاصلة"'), isTrue);
    });
  });

  group('الوضع الليلي المجدول', () {
    test('نافذة عادية (٢٢:٠٠ → ٠٦:٠٠) بتتعامل مع تجاوز منتصف الليل', () {
      // ١١م → غامق
      expect(AppState.isDarkWindow(23 * 60, '22:00', '06:00'), isTrue);
      // ٢ص → غامق (بعد منتصف الليل)
      expect(AppState.isDarkWindow(2 * 60, '22:00', '06:00'), isTrue);
      // ٦ص بالظبط → فاتح (النهاية غير شاملة)
      expect(AppState.isDarkWindow(6 * 60, '22:00', '06:00'), isFalse);
      // ٣ع → فاتح
      expect(AppState.isDarkWindow(15 * 60, '22:00', '06:00'), isFalse);
    });
    test('نافذة نهارية عادية (٠٩:٠٠ → ١٧:٠٠) بدون تجاوز', () {
      expect(AppState.isDarkWindow(12 * 60, '09:00', '17:00'), isTrue);
      expect(AppState.isDarkWindow(8 * 60, '09:00', '17:00'), isFalse);
      expect(AppState.isDarkWindow(20 * 60, '09:00', '17:00'), isFalse);
    });
  });
}
