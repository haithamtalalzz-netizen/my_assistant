// أرقام بنود الهَبّات — «مافيش باب بيتفتح من غير ما يقول اللى وراه».
//
// القاعدة دى طلعت من «فلوسى»: الشاشة كانت قايمة أبواب صامتة، فكل دوسة
// كانت تجربة. لمّا كل زرار بقى بيقول رقمه بقيت تعرف من غير ما تفتح.
// الملف ده بيجمع الأرقام دى فى مكان واحد عشان:
//   · الشاشات تفضل شاشات — الاستعلام مايتكتبش جوّه الودجت.
//   · الأرقام تتختبر لوحدها (اختبار `hub_stats_test.dart`).
//
// 🔴 كل دالة هنا بترجّع null لو البند فاضى، عشان السطر يفضل ساكت بدل
// ما يقول «0» — الصفر بيتقرا كأنه حاجة اتحسبت، والفاضى مش نفس الحاجة.
import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/custom_rules.dart';
import '../core/db.dart';
import '../core/insights.dart';
import '../core/l10n.dart';
import '../screens/group_hub_screen.dart';
import '../models/models.dart';
import 'challenges_repo.dart';
import 'day_log_repo.dart';
import 'docs_repo.dart';
import 'inbox_repo.dart';
import 'insights_repo.dart';
import 'courses_repo.dart';
import 'habits_repo.dart';
import 'passwords_repo.dart';
import 'quit_repo.dart';
import 'reading_repo.dart';
import 'relatives_repo.dart';
import 'rules_repo.dart';
import 'weekly_repo.dart';

const _late = Color(0xFFEF4444);

/// كام يوم عدّى على تاريخ ISO — أو null لو التاريخ بايظ.
int? _daysSince(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? null : dateOnly(DateTime.now()).difference(dateOnly(d)).inDays;
}

// ————————————————— تطوّرى —————————————————

/// القراءة: الكتاب اللى بتقرا فيه دلوقتى + كام كتاب خلّصت.
Future<HubStat?> readingStat() async {
  final books = await ReadingRepo().all();
  if (books.isEmpty) return null;
  final done = books.where((b) => b.status == 'done').length;
  final now = books.where((b) => b.status == 'reading').toList();
  final cur = now.isEmpty ? null : now.first;
  return HubStat(
    sub: cur == null
        ? tr('${arNum(books.length)} كتاب فى المكتبة',
            '${arNum(books.length)} books')
        : tr('«${cur.title}» · صفحة ${arNum(cur.currentPage)}',
            '"${cur.title}" · page ${arNum(cur.currentPage)}'),
    big: arNum(done),
    bigSub: tr('كتاب خلّصته', 'finished'),
  );
}

/// التعلّم: الكورس الشغّال ونسبته + عدد الشغّالين.
Future<HubStat?> coursesStat() async {
  final all = await CoursesRepo().all();
  if (all.isEmpty) return null;
  final active = all.where((c) => c.status != 'done').toList();
  final cur = active.isEmpty ? null : active.first;
  final pct = cur == null || cur.totalUnits <= 0
      ? null
      : (cur.doneUnits / cur.totalUnits * 100).round();
  return HubStat(
    sub: cur == null
        ? tr('كلهم خلصوا', 'All done')
        : pct == null
            ? cur.title
            : tr('${cur.title} · ${arNum(pct)}٪', '${cur.title} · $pct%'),
    big: arNum(active.length),
    bigSub: tr('كورس شغّال', 'in progress'),
  );
}

/// العادات: أطول سلسلة شغّالة دلوقتى.
Future<HubStat?> habitsStat() async {
  final stats = await HabitsRepo().analytics();
  if (stats.isEmpty) return null;
  final best = stats.reduce((a, b) => b.streak > a.streak ? b : a);
  if (best.streak == 0) {
    return HubStat(
      sub: tr('${arNum(stats.length)} عادة · مافيش سلسلة شغّالة',
          '${arNum(stats.length)} habits · no active streak'),
    );
  }
  return HubStat(
    sub: tr('أطول سلسلة: ${best.habit.name}',
        'Longest streak: ${best.habit.name}'),
    big: arNum(best.streak),
    bigSub: tr('يوم', 'days'),
  );
}

