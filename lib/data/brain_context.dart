import '../core/ar.dart';
import 'appointments_repo.dart';
import 'docs_repo.dart';
import 'gym_repo.dart';
import 'habits_repo.dart';
import 'income_repo.dart';
import 'insights_repo.dart';
import 'measurements_repo.dart';
import 'medical_repo.dart';
import 'meds_repo.dart';
import 'money_repo.dart';
import 'savings_repo.dart';
import 'settings_repo.dart';

/// بيبني لقطة نصية مضغوطة من بيانات المستخدم عشان تتبعت مع سؤال المحادثة.
/// بيحترم إعداد الخصوصية: لو مشاركة الصحة متقفلة، مفيش أدوية ولا قياسات
/// ولا نوم في السياق.
Future<String> buildBrainContext() async {
  final settings = SettingsRepo();
  final now = DateTime.now();
  final buf = StringBuffer();

  final name = await settings.userName();
  buf.writeln('التاريخ: ${arFullDate(now)}');
  if (name.isNotEmpty) buf.writeln('اسم المستخدم: $name');

  // مواعيد الأسبوع الجاي.
  final appts = await AppointmentsRepo().all();
  final weekAhead = now.add(const Duration(days: 7));
  final upcoming = [
    for (final a in appts)
      if (!a.done && a.when.isAfter(now) && a.when.isBefore(weekAhead)) a
  ];
  if (upcoming.isNotEmpty) {
    buf.writeln('مواعيد الأسبوع الجاي:');
    for (final a in upcoming.take(10)) {
      buf.writeln('- ${a.title} (${a.category}) ${arShortDate(a.when)} ${arTime(a.when)}');
    }
  }
  final overdue = [
    for (final a in appts)
      if (!a.done && a.when.isBefore(dateOnly(now))) a.title
  ];
  if (overdue.isNotEmpty) {
    buf.writeln('مواعيد فايتة من غير ما تتعمل: ${overdue.take(5).join('، ')}');
  }

  // الفلوس.
  final money = MoneyRepo();
  final total = await money.totalForMonth(now.year, now.month);
  final byCat = await money.byCategory(now.year, now.month);
  final budget = await settings.monthlyBudget();
  buf.writeln('مصاريف الشهر: ${egp(total)}'
      '${budget > 0 ? ' من ميزانية ${egp(budget)}' : ''}');
  if (byCat.isNotEmpty) {
    buf.writeln('حسب الفئة: ${byCat.entries.map((e) => '${e.key} ${egp(e.value)}').join('، ')}');
  }
  // الدخل والصافي.
  final incomeTotal =
      await IncomeRepo().totalForMonth(now.year, now.month);
  if (incomeTotal > 0) {
    buf.writeln('دخل الشهر: ${egp(incomeTotal)} — الصافي (دخل ناقص مصروف): '
        '${egp(incomeTotal - total)}');
  }
  // أهداف الادخار.
  final goals = await SavingsRepo().all();
  if (goals.isNotEmpty) {
    buf.writeln('أهداف الادخار: ${goals.map((g) => '${g.name} '
        '(${egp(g.saved)} من ${egp(g.target)})').join('، ')}');
  }

  // العادات وسلاسلها.
  final habitsRepo = HabitsRepo();
  final habits = await habitsRepo.active();
  if (habits.isNotEmpty) {
    final parts = <String>[];
    for (final h in habits) {
      final streak = computeStreak(await habitsRepo.daysFor(h.id!), now);
      parts.add('${h.name} (سلسلة ${arNum(streak)})');
    }
    buf.writeln('العادات: ${parts.join('، ')}');
  }

  // الصحة — حسب إعداد الخصوصية.
  final shareHealth = await settings.get('gemini_send_health') != '0';
  if (shareHealth) {
    final meds = await MedsRepo().all(activeOnly: true);
    if (meds.isNotEmpty) {
      buf.writeln('الأدوية الحالية: ${meds.map((m) => '${m.name} (${m.times.length} جرعات/يوم)').join('، ')}');
    }
    final data = await InsightsRepo().assemble(now: now);
    final recentSleep = [
      for (final d in data.days.reversed.take(7))
        if (d.sleep != null) d.sleep!
    ];
    if (recentSleep.isNotEmpty) {
      final avg = recentSleep.reduce((a, b) => a + b) / recentSleep.length;
      buf.writeln('متوسط النوم آخر أسبوع: ${arNum(avg.toStringAsFixed(1))} ساعة');
    }
    final measurements = await MeasurementsRepo().recent(limit: 6);
    if (measurements.isNotEmpty) {
      buf.writeln('آخر قياسات: ${measurements.map((m) => '${m.type} ${m.display()} (${m.day})').join('، ')}');
    }
    // الجيم: الوضع الحالي وأعلى أوزان.
    final gym = GymRepo();
    final program = await gym.currentProgram();
    if (program.isNotEmpty) {
      buf.writeln('وضع التمرين الحالي: ${gymProgramLabel(program)}');
    }
    final prs = await gym.personalRecords();
    if (prs.isNotEmpty) {
      buf.writeln('أعلى أوزان: ${prs.take(5).map((p) => '${p.exercise} '
          '${arNum(p.weight % 1 == 0 ? p.weight.toInt() : p.weight)}كجم').join('، ')}');
    }
    // هدف السعرات.
    final calGoal = await settings.calorieGoal();
    if (calGoal > 0) {
      buf.writeln('هدف السعرات اليومي: ${arNum(calGoal)}');
    }
    // آخر سجلات طبية (آخر ٩٠ يوم).
    final medical = await MedicalRepo()
        .since(dayKey(now.subtract(const Duration(days: 90))));
    if (medical.isNotEmpty) {
      buf.writeln('سجلات طبية أخيرة: ${medical.take(5).map((r) =>
          '${medicalTypeLabel(r.type)} ${r.title} (${r.day})').join('، ')}');
    }
  }

  // مستندات قربت تخلص.
  final expiring = await DocsRepo().expiringSoon();
  if (expiring.isNotEmpty) {
    buf.writeln('مستندات قربت تنتهي: ${expiring.map((d) => d.title).join('، ')}');
  }

  return buf.toString();
}

const String kBrainSystemPrompt = '''
انت «المدير» — مساعد شخصي مصري ودود جوه تطبيق My Assistant.
بترد بالعامية المصرية، مختصر ومباشر وعملي.
هيوصلك سياق ببيانات المستخدم الحقيقية — استخدمه في إجاباتك بالأرقام.
لو سُئلت عن حاجة طبية: انصح بشكل عام ووجّه للدكتور، متشخصش.
لو مفيش بيانات كفاية للإجابة قول كده بصراحة.
''';
