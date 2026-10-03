// «عملت إيه النهاردة» — الرقم اللى بيتعرض لازم يكون صادق.
//
// الحاجة اللى بتغلط فى صمت هنا: مدة اليوم جاية من **مصدرين** (نشاط
// حُرّ + جلسات جيم). لو قريت واحد بس، الشاشة هتقول رقم ناقص وهى واثقة —
// ودى أسوأ من إنها ماتقولش حاجة.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/activity_repo.dart';
import 'package:my_assistant/data/day_log.dart';
import 'package:my_assistant/data/gym_repo.dart';
import 'package:my_assistant/data/meals_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  final now = DateTime.now();
  final today = dayKey(now);

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  Future<void> walk(int minutes, {String? day, String type = 'walk'}) =>
      ActivityRepo().add(ActivitySession(
        day: day ?? today,
        type: type,
        distanceKm: 0,
        durationSec: minutes * 60,
        calories: 0,
        createdAt: now.toIso8601String(),
      ));

  group('رياضة اليوم', () {
    test('فاضية فى الأول', () async {
      final e = await DayLog.exerciseToday();
      expect(e.isEmpty, isTrue);
      expect(e.what, '');
    });

    test('بتجمع المصدرين: نشاط حُرّ + جيم', () async {
      await walk(30);
      await GymRepo().addSession(
          GymSession(day: today, program: 'Push', durationMin: 45));
      final e = await DayLog.exerciseToday();
      expect(e.minutes, 75, reason: 'لو قرا مصدر واحد هيقول ٣٠ أو ٤٥');
      expect(e.what, contains('مشى'));
      expect(e.what, contains('Push'));
    });

    test('نفس النوع مرتين بيتجمع فى سطر واحد', () async {
      await walk(20);
      await walk(10);
      final e = await DayLog.exerciseToday();
      expect(e.minutes, 30);
      expect(e.what, 'مشى 30 د');
    });

    test('نشاط إمبارح مابيتحسبش النهاردة', () async {
      final yesterday =
          dayKey(dateOnly(now).subtract(const Duration(days: 1)));
      await walk(60, day: yesterday);
      expect((await DayLog.exerciseToday()).isEmpty, isTrue);
    });

    test('جلسة جيم من غير برنامج بتتقال «جيم»', () async {
      await GymRepo()
          .addSession(GymSession(day: today, program: '', durationMin: 40));
      expect((await DayLog.exerciseToday()).what, 'جيم 40 د');
    });

    test('النوع الإنجليزى من متتبّع الـGPS بيتعرّب', () async {
      await walk(15, type: 'run');
      expect((await DayLog.exerciseToday()).what, 'جرى 15 د');
    });
  });

  group('الأزرار الجاهزة', () {
    test('فى الأول بتبقى الافتراضية', () async {
      final p = await DayLog.presets();
      expect(p, kDefaultExercisePresets);
    });

    test('بتتعلّم من اللى سجّلته', () async {
      // «مشى ٢٥» تلات مرات، و«جرى ١٠» مرة.
      for (var i = 0; i < 3; i++) {
        await walk(25);
      }
      await walk(10, type: 'run');
      final p = await DayLog.presets();
      expect(p.first, const ExercisePreset('مشى', 25));
      // الاسم بيتحسب — فمستحيل الافتراضى والمتعلَّم يتكتبوا بخطّين.
      expect(p.first.label, 'مشى 25 د');
      expect(p.length, 3, reason: 'الافتراضيات بتكمّل الناقص');
    });

    test('الافتراضى مابيتكرّرش مع اللى اتعلّمه', () async {
      for (var i = 0; i < 2; i++) {
        await walk(30);
      }
      final p = await DayLog.presets();
      expect(p.where((e) => e.type == 'مشى' && e.minutes == 30).length, 1);
    });
  });

  group('تسجيل وتراجع', () {
    test('دوسة بتسجّل، وتراجع بيشيلها', () async {
      const p = ExercisePreset('مشى', 30);
      final id = await DayLog.logExercise(p);
      expect((await DayLog.exerciseToday()).minutes, 30);

      await DayLog.undoExercise(id);
      expect((await DayLog.exerciseToday()).isEmpty, isTrue);
    });
  });

  group('أكل اليوم', () {
    Future<void> eat(String slot, String what, double cal, {String? day}) =>
        MealsRepo().add(Meal(
            day: day ?? today, slot: slot, description: what, calories: cal));

    test('بيجمع سعرات اليوم ويقول الخانات بالترتيب', () async {
      await eat('عشا', 'فراخ', 600);
      await eat('فطار', 'فول', 400);
      final m = await DayLog.mealsToday();
      expect(m.calories, 1000);
      // الترتيب الطبيعى للخانات، مش ترتيب التسجيل.
      expect(m.what, 'فطار · عشا');
    });

    test('الخانة المكرّرة بتتقال مرة', () async {
      await eat('سناك', 'تمر', 100);
      await eat('سناك', 'مكسرات', 200);
      expect((await DayLog.mealsToday()).what, 'سناك');
    });

    test('زرار الخانة بيكرّر آخر مرة أكلتها فيها', () async {
      final yesterday =
          dayKey(dateOnly(now).subtract(const Duration(days: 1)));
      await eat('فطار', 'فول وبيض', 450, day: yesterday);

      final id = await DayLog.repeatMeal('فطار');
      expect(id, isNotNull);

      final todayMeals = await MealsRepo().forDay(today);
      expect(todayMeals.single.description, 'فول وبيض');
      expect(todayMeals.single.calories, 450);

      await DayLog.undoMeal(id!);
      expect(await MealsRepo().forDay(today), isEmpty);
    });

    test('مفيش وجبة سابقة = مابيسجّلش حاجة من دماغه', () async {
      // الشاشة ساعتها بتفتح الورقة — المهم إنها ماتخترعش وجبة.
      expect(await DayLog.repeatMeal('غدا'), isNull);
      expect(await MealsRepo().forDay(today), isEmpty);
    });

    test('بيكرّر الأحدث مش الأقدم', () async {
      final d2 = dayKey(dateOnly(now).subtract(const Duration(days: 2)));
      final d1 = dayKey(dateOnly(now).subtract(const Duration(days: 1)));
      await eat('غدا', 'قديمة', 100, day: d2);
      await eat('غدا', 'الأحدث', 700, day: d1);
      await DayLog.repeatMeal('غدا');
      expect((await MealsRepo().forDay(today)).single.description, 'الأحدث');
    });
  });
}
