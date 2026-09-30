import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/bills_repo.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../data/wallets_repo.dart';
import '../../data/wealth_history.dart';
import '../../models/models.dart';
import '../../widgets/bar_actions.dart';
import '../../widgets/history_calendar.dart';
import '../../widgets/search_action.dart';
import 'fixed_monthly_screen.dart';
import 'income_sheet.dart';
import 'money_log_screen.dart';
import 'quick_expense_sheet.dart';
import 'wallets_screen.dart';

/// **فلوسى** — اتبنى من الأول بالتقسيمة دى:
///
///   ١ إجمالى فلوسى فوق، مقسوم على المحافظ (كاش · بنوك · ذهب وفضة ·
///     أصول · مواشى) — كل محفظة مربّع بلونها.
///   ٢ «صرفت إيه النهاردة؟» — دوس عليها تختار يوم أو شهر أو سنة أو
///     فترة من–إلى.
///   ٣ زرار «＋ صرفت» و«＋ قبضت».
///   ٤ «اللى ثابت كل شهر» — دخلك · فواتير ثابتة · الفاضل بعدهم.
///
/// الشكل القديم (٨ كروت تحليل + ٥ أقسام ورا زرار «شوف كل حاجة») اتشال
/// خالص بطلبه. البنود اللى فى السايدبار (الادخار · الديون · الجمعيات ·
/// الاشتراكات · الأمنيات) شاشات مستقلة وماتغيّرتش.
class MoneyScreen extends StatefulWidget {
  final Widget? drawer;
  const MoneyScreen({super.key, this.drawer});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _money = MoneyRepo();
  final _wallets = WalletsRepo();
  final _bills = BillsRepo();
  final _income = IncomeRepo();

  bool _loading = true;

  List<({Wallet wallet, double balance})> _list = [];
  double _total = 0;

  late DateTime _from;
  late DateTime _to;
  double _spent = 0;
  int _spentCount = 0;
  double _received = 0;
  int _receivedCount = 0;

  double _monthlyIncome = 0;
  double _monthlyBills = 0;
  double _certInterest = 0;

  double _liquid = 0;
  double _locked = 0;

