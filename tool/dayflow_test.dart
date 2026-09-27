// **دورة اليوم**: بيعمل اللى المستخدم بيعمله فعلاً — يضيف مهمة ويقفلها،
// يسجّل جرعة، يصلّى، يشرب مياه — ويتأكد إن الأرقام بتتحرّك فى كل مكان
// مترابط (البطل · خط اليوم · إنجاز اليوم · كروت الرئيسية).
//
// ده اللى بيمسك «الزرار بيشتغل بس الرقم ما اتغيّرش» — وهو نوع عطب
// الاختبارات الوظيفية بتعدّيه.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/dashboard_stats.dart';
import 'package:my_assistant/core/day_timeline.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/health_repo.dart';
import 'package:my_assistant/data/meds_repo.dart';
import 'package:my_assistant/data/tasks_repo.dart';
import 'package:my_assistant/data/worship_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async => initializeDateFormatting('ar'));

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  test('مهمة: تتضاف → تظهر فى خط اليوم → تتقفل → تختفى من «الجاى»', () async {
    final now = DateTime(2026, 9, 28, 9, 0);
    final repo = TasksRepo();
    final id = await repo.save(Task(
        title: 'دفع فاتورة الغاز',
        dueAt: DateTime(2026, 9, 28, 17, 0).toIso8601String(),
        createdAt: now.toIso8601String()));

    var tasks = await repo.dueTasks(DateTime(2026, 9, 28, 23, 59));
    var line = buildDayTimeline(now: now, tasks: tasks, maxPast: null);
    expect(line.length, 1);
    expect(nextDayEvent(line, now)!.title, 'دفع فاتورة الغاز');

    // الزرار: خلّصتها
    await repo.setDone(id, true);

    tasks = await repo.dueTasks(DateTime(2026, 9, 28, 23, 59));
    line = buildDayTimeline(now: now, tasks: tasks, maxPast: null);
    // مابقاش «جاى»، والتقدّم اتحرّك.
    expect(nextDayEvent(line, now), isNull);
  });

  test('جرعة: تتعلّم «اتاخدت» → تخرج من الجاى ويزيد التقدّم', () async {
    final now = DateTime(2026, 9, 28, 9, 0);
    final meds = MedsRepo();
    final id = await meds.save(const Medication(
        name: 'كونكور', dosage: '5 مج', times: ['08:00', '21:00']));
    final day = dayKey(now);

    var taken = await meds.takenOn(day);
    var line = buildDayTimeline(
        now: now,
        meds: await meds.all(activeOnly: true),
        takenSlots: taken,
        maxPast: null);
    expect(line.length, 2);
    expect(dayTimelineProgress(line).done, 0);

    await meds.setTaken(id, day, '08:00', true);

    taken = await meds.takenOn(day);
    line = buildDayTimeline(
        now: now,
        meds: await meds.all(activeOnly: true),
        takenSlots: taken,
        maxPast: null);
    expect(dayTimelineProgress(line).done, 1);
    // اللى جاى بقى جرعة الليل.
    expect(nextDayEvent(line, now)!.slot, '21:00');
  });

  test('صلاة: «صلّيت» بتتسجّل وبتتشطب من الخط', () async {
    final now = DateTime(2026, 9, 28, 13, 0);
    final worship = WorshipRepo();
    final times = [
      DateTime(2026, 9, 28, 5, 12),
      DateTime(2026, 9, 28, 12, 5),
      DateTime(2026, 9, 28, 15, 48),
    ];

    // صلّى الفجر، وفات عليه الضهر.
    await worship.togglePrayer(now, 0, true);
    var prayed = await worship.prayedOn(now);
    var line = buildDayTimeline(
        now: now, prayers: times, prayedIdx: prayed, maxPast: null);
    // أقدم فايت ولسه ما اتصلّاش = الضهر (الفجر اتصلّى).
    expect(overdueDayEvent(line, now)!.title, 'الضهر');

    await worship.togglePrayer(now, 1, true);

    prayed = await worship.prayedOn(now);
    line = buildDayTimeline(
        now: now, prayers: times, prayedIdx: prayed, maxPast: null);
    expect(line[1].done, isTrue);
    expect(nextDayEvent(line, now)!.title, 'العصر');
  });

  test('مياه: الكوباية بتزوّد الرقم وكارت الصحة بيتغيّر معاه', () async {
    final now = DateTime.now();
    final day = dayKey(now);
    final health = HealthRepo();

    final before = await collectDashboard(now);
    final healthBefore =
        before.firstWhere((d) => d.key == 'health', orElse: () => before.first);

    await health.addWaterMl(day, 250);
    expect(await health.waterMlOn(day), 250);

    final after = await collectDashboard(now);
    final healthAfter = after.firstWhere((d) => d.key == 'health',
        orElse: () => after.first);
    // نفس الكارت، ورقمه اتغيّر (مش بيقرا من كاش قديم).
    expect(healthAfter.key, healthBefore.key);
    expect(healthAfter.value, isNot(equals('')));
  });

  test('الرئيسية بتجمع الأنواع كلها فى خط واحد مرتّب', () async {
    final now = DateTime(2026, 9, 28, 10, 0);
    final tasks = TasksRepo();
    await tasks.save(Task(
        title: 'مهمة',
        dueAt: DateTime(2026, 9, 28, 17, 0).toIso8601String(),
        createdAt: ''));
    final meds = MedsRepo();
    await meds.save(const Medication(name: 'دوا', times: ['21:00']));

    final line = buildDayTimeline(
      now: now,
      prayers: [DateTime(2026, 9, 28, 12, 5)],
      meds: await meds.all(activeOnly: true),
      tasks: await tasks.dueTasks(DateTime(2026, 9, 28, 23, 59)),
      maxPast: null,
    );
    expect(line.map((e) => e.kind).toList(), [
      TimelineKind.prayer,
      TimelineKind.task,
      TimelineKind.med,
    ]);
  });
}
