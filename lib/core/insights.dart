// محرك الرؤى — إحصاء محلي خالص (بيرسون + أنماط + اتجاهات) من غير أي API.
// الملف ده نقي (مفيش Flutter ولا DB) عشان يتاختبر بسهولة.
import 'dart:math' as math;

import 'ar.dart';
import 'l10n.dart';

/// مقاييس يوم واحد — بتتجمع من الجداول المختلفة.
class DailyMetrics {
  final String day;
  final double? sleep;
  final int water;
  final double spend;

  /// نسبة إنجاز العادات في اليوم ده (null لو مفيش عادات وقتها).
  final double? habitRatio;
  final bool workout;
  final int? steps;

  /// سعرات نشطة محروقة ومسافة (كم) — من الساعة الذكية (null لو مش متاح).
  final int? calories;
  final double? distanceKm;

  const DailyMetrics({
    required this.day,
    this.sleep,
    this.water = 0,
    this.spend = 0,
    this.habitRatio,
    this.workout = false,
    this.steps,
    this.calories,
    this.distanceKm,
  });
}

class InsightData {
  /// مرتبة من الأقدم للأحدث.
  final List<DailyMetrics> days;
  final Map<String, double> monthByCategory;
  final Map<String, double> prevMonthByCategory;
  final Map<String, int> habitStreaks;

  /// نسبة التزام كل عادة آخر ٣٠ يوم (0..1).
  final Map<String, double> habitCompletion;

  const InsightData({
    required this.days,
    this.monthByCategory = const {},
    this.prevMonthByCategory = const {},
    this.habitStreaks = const {},
    this.habitCompletion = const {},
  });
}

enum InsightKind { correlation, pattern, trend, habit, celebration, info }

class Insight {
  final InsightKind kind;
  final String text;
  final double weight;

  const Insight(this.kind, this.text, this.weight);
}

/// معامل ارتباط بيرسون — null لو البيانات مش كفاية أو من غير تباين.
double? pearson(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2 || n != ys.length) return null;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = ys.reduce((a, b) => a + b) / n;
  var cov = 0.0, vx = 0.0, vy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    final dy = ys[i] - my;
    cov += dx * dy;
    vx += dx * dx;
    vy += dy * dy;
  }
  if (vx == 0 || vy == 0) return null;
  return cov / math.sqrt(vx * vy);
}

List<Insight> buildInsights(InsightData data) {
  final out = <Insight>[];
  _correlations(data, out);
  _weekdaySpending(data, out);
  _sleepTrend(data, out);
  _categoryChange(data, out);
  _habitInsights(data, out);
  if (out.isEmpty) {
    out.add(Insight(
        InsightKind.info,
        tr(
            'لسه بجمع بيانات كفاية عنك — كمّل تسجيل أسبوعين وهتلاقي هنا '
                'استنتاجات حقيقية عن نومك وفلوسك وعاداتك.',
            "Still gathering enough data about you — keep logging for a couple of "
                'weeks and real insights about your sleep, money and habits will '
                'appear here.'),
        0));
  }
  out.sort((a, b) => b.weight.compareTo(a.weight));
  return out;
}

void _pairCorrelation({
  required List<Insight> out,
  required List<double?> a,
  required List<double?> b,
  required String positiveText,
  required String negativeText,
}) {
  final xs = <double>[];
  final ys = <double>[];
  for (var i = 0; i < a.length; i++) {
    final av = a[i];
    final bv = b[i];
    if (av != null && bv != null) {
      xs.add(av);
      ys.add(bv);
    }
  }
  if (xs.length < 14) return;
  final r = pearson(xs, ys);
  if (r == null || r.abs() < 0.4) return;
  final strength = r.abs() >= 0.6
      ? tr('علاقة واضحة', 'clear link')
      : tr('علاقة ملحوظة', 'notable link');
  final text = r > 0 ? positiveText : negativeText;
  out.add(Insight(
      InsightKind.correlation,
      tr('$text ($strength في آخر ${arNum(xs.length)} يوم).',
          '$text ($strength over the last ${arNum(xs.length)} days).'),
      r.abs()));
}

