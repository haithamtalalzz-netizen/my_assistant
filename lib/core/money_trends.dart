import '../data/income_repo.dart';
import '../data/money_repo.dart';
import 'ar.dart';

/// مقارنة فئة واحدة بين شهرين.
class CategoryDelta {
  final String category;
  final double now;
  final double prev;

  const CategoryDelta(this.category, this.now, this.prev);

  double get diff => now - prev;

  /// نسبة التغيّر — null لو الشهر اللى فات كان صفر (مافيش أساس نقارن عليه،
  /// و«∞٪» مش رقم مفيد).
  double? get percent => prev <= 0 ? null : diff / prev * 100;

  bool get isNew => prev <= 0 && now > 0;
  bool get stopped => now <= 0 && prev > 0;
}

/// اتجاه شهر واحد فى ترند الرصيد.
class MonthFlow {
  final int year;
  final int month;
  final double income;
  final double spent;

  const MonthFlow({
    required this.year,
    required this.month,
    required this.income,
    required this.spent,
  });

  double get net => income - spent;
  String get label => arMonthShort(DateTime(year, month));
}

/// تحليلات الفلوس عبر الشهور — طبقة core من غير ودجت عشان تتختبر.
class MoneyTrends {
  /// مقارنة كل فئة بين شهر و[months] شهر قبله (افتراضى: الشهر السابق).
  /// بترجّع الفئات مرتّبة **بأكبر فرق مطلق** — اللى اتغير فعلًا هو المهم،
  /// مش اللى صرفت فيه أكتر.
  static Future<List<CategoryDelta>> categoryDeltas(int year, int month) async {
    final repo = MoneyRepo();
    final now = await repo.byCategory(year, month);
    final prevDate = DateTime(year, month - 1);
    final prev = await repo.byCategory(prevDate.year, prevDate.month);
    final keys = {...now.keys, ...prev.keys};
    final out = [
      for (final k in keys) CategoryDelta(k, now[k] ?? 0, prev[k] ?? 0)
    ];
    out.sort((a, b) => b.diff.abs().compareTo(a.diff.abs()));
    return out;
  }

  /// دخل/مصروف/صافى لآخر [count] شهر (الأقدم الأول) — لترند الرصيد.
  static Future<List<MonthFlow>> monthlyFlow(int year, int month,
      {int count = 6}) async {
    final money = MoneyRepo();
    final income = IncomeRepo();
    final out = <MonthFlow>[];
    for (var i = count - 1; i >= 0; i--) {
      final m = DateTime(year, month - i);
      out.add(MonthFlow(
        year: m.year,
        month: m.month,
        income: await income.totalForMonth(m.year, m.month),
        spent: await money.totalForMonth(m.year, m.month),
      ));
    }
    return out;
  }

  /// الرصيد التراكمى عبر الشهور (بيبدأ من صفر) — بيوضّح لو بتاكل من رصيدك.
  static List<double> cumulativeNet(List<MonthFlow> flow) {
    var running = 0.0;
    return [
      for (final f in flow)
        running += f.net,
    ];
  }
}
