import 'package:sqflite/sqflite.dart';

import 'ar.dart';
import 'db.dart';
import 'l10n.dart';

/// المقاييس اللى المستخدم يقدر يبني عليها قاعدة (كلها من بيانات موجودة).
const List<String> kRuleMetricKeys = [
  'weekly_spend',
  'monthly_spend',
  'today_steps',
  'today_water',
];

String ruleMetricLabel(String key) {
  switch (key) {
    case 'weekly_spend':
      return tr('مصاريف آخر ٧ أيام', 'Last 7 days spend');
    case 'monthly_spend':
      return tr('مصاريف الشهر', 'This month spend');
    case 'today_steps':
      return tr('خطوات النهاردة', "Today's steps");
    case 'today_water':
      return tr('مياه النهاردة (أكواب)', "Today's water (cups)");
    default:
      return key;
  }
}

String ruleMetricUnit(String key) {
  switch (key) {
    case 'weekly_spend':
    case 'monthly_spend':
      return tr('ج', 'EGP');
    case 'today_steps':
      return tr('خطوة', 'steps');
    case 'today_water':
      return tr('كوب', 'cups');
    default:
      return '';
  }
}

/// القاعدة «بتتحقق» لو القيمة الحالية أكبر (>) أو أصغر (<) من الحد. خالص/متغطّى بتست.
bool ruleFires(String op, double value, double threshold) =>
    op == '<' ? value < threshold : value > threshold;

/// القيم الحالية لكل مقياس (قراءة فقط من الجداول الموجودة).
Future<Map<String, double>> metricValues({Database? database}) async {
  final db = database ?? await AppDb.instance;
  final now = DateTime.now();
  final weekStart = dayKey(now.subtract(const Duration(days: 6)));
  final month =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  final today = dayKey(now);

  double num0(List<Map<String, Object?>> rows, String col) =>
      rows.isNotEmpty ? ((rows.first[col] as num?) ?? 0).toDouble() : 0.0;

  try {
    final ws = num0(
        await db.rawQuery(
            'SELECT COALESCE(SUM(amount),0) t FROM expenses WHERE day >= ?',
            [weekStart]),
        't');
    final ms = num0(
        await db.rawQuery(
            'SELECT COALESCE(SUM(amount),0) t FROM expenses WHERE day LIKE ?',
            ['$month%']),
        't');
    final steps = num0(
        await db.rawQuery(
            'SELECT steps FROM steps_logs WHERE day = ?', [today]),
        'steps');
    final water = num0(
        await db.rawQuery(
            'SELECT glasses FROM water_logs WHERE day = ?', [today]),
        'glasses');
    return {
      'weekly_spend': ws,
      'monthly_spend': ms,
      'today_steps': steps,
      'today_water': water,
    };
  } catch (_) {
    return {for (final k in kRuleMetricKeys) k: 0.0};
  }
}