void _correlations(InsightData data, List<Insight> out) {
  final days = data.days;
  final sleep = [for (final d in days) d.sleep];
  final spend = [for (final d in days) (d.spend >= 0 ? d.spend : null)];
  final habits = [for (final d in days) d.habitRatio];
  final steps = [for (final d in days) d.steps?.toDouble()];
  final calories = [for (final d in days) d.calories?.toDouble()];
  final workout = [for (final d in days) d.workout ? 1.0 : 0.0];

  _pairCorrelation(
    out: out,
    a: sleep,
    b: spend,
    positiveText: tr('مصاريفك بتزيد في الأيام اللي بتنام فيها أكتر',
        'You spend more on days you sleep more'),
    negativeText: tr('مصاريفك بتزيد في الأيام اللي نومك فيها قليل',
        'You spend more on days you sleep less'),
  );
  _pairCorrelation(
    out: out,
    a: sleep,
    b: habits,
    positiveText: tr('التزامك بعاداتك أعلى لما تنام كويس',
        'You stick to your habits more when you sleep well'),
    negativeText: tr('قلة النوم مش بتأثر على التزامك بعاداتك — عاش',
        "Poor sleep doesn't hurt your habit consistency — nice"),
  );
  _pairCorrelation(
    out: out,
    a: steps,
    b: sleep,
    positiveText: tr('الأيام اللي بتتحرك فيها أكتر بتنام فيها أحسن',
        'You sleep better on days you move more'),
    negativeText: tr('كتر الحركة مش بيحسن نومك — جرب تبدري بالنوم',
        "More movement isn't improving your sleep — try sleeping earlier"),
  );
  _pairCorrelation(
    out: out,
    a: [for (final w in workout) w],
    b: sleep,
    positiveText: tr('أيام التمرين نومك فيها أطول',
        'You sleep longer on workout days'),
    negativeText: tr('أيام التمرين نومك فيها أقل — بلاش تمرين متأخر',
        'You sleep less on workout days — avoid late workouts'),
  );
  _pairCorrelation(
    out: out,
    a: calories,
    b: sleep,
    positiveText: tr('الأيام اللي بتحرق فيها سعرات أكتر بتنام فيها أحسن',
        'You sleep better on days you burn more calories'),
    negativeText: tr('حرق سعرات أكتر مش بيحسن نومك — جرب تبدري بالمجهود',
        "Burning more calories isn't improving your sleep — try exerting earlier"),
  );
}

void _weekdaySpending(InsightData data, List<Insight> out) {
  final days = data.days;
  if (days.length < 28) return;
  final sums = List<double>.filled(8, 0);
  final counts = List<int>.filled(8, 0);
  for (final d in days) {
    final weekday = DateTime.parse(d.day).weekday;
    sums[weekday] += d.spend;
    counts[weekday]++;
  }
  final names = [
    '',
    tr('الإثنين', 'Monday'),
    tr('التلات', 'Tuesday'),
    tr('الأربع', 'Wednesday'),
    tr('الخميس', 'Thursday'),
    tr('الجمعة', 'Friday'),
    tr('السبت', 'Saturday'),
    tr('الحد', 'Sunday'),
  ];
  var bestDay = 0;
  var bestAvg = 0.0;
  var totalAvg = 0.0;
  var totalDays = 0;
  for (var w = 1; w <= 7; w++) {
    if (counts[w] < 3) return;
    final avg = sums[w] / counts[w];
    totalAvg += sums[w];
    totalDays += counts[w];
    if (avg > bestAvg) {
      bestAvg = avg;
      bestDay = w;
    }
  }
  totalAvg = totalAvg / totalDays;
  if (bestAvg >= totalAvg * 1.4 && bestAvg >= 50) {
    out.add(Insight(
        InsightKind.pattern,
        tr(
            'يوم ${names[bestDay]} هو أعلى أيامك صرفًا — متوسط ${egp(bestAvg)} '
                'مقابل ${egp(totalAvg)} لباقي الأيام.',
            '${names[bestDay]} is your highest-spending day — averaging '
                '${egp(bestAvg)} vs ${egp(totalAvg)} on other days.'),
        0.55));
  }
}

