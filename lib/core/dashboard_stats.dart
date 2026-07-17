import 'log.dart';

import '../data/debts_repo.dart';
import '../data/docs_repo.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/lab_results_repo.dart';
import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/money_repo.dart';
import '../data/plants_repo.dart';
import '../data/reading_repo.dart';
import '../data/renewals_repo.dart';
import '../data/settings_repo.dart';
import '../data/subscriptions_repo.dart';
import '../data/tasks_repo.dart';
import '../data/vaccinations_repo.dart';
import '../data/wallets_repo.dart';
import '../data/worship_repo.dart';
import 'ar.dart';
import 'l10n.dart';

/// كارت واحد فى اللوحة الشاملة — بيانات بس (مفيش ودجت هنا عشان يفضل قابل
/// للاختبار). الشاشة هى اللى بتربط المفتاح بالأيقونة واللون والوجهة.
class DashStat {
  /// مفتاح ثابت — الشاشة بتحوّله لأيقونة/لون/شاشة.
  final String key;
  final String title;

  /// الرقم الكبير.
  final String value;

  /// سطر صغير تحت الرقم (سياق).
  final String sub;

  const DashStat({
    required this.key,
    required this.title,
    required this.value,
    this.sub = '',
  });
}

String _egp(double v) => egp(v);