/// التحديات: التحدى الشغّال واليوم اللى انت فيه.
Future<HubStat?> challengesStat() async {
  final all = await ChallengesRepo().all();
  if (all.isEmpty) return null;
  final live = <Challenge, int>{};
  for (final c in all) {
    final passed = _daysSince(c.startDate);
    if (passed == null || passed < 0) continue;
    if (passed < c.days) live[c] = passed + 1;
  }
  if (live.isEmpty) {
    return HubStat(
      sub: tr('${arNum(all.length)} تحدى خلصوا', '${arNum(all.length)} finished'),
    );
  }
  final first = live.entries.first;
  return HubStat(
    sub: tr('${first.key.name} · يوم ${arNum(first.value)} من ${arNum(first.key.days)}',
        '${first.key.name} · day ${arNum(first.value)} of ${arNum(first.key.days)}'),
    big: arNum(live.length),
    bigSub: tr('شغّال', 'active'),
  );
}

/// عدّاد الإقلاع: كام يوم وانت بعيد + اللى وفّرته.
Future<HubStat?> quitStat() async {
  final all = await QuitRepo().all();
  if (all.isEmpty) return null;
  final c = all.first;
  final days = _daysSince(c.startDate) ?? 0;
  final saved = c.dailySaving * days;
  return HubStat(
    sub: saved > 0
        ? tr('${c.name} · وفّرت ${egp(saved)}',
            '${c.name} · saved ${egp(saved)}')
        : c.name,
    big: arNum(days),
    bigSub: tr('يوم', 'days'),
  );
}

/// صلة الرحم: مين فات ميعاد الاطمئنان عليه.
///
/// الرقم هنا **اللى فات** مش الإجمالى — لإن ده اللى بيخلّيك تفتح.
Future<HubStat?> relativesStat() async {
  final repo = RelativesRepo();
  final all = await repo.all();
  if (all.isEmpty) return null;
  final due = await repo.due(DateTime.now());
  if (due.isEmpty) {
    return HubStat(
      sub: tr('كلهم مطمّن عليهم', 'All caught up'),
      big: arNum(all.length),
      bigSub: tr('حد', 'people'),
    );
  }
  return HubStat(
    sub: tr('محتاج تطمن على ${arNum(due.length)}',
        '${arNum(due.length)} to check on'),
    big: arNum(due.length),
    bigSub: tr('فاتت', 'overdue'),
    bigColor: _late,
  );
}

/// كلمات السر: عددها — وإنها على الجهاز مش على أى سيرفر.
Future<HubStat?> passwordsStat() async {
  final all = await PasswordsRepo().all();
  if (all.isEmpty) return null;
  return HubStat(
    sub: tr('محفوظة على الجهاز', 'Stored on this device'),
    big: arNum(all.length),
    bigSub: tr('كلمة', 'saved'),
  );
}

/// خلاصة «تطوّرى» كلها: كام يوم من الأسبوع فيه نشاط + أطول سلسلة.
///
/// «فيه نشاط» = عملت عادة واحدة على الأقل فى اليوم ده. ده أصدق مقياس
/// متاح دلوقتى؛ لو اتضاف مصدر تانى (قراءة/كورس) يتضم هنا.
Future<(int daysThisWeek, int bestStreak)> growthWeek() async {
  final repo = HabitsRepo();
  final today = dateOnly(DateTime.now());
  var days = 0;
  for (var i = 0; i < 7; i++) {
    final d = today.subtract(Duration(days: i));
    if ((await repo.doneOn(dayKey(d))).isNotEmpty) days++;
  }
  final stats = await repo.analytics();
  final best = stats.isEmpty
      ? 0
      : stats.map((s) => s.streak).reduce((a, b) => a > b ? a : b);
  return (days, best);
}

// ————————————————— المتابعة والأدوات —————————————————

/// الرسوم: كام رسم **هيرسم فعلاً**، مش كام رسم موجود.
///
/// الفرق هو كل الفايدة: شاشة الرسوم فيها ٨ رسوم، بس الرسم اللى مالوش
/// بيانات بيطلع صندوق فاضى. فالرقم بيعدّ المصادر اللى فيها قراءة.
Future<HubStat?> chartsStat() async {
  final db = await AppDb.instance;
  final from = dayKey(dateOnly(DateTime.now()).subtract(const Duration(days: 29)));

  Future<bool> anyDay(String table) async =>
      (await db.query(table, where: 'day >= ?', whereArgs: [from], limit: 1))
          .isNotEmpty;

  var n = 0;
  for (final t in const ['sleep_logs', 'fitness_logs', 'steps_logs', 'water_logs']) {
    if (await anyDay(t)) n++;
  }
  if ((await db.query('measurements',
          where: 'type = ?', whereArgs: ['وزن'], limit: 1))
      .isNotEmpty) {
    n++;
  }
  if ((await db.query('expenses', limit: 1)).isNotEmpty) n++;

  if (n == 0) return null;
  return HubStat(
    sub: tr('نوم · خطوات · مياه · وزن · مصاريف',
        'Sleep · steps · water · weight · spending'),
    big: arNum(n),
    bigSub: tr('رسم فيه بيانات', 'with data'),
  );
}