void _sleepTrend(InsightData data, List<Insight> out) {
  final days = data.days;
  if (days.length < 14) return;
  final last7 = days.sublist(days.length - 7);
  final prev7 = days.sublist(days.length - 14, days.length - 7);
  double? avg(List<DailyMetrics> ds) {
    final vals = [
      for (final d in ds)
        if (d.sleep != null) d.sleep!
    ];
    if (vals.length < 4) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  final a = avg(prev7);
  final b = avg(last7);
  if (a == null || b == null) return;
  final diff = b - a;
  if (diff.abs() < 0.5) return;
  out.add(Insight(
      InsightKind.trend,
      diff > 0
          ? tr(
              'نومك اتحسن الأسبوع ده: متوسط ${arNum(b.toStringAsFixed(1))} ساعة '
                  'مقابل ${arNum(a.toStringAsFixed(1))} الأسبوع اللي فات — كمّل.',
              'Your sleep improved this week: averaging '
                  '${arNum(b.toStringAsFixed(1))} hours vs '
                  '${arNum(a.toStringAsFixed(1))} last week — keep it up.')
          : tr(
              'نومك قلّ الأسبوع ده: متوسط ${arNum(b.toStringAsFixed(1))} ساعة '
                  'مقابل ${arNum(a.toStringAsFixed(1))} الأسبوع اللي فات — خد بالك.',
              'Your sleep dropped this week: averaging '
                  '${arNum(b.toStringAsFixed(1))} hours vs '
                  '${arNum(a.toStringAsFixed(1))} last week — take care.'),
      0.5 + diff.abs() / 10));
}

void _categoryChange(InsightData data, List<Insight> out) {
  String? topCat;
  var topChange = 0.0;
  double topNow = 0, topPrev = 0;
  for (final e in data.monthByCategory.entries) {
    final prev = data.prevMonthByCategory[e.key];
    if (prev == null || prev < 100) continue;
    final change = (e.value - prev) / prev;
    if (change.abs() >= 0.3 && change.abs() > topChange.abs()) {
      topChange = change;
      topCat = e.key;
      topNow = e.value;
      topPrev = prev;
    }
  }
  if (topCat == null) return;
  final pct = (topChange * 100).abs().round();
  out.add(Insight(
      InsightKind.trend,
      topChange > 0
          ? tr(
              'صرفك على «$topCat» الشهر ده زاد ٪${arNum(pct)} عن اللي فات '
                  '(${egp(topNow)} مقابل ${egp(topPrev)}).',
              'Your spending on "$topCat" rose ${arNum(pct)}% this month vs last '
                  '(${egp(topNow)} vs ${egp(topPrev)}).')
          : tr('صرفك على «$topCat» الشهر ده قلّ ٪${arNum(pct)} — شغل نضيف.',
              'Your spending on "$topCat" dropped ${arNum(pct)}% this month — nice work.'),
      0.45 + topChange.abs() / 4));
}

void _habitInsights(InsightData data, List<Insight> out) {
  // أطول سلسلة حالية تستاهل احتفال.
  String? bestHabit;
  var bestStreak = 0;
  data.habitStreaks.forEach((name, streak) {
    if (streak > bestStreak) {
      bestStreak = streak;
      bestHabit = name;
    }
  });
  if (bestHabit != null && bestStreak >= 7) {
    out.add(Insight(
        InsightKind.celebration,
        tr(
            'أطول سلسلة حالية: «$bestHabit» — ${arNum(bestStreak)} يوم متواصل. '
                'حافظ عليها!',
            'Longest current streak: "$bestHabit" — ${arNum(bestStreak)} days in a '
                'row. Keep it going!'),
        0.35 + bestStreak / 100));
  }
  // العادة الأكتر تفويتًا.
  String? worstHabit;
  var worstRatio = 1.0;
  data.habitCompletion.forEach((name, ratio) {
    if (ratio < worstRatio) {
      worstRatio = ratio;
      worstHabit = name;
    }
  });
  if (worstHabit != null &&
      worstRatio < 0.5 &&
      data.habitCompletion.length >= 2) {
    out.add(Insight(
        InsightKind.habit,
        tr(
            'عادة «$worstHabit» هي الأكتر تفويتًا (٪${arNum((worstRatio * 100).round())} '
                'التزام آخر ٣٠ يوم) — جرب تصغرها أو تنقل وقتها.',
            'The habit "$worstHabit" is your most-missed '
                '(${arNum((worstRatio * 100).round())}% adherence over 30 days) — '
                'try shrinking it or moving its time.'),
        0.4 + (0.5 - worstRatio)));
  }
}