/// بيجمع أرقام كل أقسام التطبيق للوحة الشاملة — كله محلى من قاعدة البيانات.
/// أى قسم بيفشل بيتخطى (مايكسرش اللوحة كلها).
Future<List<DashStat>> collectDashboard([DateTime? at]) async {
  final now = at ?? DateTime.now();
  final day = dayKey(now);
  final out = <DashStat>[];

  Future<void> add(String key, Future<DashStat?> Function() build) async {
    try {
      final s = await build();
      if (s != null) out.add(s);
    } on Exception catch (e) {
      logError('فشل كارت اللوحة «$key»', e);
    }
  }

  // ————— الفلوس —————
  await add('money', () async {
    final spent = await MoneyRepo().totalForMonth(now.year, now.month);
    final balance = await WalletsRepo().totalBalance();
    return DashStat(
      key: 'money',
      title: tr('الفلوس', 'Money'),
      value: _egp(spent),
      sub: tr('مصروف الشهر · الرصيد ${_egp(balance)}',
          'Spent this month · balance ${_egp(balance)}'),
    );
  });

  // ————— المهام —————
  await add('tasks', () async {
    final open = await TasksRepo().openCount();
    final due = (await TasksRepo().dueTasks(now)).length;
    return DashStat(
      key: 'tasks',
      title: tr('المهام', 'Tasks'),
      value: arNum(open),
      sub: due == 0
          ? tr('مفتوحة · مفيش مستحق', 'open · none due')
          : tr('مفتوحة · ${arNum(due)} مستحقة', 'open · ${arNum(due)} due'),
    );
  });

  // ————— العادات —————
  await add('habits', () async {
    final all = await HabitsRepo().active();
    if (all.isEmpty) return null;
    final done = (await HabitsRepo().doneOn(day)).length;
    return DashStat(
      key: 'habits',
      title: tr('العادات', 'Habits'),
      value: '${arNum(done)}/${arNum(all.length)}',
      sub: tr('اتعملت النهارده', 'done today'),
    );
  });

  // ————— الصلاة —————
  await add('prayer', () async {
    final prayed = (await WorshipRepo().prayedToday()).length;
    final streak = await WorshipRepo().fullDaysStreak();
    return DashStat(
      key: 'prayer',
      title: tr('الصلاة', 'Prayer'),
      value: '${arNum(prayed)}/٥',
      sub: streak > 0
          ? tr('🔥 سلسلة ${arNum(streak)} يوم', '🔥 ${arNum(streak)}-day streak')
          : tr('صلوات النهارده', 'prayers today'),
    );
  });

  // ————— الأكل —————
  await add('food', () async {
    final n = await MealsRepo().dayNutrients(day);
    if (n.kcal <= 0) return null;
    final goal = await SettingsRepo().calorieGoal();
    return DashStat(
      key: 'food',
      title: tr('الأكل', 'Food'),
      value: arNum(n.kcal.round()),
      sub: goal > 0
          ? tr('سعرة من ${arNum(goal)}', 'kcal of ${arNum(goal)}')
          : tr('سعرة النهارده', 'kcal today'),
    );
  });

  // ————— الصحة (مياه بالملى + آخر وزن) —————
  await add('health', () async {
    final ml = await HealthRepo().waterMlOn(day);
    final goalMl = await SettingsRepo().waterGoalMl();
    final weights = await MeasurementsRepo().recent(limit: 1, type: 'وزن');
    final w = weights.isEmpty ? null : weights.first.value;
    return DashStat(
      key: 'health',
      title: tr('الصحة', 'Health'),
      value: '${arNum(ml)}/${arNum(goalMl)}',
      sub: w == null
          ? tr('مل مياه النهارده', 'mL water today')
          : tr('مل مياه · الوزن ${arNum(w.toStringAsFixed(1))} كجم',
              'mL water · weight ${arNum(w.toStringAsFixed(1))} kg'),
    );
  });

  // ————— الديون —————
  await add('debts', () async {
    final (owedToMe, iOwe) = await DebtsRepo().totals();
    if (owedToMe == 0 && iOwe == 0) return null;
    final net = owedToMe - iOwe;
    return DashStat(
      key: 'debts',
      title: tr('الديون', 'Debts'),
      value: _egp(net.abs()),
      sub: net >= 0
          ? tr('صافى ليك', 'net owed to you')
          : tr('صافى عليك', 'net you owe'),
    );
  });

  // ————— الاشتراكات —————
  await add('subs', () async {
    final total = await SubscriptionsRepo().monthlyTotal();
    if (total <= 0) return null;
    return DashStat(
      key: 'subs',
      title: tr('الاشتراكات', 'Subscriptions'),
      value: _egp(total),
      sub: tr('شهرياً', 'per month'),
    );
  });

  // ————— القراءة —————
  await add('reading', () async {
    final finished = await ReadingRepo().finishedCount();
    if (finished <= 0) return null;
    return DashStat(
      key: 'reading',
      title: tr('القراءة', 'Reading'),
      value: arNum(finished),
      sub: tr('كتاب خلصته', 'books finished'),
    );
  });

  // ————— البيت (صيانة + نباتات) —————
  await add('home', () async {
    final maint = (await HomeMaintenanceRepo().due(now)).length;
    final plants = (await PlantsRepo().due(now)).length;
    final total = maint + plants;
    if (total == 0) return null;
    return DashStat(
      key: 'home',
      title: tr('البيت', 'Home'),
      value: arNum(total),
      sub: tr('صيانة ${arNum(maint)} · نباتات ${arNum(plants)}',
          '${arNum(maint)} maintenance · ${arNum(plants)} plants'),
    );
  });

  // ————— المستندات والتجديدات —————
  await add('docs', () async {
    final docs = (await DocsRepo().expiringSoon()).length;
    final ren = (await RenewalsRepo().dueSoon()).length;
    final total = docs + ren;
    if (total == 0) return null;
    return DashStat(
      key: 'docs',
      title: tr('المستندات', 'Documents'),
      value: arNum(total),
      sub: tr('قربت تنتهى', 'expiring soon'),
    );
  });

  // ————— التحاليل والتطعيمات —————
  await add('labs', () async {
    final out0 = await LabResultsRepo().outOfRangeCount();
    final vax = (await VaccinationsRepo().dueSoon()).length;
    if (out0 == 0 && vax == 0) return null;
    return DashStat(
      key: 'labs',
      title: tr('التحاليل', 'Labs'),
      value: arNum(out0),
      sub: vax > 0
          ? tr('خارج الطبيعى · ${arNum(vax)} تطعيم قرب',
              'out of range · ${arNum(vax)} vaccine due')
          : tr('خارج الطبيعى', 'out of range'),
    );
  });

  return out;
}
