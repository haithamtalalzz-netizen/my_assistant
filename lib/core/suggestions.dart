import 'ar.dart';
import 'insights.dart';
import 'l10n.dart';

/// اقتراح عملى واحد — نص + وزن (الأعلى بيتعرض الأول).
class Suggestion {
  final String text;
  final double weight;

  const Suggestion(this.text, this.weight);
}

/// «مديرك بيقترح» — قواعد بسيطة **فوق** بيانات الرؤى الموجودة.
///
/// الفرق عن `buildInsights`: ده مابيوصفش نمط («نومك بيقل») — بيقول **تعمل
/// إيه**. وكل قاعدة بتقارن آخر أسبوع بالأسبوع اللى قبله من نفس البيانات،
/// فمفيش أى رقم مخترع.
///
/// طبقة نقية (مفيش Flutter ولا DB) عشان تتختبر — زى `insights.dart`.
List<Suggestion> buildSuggestions(InsightData data) {
  final out = <Suggestion>[];
  final days = data.days;
  if (days.length < 8) return out; // محتاجين أسبوعين نقارن بينهم

  final recent = days.sublist(days.length - 7);
  final before = days.sublist(
      days.length >= 14 ? days.length - 14 : 0, days.length - 7);
  if (before.isEmpty) return out;

  double? avg(List<DailyMetrics> list, double? Function(DailyMetrics) pick) {
    final vals = [for (final d in list) if (pick(d) != null) pick(d)!];
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  final sleepNow = avg(recent, (d) => d.sleep);
  final sleepPrev = avg(before, (d) => d.sleep);
  final spendNow = avg(recent, (d) => d.spend);
  final spendPrev = avg(before, (d) => d.spend);
  final waterNow = avg(recent, (d) => d.water.toDouble());
  final waterPrev = avg(before, (d) => d.water.toDouble());
  final habitNow = avg(recent, (d) => d.habitRatio);
  final habitPrev = avg(before, (d) => d.habitRatio);

  // القاعدة الأساسية من الخطة: نوم قل + مصاريف زادت.
  if (sleepNow != null &&
      sleepPrev != null &&
      spendNow != null &&
      spendPrev != null &&
      sleepNow < sleepPrev - 0.5 &&
      spendNow > spendPrev * 1.2 &&
      spendPrev > 0) {
    out.add(Suggestion(
      tr(
          'نومك قلّ (${arNum(sleepNow.toStringAsFixed(1))} ساعة بدل ${arNum(sleepPrev.toStringAsFixed(1))}) ومصاريفك زادت — التعب بيخلّى القرارات أسرع. جرّب تنام بدرى ٣ أيام وشوف الفرق.',
          'Sleep is down (${arNum(sleepNow.toStringAsFixed(1))}h vs ${arNum(sleepPrev.toStringAsFixed(1))}h) and spending is up — tiredness makes decisions quicker. Try 3 earlier nights and compare.'),
      3.0,
    ));
  }

  // نوم قل لوحده.
  if (sleepNow != null && sleepPrev != null && sleepNow < sleepPrev - 1) {
    out.add(Suggestion(
      tr('نومك قلّ ساعة عن الأسبوع اللى فات — حاول تقفل الموبايل بدرى النهارده.',
          "You're sleeping an hour less than last week — try an early phone-off tonight."),
      2.0,
    ));
  }

  // مصاريف زادت لوحدها (مع أكبر فئة زادت).
  if (spendNow != null &&
      spendPrev != null &&
      spendPrev > 0 &&
      spendNow > spendPrev * 1.3) {
    final top = _topRisingCategory(data);
    out.add(Suggestion(
      top == null
          ? tr('مصاريفك الأسبوع ده أعلى بوضوح عن اللى فات — راجع «فين فلوسى؟».',
              "This week's spending is clearly higher — check “Where did my money go?”.")
          : tr('مصاريفك زادت، وأكتر بند طالع هو «$top» — راجعه.',
              'Spending is up, and the biggest riser is "$top" — take a look.'),
      2.2,
    ));
  }

  // المياه قلّت.
  if (waterNow != null && waterPrev != null && waterNow < waterPrev - 1) {
    out.add(Suggestion(
      tr('شربك للمياه قلّ عن الأسبوع اللى فات — خلّى كوباية جنبك دلوقتى.',
          'Water intake dropped vs last week — keep a glass next to you now.'),
      1.5,
    ));
  }

  // العادات قلّت.
  if (habitNow != null &&
      habitPrev != null &&
      habitPrev > 0.3 &&
      habitNow < habitPrev - 0.25) {
    out.add(Suggestion(
      tr('التزامك بالعادات قلّ الأسبوع ده — ابدأ بعادة واحدة بس النهارده، السلسلة بترجع.',
          'Habit consistency dropped this week — do just one today; the streak comes back.'),
      1.8,
    ));
  }

  out.sort((a, b) => b.weight.compareTo(a.weight));
  return out;
}

/// أكتر فئة زادت عن الشهر اللى فات (بالقيمة المطلقة) — null لو مفيش بيانات.
String? _topRisingCategory(InsightData data) {
  if (data.monthByCategory.isEmpty || data.prevMonthByCategory.isEmpty) {
    return null;
  }
  String? best;
  var bestDiff = 0.0;
  for (final e in data.monthByCategory.entries) {
    final diff = e.value - (data.prevMonthByCategory[e.key] ?? 0);
    if (diff > bestDiff) {
      bestDiff = diff;
      best = e.key;
    }
  }
  return best;
}