  /// الفرق عن أول الشهر — null يعنى أول شهر بنسجّل فيه، فمانعرفش.
  double? _monthChange;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _from = today;
    _to = today;
    _load();
  }

  String _key(DateTime d) => dayKey(d);

  Future<void> _load() async {
    await _wallets.adoptLegacyMetalPrices();
    final list = await _wallets.allWithBalances();
    final total = list.fold<double>(0, (s, e) => s + e.balance);
    final sum = await _money.rangeSummary(_key(_from), _key(_to));
    final got = await _income.rangeSummary(_key(_from), _key(_to));

    final recurring = await _income.allRecurring();
    final bills = await _bills.all();
    final split = await _wallets.liquidSplit();
    final cert = await _wallets.monthlyCertificateInterest();

    // أول فتحة فى الشهر بتسجّل المرجع، واللى بعدها بتقارن بيه.
    await WealthHistory.recordIfNew(total);
    final change = await WealthHistory.changeThisMonth(total);

    if (!mounted) return;
    setState(() {
      _list = list;
      _total = total;
      _liquid = split.liquid;
      _locked = split.locked;
      _monthChange = change;
      _spent = sum.total;
      _spentCount = sum.count;
      _received = got.total;
      _receivedCount = got.count;
      _certInterest = cert;
      _monthlyIncome = recurring.fold<double>(0, (s, e) => s + e.amount);
      _monthlyBills = bills.fold<double>(0, (s, e) => s + e.amount);
      _loading = false;
    });
  }

  // ———————————————————— المدى ————————————————————

  /// سجل الفلوس بالتقويم — نفس الشاشة القديمة، بقت ورا أيقونة.
  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryCalendar(
          title: tr('سجل الفلوس', 'Money history'),
          accent: Colors.green,
          activeDays: (y, m) => _money.activeDaysInMonth(y, m),
          dayReport: (day) async {
            final r = await _money.dayReport(dayKey(day));
            return [
              if (r.income > 0)
                HistoryRow('💰', tr('دخل', 'Income'), egp(r.income)),
              HistoryRow('🧾', tr('مصروف', 'Spent'), egp(r.spent)),
              for (final e in r.byCategory.entries)
                HistoryRow('•', expenseCategoryLabel(e.key), egp(e.value)),
            ];
          },
        ),
      ),
    );
  }

  Future<void> _openWallets() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const WalletsScreen()));
    if (mounted) await _load();
  }

  Future<void> _addExpense() async {
    final ok = await openExpensePage(context);
    if (ok == true && mounted) await _load();
  }

  Future<void> _addIncome() async {
    final ok = await openIncomePage(context);
    if (ok == true && mounted) await _load();
  }

  // ———————————————————— البناء ————————————————————

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('فلوسى', 'My money')),
        actions: barActions(context, [
          BarAction(Icons.search, tr('بحث', 'Search'),
              () => openSearch(context)),
          BarAction(Icons.calendar_month_outlined,
              tr('سجل الفلوس', 'Money history'), _openHistory),
          BarAction(Icons.account_balance_wallet_outlined,
              tr('إدارة المحافظ', 'Manage wallets'), _openWallets),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                children: [
                  _totalBlock(context),
                  const SizedBox(height: 16),
                  _walletsButton(context),
                  const SizedBox(height: 11),
                  _logButtons(context),
                  const SizedBox(height: 11),
                  _fixedButton(context),
                  const SizedBox(height: 12),
                  _twoButtons(context),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  /// إجمالى فلوسى — الرقم الكبير فوق.
  Widget _totalBlock(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Text(tr('إجمالى فلوسى', 'Everything you own'),
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(arMoney(_total.round()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: scheme.primary)),
      Text(tr('جنيه', 'EGP'),
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
      if (_monthChange != null && _monthChange!.abs() >= 1) ...[
        const SizedBox(height: 6),
        _changeChip(context, _monthChange!),
      ],
      if (_locked > 0) ...[
        const SizedBox(height: 10),
        _liquidSplitBar(context),
      ],
    ]);
  }

  /// «زادت ولا قلّت الشهر ده» — الفرق عن أول الشهر.
  Widget _changeChip(BuildContext context, double change) {
    final up = change >= 0;
    final c = up ? const Color(0xFF10B981) : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: c),
        const SizedBox(width: 5),
        Text(
            up
                ? tr('زادت ${arMoney(change.round())} الشهر ده',
                    'Up ${arMoney(change.round())} this month')
                : tr('قلّت ${arMoney(change.abs().round())} الشهر ده',
                    'Down ${arMoney(change.abs().round())} this month'),
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w800, color: c)),
      ]),
    );
  }

  /// **السايلة والمربوطة** — الذهب والأصول والشهادة عندهم قيمة بس مش
  /// فلوس فى إيدك، وده اللى بيخلّى واحد «معاه مليون» ومش لاقى إيجار.
  Widget _liquidSplitBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF10B981);
    final sum = _liquid + _locked;
    final ratio = sum <= 0 ? 0.0 : (_liquid / sum).clamp(0.0, 1.0);
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 8,
          child: Row(children: [
            Expanded(
                flex: (ratio * 1000).round().clamp(1, 1000),
                child: Container(color: green)),
            Expanded(
                flex: ((1 - ratio) * 1000).round().clamp(1, 1000),
                child: Container(color: scheme.outlineVariant)),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _splitLabel(tr('سايلة', 'Liquid'), _liquid, green),
        const SizedBox(width: 14),
        _splitLabel(tr('مربوطة', 'Locked'), _locked, scheme.onSurfaceVariant),
      ]),
    ]);
  }

  Widget _splitLabel(String label, double value, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text('$label ${arMoney(value.round())}',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ]);

  /// **زرار المحافظ** — بنفس شكل باقى الأزرار.
  ///
  /// كانت مربعات بتاخد نص الشاشة، والإجمالى فوقها بيقول نفس الرقم.
  /// بقت سطر واحد بيقول عندك كام محفظة وإيه هى، والتفاصيل جوّه.
  Widget _walletsButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final names = [for (final e in _list) e.wallet.name].join(' · ');

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openWallets,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: scheme.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _list.isEmpty
                            ? tr('ضيف أول محفظة', 'Add your first wallet')
                            : tr('محافظك', 'Your wallets'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        _list.isEmpty
                            ? tr('كاش · بنك · ذهب · أصول · مواشى',
                                'cash · bank · gold · assets')
                            : names,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5, color: scheme.onSurfaceVariant)),
                  ]),
            ),
            const SizedBox(width: 8),
            if (_list.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99)),
                child: Text(arNum(_list.length),
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary)),
              ),
            Icon(Icons.chevron_left, size: 19, color: scheme.outline),
          ]),
        ),
      ),
    );
  }

  /// **زرارين**: «صرفت إيه» و«قبضت إيه» — كل واحد بيفتح سجلّه مقسوم
  /// بالأيام (النهاردة · امبارح · والتواريخ اللى قبلها).
  ///
  /// قبل كده كان كارت واحد للمصروف بس، والدخل مكانش ليه مكان تشوفه
  /// فيه أصلاً.
  Widget _logButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget btn({
      required String label,
      required String value,
      required String sub,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) =>
        Expanded(
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11)),
                          child: Icon(icon, size: 17, color: color),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_left,
                            size: 19, color: scheme.outline),
                      ]),
                      const SizedBox(height: 9),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: color)),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: scheme.onSurfaceVariant)),
                    ]),
              ),
            ),
          ),
        );

    // IntrinsicHeight: الـstretch جوّه صف ارتفاعه مفتوح بيفشل، والزرار
    // الأقصر كان هيطلع مش مظبوط مع اللى جنبه.
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      btn(
        label: tr('صرفت إيه؟', 'What I spent'),
        value: arMoney(_spent.round()),
        sub: tr('${arNum(_spentCount)} حركة النهاردة',
            '${arNum(_spentCount)} entries today'),
        icon: Icons.trending_down,
        color: scheme.error,
        onTap: () => _openLog(MoneyLogKind.spent),
      ),
      const SizedBox(width: 11),
      btn(
        label: tr('قبضت إيه؟', 'What I received'),
        value: arMoney(_received.round()),
        sub: tr('${arNum(_receivedCount)} حركة النهاردة',
            '${arNum(_receivedCount)} entries today'),
        icon: Icons.trending_up,
        color: const Color(0xFF10B981),
        onTap: () => _openLog(MoneyLogKind.received),
      ),
    ]),
    );
  }

  Future<void> _openLog(MoneyLogKind kind) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => MoneyLogScreen(kind: kind)));
    if (mounted) await _load();
  }

  Widget _twoButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn(String label, IconData icon, Color color, VoidCallback onTap) =>
        Expanded(
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 48,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 19, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
            ),
          ),
        );

    return Row(children: [
      btn(tr('صرفت', 'Spent'), Icons.remove, scheme.error, _addExpense),
      const SizedBox(width: 11),
      btn(tr('قبضت', 'Received'), Icons.add, const Color(0xFF10B981),
          _addIncome),
    ]);
  }

  /// **زرار «اللى ثابت كل شهر»** — بنفس شكل زرارى السجل.
  ///
  /// كان ٣ سطور فى آخر الصفحة بتقول الإجمالى من غير ما تقول جاى منين
  /// ولا رايح فين. بقى سطر واحد بالرقم المهم (بيفضل كام)، والصفحة
  /// جوّاه فيها البنود نفسها.
  Widget _fixedButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final income = _monthlyIncome + _certInterest;
    final left = income - _monthlyBills;
    const teal = Color(0xFF14B8A6);
    final has = income > 0 || _monthlyBills > 0;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openFixedMonthly,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.event_repeat, size: 20, color: teal),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('اللى ثابت كل شهر', 'Every month'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        has
                            ? tr(
                                'بيجيلك ${arMoney(income.round())} · بيروح ${arMoney(_monthlyBills.round())}',
                                'in ${arMoney(income.round())} · out ${arMoney(_monthlyBills.round())}')
                            : tr('ضيف دخلك الثابت وفواتيرك',
                                'Add your income and bills'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5, color: scheme.onSurfaceVariant)),
                  ]),
            ),
            const SizedBox(width: 8),
            if (has)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(arMoney(left.round()),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: left >= 0 ? teal : scheme.error)),
                Text(tr('بيفضل', 'left'),
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant)),
              ]),
            Icon(Icons.chevron_left, size: 19, color: scheme.outline),
          ]),
        ),
      ),
    );
  }

  Future<void> _openFixedMonthly() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FixedMonthlyScreen()));
    if (mounted) await _load();
  }
}
