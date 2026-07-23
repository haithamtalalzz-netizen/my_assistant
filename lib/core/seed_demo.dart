import '../data/appointments_repo.dart';
import '../data/courses_repo.dart';
import '../data/docs_repo.dart';
import '../data/goals_repo.dart';
import '../data/gym_repo.dart';
import '../data/lab_results_repo.dart';
import '../data/pets_repo.dart';
import '../data/quit_repo.dart';
import '../data/reading_repo.dart';
import '../data/subscriptions_repo.dart';
import '../data/symptoms_repo.dart';
import '../data/tasks_repo.dart';
import '../data/vaccinations_repo.dart';
import '../data/wardrobe_repo.dart';
import '../data/wishlist_repo.dart';
import '../data/worship_repo.dart';
import 'db.dart';
import '../data/bills_repo.dart';
import '../data/body_progress_repo.dart';
import '../data/challenges_repo.dart';
import '../data/debts_repo.dart';
import '../data/diaries_repo.dart';
import '../data/gameya_repo.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/income_repo.dart';
import '../data/inbox_repo.dart';
import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/medical_repo.dart';
import '../data/meds_repo.dart';
import '../data/money_repo.dart';
import '../data/occasions_repo.dart';
import '../data/pharmacy_repo.dart';
import '../data/plants_repo.dart';
import '../data/recipes_repo.dart';
import '../data/relatives_repo.dart';
import '../data/savings_repo.dart';
import '../data/wallets_repo.dart';
import '../data/workout_repo.dart';
import '../models/models.dart';
import 'ar.dart';

