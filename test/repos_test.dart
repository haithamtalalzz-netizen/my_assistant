import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/backup.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/day_planner.dart';
import 'package:my_assistant/core/insights.dart';
import 'package:my_assistant/core/ocr.dart';
import 'package:my_assistant/core/prayers.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/data/wallets_repo.dart';
import 'package:my_assistant/core/voice_parser.dart';
import 'package:my_assistant/data/appointments_repo.dart';
import 'package:my_assistant/data/day_log_repo.dart';
import 'package:my_assistant/data/docs_repo.dart';
import 'package:my_assistant/data/habits_repo.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/meds_repo.dart';
import 'package:my_assistant/data/money_repo.dart';
import 'package:my_assistant/core/streak_guard.dart';
import 'package:my_assistant/core/weather.dart';
import 'package:my_assistant/core/month_summary.dart';
import 'package:my_assistant/data/bills_repo.dart';
import 'package:my_assistant/data/debts_repo.dart';
import 'package:my_assistant/data/gameya_repo.dart';
import 'package:my_assistant/data/home_maintenance_repo.dart';
import 'package:my_assistant/data/inbox_repo.dart';
import 'package:my_assistant/data/meals_repo.dart';
import 'package:my_assistant/data/measurements_repo.dart';
import 'package:my_assistant/data/occasions_repo.dart';
import 'package:my_assistant/data/plants_repo.dart';
import 'package:my_assistant/data/search_repo.dart';
import 'package:my_assistant/data/settings_repo.dart';
import 'package:my_assistant/data/weekly_repo.dart';
import 'package:my_assistant/data/workout_repo.dart';
import 'package:my_assistant/models/models.dart';
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
      expect(await repo.waterGoal(), 8);
      expect(await repo.monthlyBudget(), 0);
      await repo.set('water_goal', '10');
      await repo.set('monthly_budget', '5000');
      expect(await repo.waterGoal(), 10);
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

    test('محافظة غير معروفة ترجع القاهرة', () {
      expect(governorateByName('مش موجودة').name, 'القاهرة');
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
}