/// تقارير PDF — تلاتة ثابتة (مخصّص · الشهر · الدكتور).
Future<HubStat?> pdfReportsStat() async => HubStat(
      sub: tr('مخصّص · الشهر · الدكتور', 'Custom · month · doctor'),
      big: arNum(3),
      bigSub: tr('تقرير', 'reports'),
    );

/// الحاسبات — تمانية ثابتة.
Future<HubStat?> calculatorsStat() async => HubStat(
      sub: tr('زكاة · كتلة جسم · قسط · وحدات', 'Zakat · BMI · loan · units'),
      big: arNum(8),
    );

/// تقويم النتيجة: كام يوم فيه نشاط فى الشهر ده.
Future<HubStat?> calendarStat() async {
  final now = DateTime.now();
  final days = await DayLogRepo().daysWithActivity(now.year, now.month);
  if (days.isEmpty) return null;
  return HubStat(
    sub: tr('دوس على يوم تشوفه كله', 'Tap a day to see all of it'),
    big: arNum(days.length),
    bigSub: tr('يوم فيه نشاط', 'active days'),
  );
}

/// قواعدى: كام قاعدة **بتتحقق دلوقتى** — مش كام قاعدة عندك.
///
/// الفرق مهم: «٥ قواعد» رقم ساكت، و«١ بتتحقق» رقم بيناديك تفتح.
Future<HubStat?> rulesStat() async {
  final rules = await RulesRepo().all();
  if (rules.isEmpty) return null;
  final values = await metricValues();
  final firing = rules
      .where((r) =>
          r.enabled && ruleFires(r.op, values[r.metric] ?? 0, r.threshold))
      .length;
  if (firing == 0) {
    return HubStat(
      sub: tr('مفيش قاعدة بتتحقق دلوقتى', 'Nothing triggering now'),
      big: arNum(rules.length),
      bigSub: tr('قاعدة', 'rules'),
    );
  }
  return HubStat(
    sub: tr('لو حصل كذا نبّهنى', 'Alert me when…'),
    big: arNum(firing),
    bigSub: tr('بتتحقق', 'firing'),
    bigColor: _late,
  );
}

/// صندوق الوارد: كام فكرة لسه ما اتصنّفتش.
Future<HubStat?> inboxStat() async {
  final n = await InboxRepo().count();
  if (n == 0) return null;
  return HubStat(
    sub: tr('فكرة سريعة تصنّفها بعدين', 'Quick notes to sort later'),
    big: arNum(n),
  );
}

/// التخطيط الأسبوعى: آخر مرة خطّطت فيها امتى.
///
/// البند ده مالوش «عدد»، فالرقم اللى يهم هو **آخر مرة** — لإن قيمته إنه
/// طقس أسبوعى، والسؤال الوحيد عنه: عملته الأسبوع ده ولا لأ.
Future<HubStat?> weeklyPlanStat() async {
  final now = DateTime.now();
  final repo = WeeklyRepo();
  // بندوّر لورا ١٢ أسبوع على آخر مراجعة متسجّلة.
  for (var w = 0; w < 12; w++) {
    final d = now.subtract(Duration(days: 7 * w));
    if (await repo.forWeek(currentWeekKey(d)) == null) continue;
    return HubStat(
      sub: switch (w) {
        0 => tr('خطّطت الأسبوع ده', 'Planned this week'),
        1 => tr('آخر مرة الأسبوع اللى فات', 'Last done a week ago'),
        _ => tr('آخر مرة من ${arNum(w)} أسابيع', 'Last done ${arNum(w)} weeks ago'),
      },
      bigColor: w > 1 ? _late : null,
    );
  }
  return HubStat(sub: tr('طقس ${arNum(10)} دقايق آخر الأسبوع', 'A 10-minute weekly ritual'));
}

/// المستندات: عددها. اللى قرب ينتهى بتقوله الشارة الحمرا على الكارت،
/// فمش بنكرّره هنا.
Future<HubStat?> docsStat() async {
  final all = await DocsRepo().all();
  if (all.isEmpty) return null;
  return HubStat(
    sub: tr('بطاقة · رخصة · عقود', 'ID · licence · contracts'),
    big: arNum(all.length),
    bigSub: tr('ورقة', 'docs'),
  );
}

/// رؤى المدير: كام رؤية طلعت من بياناتك فعلاً.
Future<HubStat?> insightsStat() async {
  final n = buildInsights(await InsightsRepo().assemble()).length;
  if (n == 0) return null;
  return HubStat(
    sub: tr('أنماط من بياناتك', 'Patterns from your data'),
    big: arNum(n),
    bigSub: tr('رؤية', 'insights'),
  );
}