/// يملأ التطبيق ببيانات وهمية لتجربة كل البنود. بيرجّع عدد العناصر المضافة.
/// (بيضيف من غير ما يمسح — لو اتضغط مرتين هيتضاعف؛ للتجربة بس.)
Future<int> seedDemoData() async {
  final now = DateTime.now();
  String d([int back = 0]) => dayKey(now.subtract(Duration(days: back)));
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  var n = 0;
  Future<void> add(Future<dynamic> Function() f) async {
    await f();
    n++;
  }

  // ---- المحافظ ----
  await add(() => WalletsRepo()
      .save(const Wallet(name: 'كاش', type: 'cash', openingBalance: 1500)));
  await add(() => WalletsRepo()
      .save(const Wallet(name: 'بنك مصر', type: 'bank', openingBalance: 12000)));
  await add(() => WalletsRepo().save(
      const Wallet(name: 'فودافون كاش', type: 'mobile', openingBalance: 300)));

  // ---- المصروفات (على أيام مختلفة للرسوم) ----
  await add(() => MoneyRepo().add(
      Expense(amount: 75, category: kExpenseCategories.first, note: 'قهوة', day: d())));
  await add(() => MoneyRepo().add(Expense(
      amount: 220, category: kExpenseCategories.first, note: 'سوبر ماركت', day: d(1))));
  await add(() => MoneyRepo().add(Expense(
      amount: 140, category: kExpenseCategories.last, note: 'بنزين', day: d(2))));
  await add(() => MoneyRepo().add(Expense(
      amount: 60, category: kExpenseCategories.first, note: 'مواصلات', day: d(3))));

  // ---- الدخل ----
  await add(() => IncomeRepo().add(Income(
      amount: 9000, source: kIncomeSources.first, note: 'مرتب الشهر', day: d(4))));
  await add(() => IncomeRepo().add(
      Income(amount: 800, source: kIncomeSources.last, note: 'شغل جانبي', day: d(1))));

  // ---- الديون ----
  await add(() => DebtsRepo().add(Debt(
      person: 'أحمد',
      amount: 500,
      direction: 'لى',
      note: 'سلفة',
      createdAt: now.toIso8601String())));
  await add(() => DebtsRepo().add(Debt(
      person: 'محل البقالة',
      amount: 120,
      direction: 'عليا',
      note: 'آجل',
      createdAt: now.toIso8601String())));

  // ---- فواتير دورية ----
  await add(() => BillsRepo()
      .save(const RecurringBill(name: 'الكهرباء', amount: 250, dayOfMonth: 10)));
  await add(() => BillsRepo()
      .save(const RecurringBill(name: 'الإنترنت', amount: 300, dayOfMonth: 5)));

  // ---- الادخار ----
  await add(() => SavingsRepo().addGoal(SavingsGoal(
      name: 'رحلة الصيف',
      target: 20000,
      saved: 6000,
      createdAt: now.toIso8601String())));

  // ---- الجمعية ----
  await add(() => GameyaRepo().save(Gameya(
      name: 'جمعية الشغل',
      amount: 1000,
      dayOfMonth: 1,
      totalMonths: 10,
      myTurn: 4,
      startMonth: month)));

  // ---- المواعيد (النهارده + قادم + متكرر) ----
  await add(() => AppointmentsRepo().save(Appointment(
      title: 'دكتور أسنان',
      category: 'صحة',
      when: DateTime(now.year, now.month, now.day, now.hour + 2))));
  await add(() => AppointmentsRepo().save(Appointment(
      title: 'اجتماع الشغل',
      category: 'شغل',
      when: now.add(const Duration(days: 2, hours: 3)))));
  await add(() => AppointmentsRepo().save(Appointment(
      title: 'صلة رحم — زيارة العيلة',
      category: 'عيلة',
      when: now.add(const Duration(days: 7)),
      repeat: 'weekly')));

  // ---- الأدوية ----
  await add(() => MedsRepo().save(const Medication(
      name: 'فيتامين د', dosage: 'حبة', times: ['08:00'])));
  await add(() => MedsRepo().save(const Medication(
      name: 'مضاد حيوي', dosage: 'قرص', times: ['08:00', '20:00'])));

  // ---- العادات (+ علّم بعضها) ----
  final h1 = await HabitsRepo().add('المشي ٣٠ دقيقة');
  final h2 = await HabitsRepo().add('قراءة ورد القرآن');
  await HabitsRepo().add('شرب ٨ كوبايات مياه');
  n += 3;
  await HabitsRepo().toggle(h1, d());
  await HabitsRepo().toggle(h2, d());

  // ---- الوجبات ----
  await add(() => MealsRepo().add(Meal(
      day: d(), slot: kMealSlots.first, description: 'فول وبيض', calories: 450)));
  await add(() => MealsRepo().add(Meal(
      day: d(), slot: kMealSlots[1], description: 'فراخ ورز', calories: 700)));

  // ---- خطة التمرين ----
  await add(() => WorkoutRepo().savePlan(const {
        1: 'صدر وترايسبس',
        3: 'ظهر وبايسبس',
        5: 'رجل وكتف',
      }));

  // ---- المناسبات ----
  await add(() => OccasionsRepo().save(Occasion(
      title: 'عيد ميلاد',
      person: 'أخويا',
      month: now.month,
      day: (now.day % 28) + 1)));
  await add(() => OccasionsRepo()
      .save(const Occasion(title: 'ذكرى الجواز', person: '', month: 6, day: 12)));

  // ---- القياسات ----
  await add(() => MeasurementsRepo()
      .add(Measurement(day: d(), type: 'وزن', value: 82, unit: 'كجم')));
  await add(() => MeasurementsRepo().add(
      Measurement(day: d(1), type: 'ضغط', value: 120, value2: 80, unit: 'ملم')));
  await add(() => MeasurementsRepo()
      .add(Measurement(day: d(2), type: 'سكر', value: 105, unit: 'مجم')));

  // ---- خطوات + نوم + مياه ----
  for (var k = 0; k < 6; k++) {
    await MeasurementsRepo().upsertSteps(d(k), 4000 + k * 900);
    await HealthRepo().setSleep(d(k), 6.5 + (k % 3));
    n += 2;
  }
  await add(() => HealthRepo().addWater(d(), 5));

  // ---- الملف الطبي ----
  await add(() => MedicalRepo().save(MedicalRecord(
      type: kMedicalTypes.first,
      day: d(10),
      title: 'كشف باطنة',
      provider: 'د. محمد',
      cost: 300)));

  // ---- الصيدلية ----
  await add(() => PharmacyRepo().save(PharmacyItem(
      name: 'بانادول', quantity: 2, expiry: d(-120), notes: 'خزانة الحمام')));
  await add(() => PharmacyRepo()
      .save(PharmacyItem(name: 'فوار', quantity: 5, expiry: d(-15))));

  // ---- نباتات (واحدة مستحقة) ----
  await add(() => PlantsRepo().save(Plant(
      name: 'الفل', location: 'بلكونة', waterIntervalDays: 3, lastWatered: d(5))));
  await add(() => PlantsRepo().save(Plant(
      name: 'صبار', location: 'الصالة', waterIntervalDays: 10, lastWatered: d(1))));

  // ---- صلة الرحم (واحد مستحق) ----
  await add(() => RelativesRepo().save(
      Relative(name: 'خالتي', phone: '01000000000', intervalDays: 14, lastContacted: d(20))));
  await add(() => RelativesRepo().save(
      Relative(name: 'عمي', phone: '01111111111', intervalDays: 30, lastContacted: d(3))));

  // ---- صيانة البيت (مستحقة) ----
  await add(() => HomeMaintenanceRepo().save(const HomeMaintenance(
      name: 'فلتر المياه', intervalMonths: 6, lastDone: '2025-01-01')));

  // ---- التقدّم البدني ----
  await add(() => BodyProgressRepo()
      .add(BodyProgress(day: d(7), weight: 83, waist: 92)));

  // ---- يوميات + وصفة + تحديات + وارد ----
  await add(() => DiariesRepo().add(Diary(
      day: d(), text: 'يوم كويس، خلّصت شغل كتير.', createdAt: now.toIso8601String())));
  await add(() => RecipesRepo().save(const Recipe(
      name: 'كشري', ingredients: 'رز\nعدس\nمكرونة', steps: 'اسلق وقلّب')));
  await add(() => ChallengesRepo().add(
      Challenge(name: 'تحدي المشي', startDate: d(3), days: 30)));
  await add(() => InboxRepo().add('أفتكر أجدد رخصة العربية'));

  // ═══════════ العمق: شهرين سجلات يومية (للرسوم والتحليلات) ═══════════
  // مصروفات + وجبات + مياه + خطوات + نوم + مزاج + صلاة + وزن على ٦٠ يوم —
  // من غير ده الرسوم البيانية والـinsights بيبانوا فاضيين مهما البنود اتملت.
  final db = await AppDb.instance;
  const foods = ['فول وطعمية', 'فراخ ورز', 'مكرونة بشاميل', 'سمك مشوى',
    'كشرى', 'شاورما', 'ملوخية', 'محشى'];
  const moodNotes = ['يوم هادى', 'شغل كتير', 'قعدة حلوة مع العيلة', ''];
  for (var k = 0; k < 60; k++) {
    final day = d(k);
    final date = now.subtract(Duration(days: k));
    // مصروف يومى متغيّر + وجبتين.
    await MoneyRepo().add(Expense(
        amount: 40.0 + (k * 37) % 260,
        category: kExpenseCategories[k % kExpenseCategories.length],
        note: '',
        day: day));
    await MealsRepo().add(Meal(
        day: day, slot: kMealSlots.first,
        description: foods[k % foods.length], calories: 350.0 + (k % 5) * 60));
    await MealsRepo().add(Meal(
        day: day, slot: kMealSlots[1],
        description: foods[(k + 3) % foods.length],
        calories: 550.0 + (k % 4) * 90));
    // صحة يومية.
    await HealthRepo().addWater(day, 4 + k % 5);
    await MeasurementsRepo().upsertSteps(day, 3500 + (k * 731) % 6500);
    await HealthRepo().setSleep(day, 5.5 + (k % 4) * 0.8);
    // مزاج (١..٥) — مفيش API لغير النهارده فبنكتب مباشرة.
    await db.insert('mood_logs', {
      'day': day,
      'score': 2 + (k * 7) % 4,
      'note': moodNotes[k % moodNotes.length],
      'created_at': date.toIso8601String(),
    });
    // صلاة: أيام كاملة وأيام ناقصة (عشان السلاسل والإحصاءات تبان حقيقية).
    final prayed = k % 7 == 3 ? 3 : 5;
    for (var pr = 0; pr < prayed; pr++) {
      await WorshipRepo().togglePrayer(date, pr, true);
    }
    // وزن كل ٣ أيام — نازل ببطء عشان الترند يبان.
    if (k % 3 == 0) {
      await MeasurementsRepo().add(Measurement(
          day: day, type: 'وزن', value: 84 - k * 0.05, unit: 'كجم'));
    }
    n += 8;
  }

  // ═══════════ الاتساع: الأقسام اللى مكانش ليها بيانات ═══════════
  final iso = now.toIso8601String();

  // ---- المهام (مشروع + مهام بمواعيد وحالات مختلفة) ----
  final projectId = await TasksRepo().saveProject(Project(
      name: 'تجهيز الشقة', color: 0xFF7C5CFF, createdAt: iso));
  n++;
  final t1 = await TasksRepo().save(Task(
      title: 'دهان الأوضة', projectId: projectId, priority: 2,
      dueAt: now.add(const Duration(days: 3)).toIso8601String(),
      createdAt: iso));
  await TasksRepo().addSubtask(t1, 'شراء الدهانات');
  await TasksRepo().addSubtask(t1, 'تغطية العفش');
  await TasksRepo().save(Task(
      title: 'دفع فاتورة الغاز',
      dueAt: now.toIso8601String(), createdAt: iso));
  final t3 = await TasksRepo().save(Task(title: 'تجديد الباقة', createdAt: iso));
  await TasksRepo().setDone(t3, true);
  n += 5;

  // ---- ملابسى ----
  const clothes = [
    ('قميص أبيض', 'قمصان', 'أبيض', 'summer', 'formal'),
    ('بنطلون جينز', 'بناطيل', 'أزرق', 'all', 'casual'),
    ('جاكيت شتوى', 'جواكت', 'أسود', 'winter', 'casual'),
    ('تيشيرت رمادى', 'تيشيرتات', 'رمادى', 'summer', 'casual'),
    ('بدلة', 'بدل', 'كحلى', 'all', 'formal'),
    ('بلوفر صوف', 'بلوفرات', 'بيج', 'winter', 'casual'),
  ];
  for (final (i, c) in clothes.indexed) {
    await WardrobeRepo().save(ClothingItem(
        name: c.$1, category: c.$2, color: c.$3, season: c.$4,
        formality: c.$5,
        lastWorn: i < 3 ? d(i * 4) : null,
        favorite: i == 0,
        needsWash: i == 3));
    n++;
  }

  // ---- تطوّرى: قراءة + كورسات + أهداف ----
  await ReadingRepo().save(Book(
      title: 'العادات الذرية', author: 'جيمس كلير', totalPages: 320,
      currentPage: 145, status: 'reading', createdAt: iso));
  await ReadingRepo().save(Book(
      title: 'قوة التفكير', author: '', totalPages: 200,
      currentPage: 200, status: 'done', createdAt: iso));
  await ReadingRepo().save(Book(
      title: 'الأب الغنى والأب الفقير', author: 'كيوساكى', totalPages: 260,
      currentPage: 0, status: 'todo', createdAt: iso));
  await CoursesRepo().save(Course(
      title: 'كورس Excel متقدم', provider: 'يوتيوب', totalUnits: 20,
      doneUnits: 12, status: 'active', createdAt: iso));
  await CoursesRepo().save(Course(
      title: 'إنجليزى محادثة', provider: 'تطبيق', totalUnits: 30,
      doneUnits: 30, status: 'done', createdAt: iso));
  final g1 = await GoalsRepo().save(Goal(
      title: 'أخس ٥ كيلو', notes: 'قبل الصيف',
      targetDate: dayKey(now.add(const Duration(days: 90))), createdAt: iso));
  await GoalsRepo().addMilestone(g1, 'أول كيلو');
  await GoalsRepo().addMilestone(g1, 'نص المشوار');
  await GoalsRepo().save(Goal(title: 'أحفظ جزء عمّ', createdAt: iso));
  n += 9;

  // ---- الاشتراكات + قائمة الأمنيات ----
  await SubscriptionsRepo().save(Subscription(
      name: 'نتفليكس', amount: 200, dayOfMonth: 3, createdAt: iso));
  await SubscriptionsRepo().save(Subscription(
      name: 'سبوتيفاى', amount: 60, dayOfMonth: 15, createdAt: iso));
  await SubscriptionsRepo().save(Subscription(
      name: 'جيم', amount: 500, dayOfMonth: 1, createdAt: iso));
  await WishlistRepo().save(WishItem(
      name: 'سماعة بلوتوث', price: 1200, priority: 1, createdAt: iso));
  await WishlistRepo().save(WishItem(
      name: 'كرسى مكتب', price: 3500, priority: 2, createdAt: iso));
  n += 5;

  // ---- المستندات (واحد قرّب يخلص) ----
  await DocsRepo().save(DocItem(
      title: 'رخصة القيادة', expiry: d(-25), remindDays: 30));
  await DocsRepo().save(DocItem(
      title: 'جواز السفر', expiry: dayKey(now.add(const Duration(days: 400)))));
  await DocsRepo().save(const DocItem(title: 'البطاقة الشخصية'));
  n += 3;

  // ---- التحاليل + التطعيمات ----
  await LabResultsRepo().save(LabResult(
      name: 'سكر صايم', value: 98, unit: 'mg/dL', date: d(10),
      refLow: '70', refHigh: '100', createdAt: iso));
  await LabResultsRepo().save(LabResult(
      name: 'فيتامين د', value: 18, unit: 'ng/mL', date: d(10),
      refLow: '30', refHigh: '100', notes: 'ناقص — محتاج مكمل',
      createdAt: iso));
  await LabResultsRepo().save(LabResult(
      name: 'هيموجلوبين', value: 14.2, unit: 'g/dL', date: d(40),
      refLow: '13', refHigh: '17', createdAt: iso));
  await VaccinationsRepo().save(Vaccination(
      name: 'إنفلونزا', person: 'أنا', date: d(90),
      nextDue: dayKey(now.add(const Duration(days: 20))), createdAt: iso));
  n += 4;

  // ---- الجيم (حصص وتمارين) ----
  for (var k = 0; k < 8; k++) {
    final sid = await GymRepo().addSession(GymSession(
        day: d(k * 3), program: k % 2 == 0 ? 'صدر وترايسبس' : 'ظهر وبايسبس',
        durationMin: 45 + (k % 3) * 15));
    await GymRepo().addSet(GymSet(
        sessionId: sid, exercise: k % 2 == 0 ? 'بنش برس' : 'عقلة',
        setIndex: 1, reps: 10, weight: 40 + k * 2.5));
    n += 2;
  }

  // ---- الإقلاع + الأعراض + الحيوانات ----
  await QuitRepo().add(QuitCounter(
      name: 'السجائر', startDate: d(45), dailySaving: 60));
  await SymptomsRepo().save(SymptomLog(
      day: d(2), symptom: 'صداع', severity: 3, note: 'بعد يوم طويل',
      createdAt: iso));
  final petId = await PetsRepo().savePet(Pet(
      name: 'مشمش', species: 'قطة', createdAt: iso));
  await PetsRepo().saveEvent(PetEvent(
      petId: petId, type: 'تطعيم', day: d(30),
      nextDue: dayKey(now.add(const Duration(days: 60))),
      note: 'التطعيم السنوى', createdAt: iso));
  n += 4;

  return n;
}
