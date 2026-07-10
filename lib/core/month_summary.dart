import '../data/money_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'notifications.dart';

/// خلاصة الشهر المالية: إشعار مرة واحدة في أول أيام الشهر الجديد
/// بملخص الشهر اللي فات — واقتراح ميزانية من متوسط آخر ٣ شهور.
class MonthSummary {
  static const int notifId = 930001;

  /// متوسط مصاريف آخر [months] شهور كاملة — null لو مفيش بيانات كفاية.
  static Future<double?> suggestedBudget({int months = 3}) async {
    final money = MoneyRepo();
    final now = DateTime.now();
    final totals = <double>[];
    for (var i = 1; i <= months; i++) {
      final m = DateTime(now.year, now.month - i);
      final total = await money.totalForMonth(m.year, m.month);
      if (total > 0) totals.add(total);
    }
    if (totals.length < 2) return null;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  static Future<void> ensure() async {
    final now = DateTime.now();
    if (now.day > 3) return; // بنعرضها في أول ٣ أيام بس
    final settings = SettingsRepo();
    final prev = DateTime(now.year, now.month - 1);
    final prevKey = MoneyRepo.monthPrefix(prev.year, prev.month);
    if (await settings.get('last_month_summary') == prevKey) return;

    final money = MoneyRepo();
    final total = await money.totalForMonth(prev.year, prev.month);
    if (total <= 0) return;
    final byCat = await money.byCategory(prev.year, prev.month);
    final before = DateTime(now.year, now.month - 2);
    final beforeTotal = await money.totalForMonth(before.year, before.month);

    final parts = <String>[
      tr('إجمالي ${arMonth(prev)}: ${egp(total)}.',
          'Total for ${arMonth(prev)}: ${egp(total)}.'),
    ];
    if (byCat.isNotEmpty) {
      final top = byCat.entries.first;
      parts.add(tr('أكبر بند: ${top.key} (${egp(top.value)}).',
          'Biggest category: ${top.key} (${egp(top.value)}).'));
    }
    if (beforeTotal > 100) {
      final change = ((total - beforeTotal) / beforeTotal * 100).round();
      if (change.abs() >= 10) {
        parts.add(change > 0
            ? tr('أعلى ٪${arNum(change)} من الشهر اللي قبله.',
                '${arNum(change)}% higher than the month before.')
            : tr('أقل ٪${arNum(-change)} من الشهر اللي قبله — شغل نضيف.',
                '${arNum(-change)}% lower than the month before — nice work.'));
      }
    }

    await Notifications.showNow(
      id: notifId,
      title: tr('خلاصة الشهر المالية', 'Monthly money summary'),
      body: parts.join(' '),
    );
    await settings.set('last_month_summary', prevKey);
  }
}
