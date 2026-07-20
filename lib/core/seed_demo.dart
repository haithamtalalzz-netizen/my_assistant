import '../data/appointments_repo.dart';
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

  return n;
}
