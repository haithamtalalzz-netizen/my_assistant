import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/bills_repo.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../data/wallets_repo.dart';
import '../../data/wealth_history.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/bar_actions.dart';
import '../../widgets/history_calendar.dart';
import '../../widgets/search_action.dart';
import 'fixed_bills_screen.dart';
import 'income_sheet.dart';
import 'quick_expense_sheet.dart';
import 'recurring_income_screen.dart';
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

/// مدى «صرفت إيه» — اليوم هو الافتراضى.
enum _Range { day, month, year, custom }

class _MoneyScreenState extends State<MoneyScreen> {
  final _money = MoneyRepo();
  final _wallets = WalletsRepo();
  final _bills = BillsRepo();
  final _income = IncomeRepo();

  bool _loading = true;

  List<({Wallet wallet, double balance})> _list = [];
  double _total = 0;

  _Range _range = _Range.day;
  late DateTime _from;
  late DateTime _to;
  double _spent = 0;
  int _spentCount = 0;

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
      _certInterest = cert;
      _monthlyIncome = recurring.fold<double>(0, (s, e) => s + e.amount);
      _monthlyBills = bills.fold<double>(0, (s, e) => s + e.amount);
      _loading = false;
    });
  }

  // ———————————————————— المدى ————————————————————

  String get _rangeLabel => switch (_range) {
        _Range.day => _isToday(_from)
            ? tr('النهاردة', 'Today')
            : arShortDate(_from),
        _Range.month => arMonth(_from),
        _Range.year => arNum(_from.year),
        _Range.custom =>
          tr('${arShortDate(_from)} ← ${arShortDate(_to)}',
              '${arShortDate(_from)} → ${arShortDate(_to)}'),
      };

  String get _spentTitle => switch (_range) {
        _Range.day => _isToday(_from)
            ? tr('صرفت إيه النهاردة؟', 'Spent today?')
            : tr('صرفت إيه يوم ${arShortDate(_from)}؟',
                'Spent on ${arShortDate(_from)}?'),
        _Range.month => tr('صرفت إيه الشهر ده؟', 'Spent this month?'),
        _Range.year => tr('صرفت إيه السنة دى؟', 'Spent this year?'),
        _Range.custom => tr('صرفت إيه فى الفترة دى؟', 'Spent in this range?'),
      };

  bool _isToday(DateTime d) =>
      dateOnly(d) == dateOnly(DateTime.now());

  Future<void> _pickRange() async {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(children: [
              Icon(Icons.calendar_month, color: scheme.primary, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(tr('تشوف مصاريف إيه؟', 'Which period?'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          for (final o in [
            ('day', tr('يوم واحد', 'A single day'), Icons.today),
            ('month', tr('شهر', 'A month'), Icons.calendar_view_month),
            ('year', tr('سنة', 'A year'), Icons.event_note),
            ('custom', tr('فترة من … إلى', 'From … to'), Icons.date_range),
          ])
            ListTile(
              leading: Icon(o.$3, color: scheme.primary),
              title: Text(o.$2),
              onTap: () => Navigator.pop(ctx, o.$1),
            ),
          const SizedBox(height: 6),
        ]),
      ),
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case 'day':
        final d = await showDatePicker(
          context: context,
          initialDate: _from,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
        );
        if (d == null) return;
        _range = _Range.day;
        _from = dateOnly(d);
        _to = _from;
      case 'month':
        final d = await showDatePicker(
          context: context,
          initialDate: _from,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: tr('اختار أى يوم فى الشهر', 'Pick any day in the month'),
        );
        if (d == null) return;
        _range = _Range.month;
        _from = DateTime(d.year, d.month, 1);
        _to = DateTime(d.year, d.month + 1, 0);
      case 'year':
        final d = await showDatePicker(
          context: context,
          initialDate: _from,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: tr('اختار أى يوم فى السنة', 'Pick any day in the year'),
        );
        if (d == null) return;
        _range = _Range.year;
        _from = DateTime(d.year, 1, 1);
        _to = DateTime(d.year, 12, 31);
      case 'custom':
        final r = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(start: _from, end: _to),
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
        );
        if (r == null) return;
        _range = _Range.custom;
        _from = dateOnly(r.start);
        _to = dateOnly(r.end);
    }
    if (mounted) await _load();
  }

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
    final ok = await showQuickExpenseSheet(context);
    if (ok == true && mounted) await _load();
  }

  Future<void> _addIncome() async {
    final ok = await showIncomeSheet(context);
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
                  const SizedBox(height: 14),
                  ..._walletGrid(context),
                  const SizedBox(height: 18),
                  _spentCard(context),
                  const SizedBox(height: 12),
                  _twoButtons(context),
                  _fixedMonthly(context),
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

  /// المحافظ مربعات، اتنين فى الصف، وآخر مربّع «＋ محفظة جديدة».
  List<Widget> _walletGrid(BuildContext context) {
    final cells = <Widget>[
      for (final e in _list) _walletTile(context, e.wallet, e.balance),
      _addTile(context),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < cells.length ? 10 : 0),
        // IntrinsicHeight: من غيره الصف بيوسّط، فالمربّع القصير يطلع
        // مش مظبوط مع اللى جنبه.
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: cells[i]),
            const SizedBox(width: 10),
            Expanded(
                child: i + 1 < cells.length
                    ? cells[i + 1]
                    : const SizedBox.shrink()),
          ]),
        ),
      ));
    }
    return rows;
  }

  Widget _walletTile(BuildContext context, Wallet w, double balance) {
    final c = walletTypeColor(w.type);
    return Material(
      color: Color.alphaBlend(
          c.withValues(alpha: 0.10), Theme.of(context).colorScheme.surface),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openWallets,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withValues(alpha: 0.25)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(walletTypeIcon(w.type), size: 16, color: c),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(w.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(arMoney(balance.round()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: c)),
          ]),
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openWallets,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(children: [
            Icon(Icons.add_circle_outline, size: 19, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  _list.isEmpty
                      ? tr('ضيف أول محفظة', 'Add your first wallet')
                      : tr('محفظة جديدة', 'New wallet'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
            ),
          ]),
        ),
      ),
    );
  }

  /// «صرفت إيه …؟» — الضغط بيفتح اختيار المدى.
  Widget _spentCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickRange,
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
                  color: scheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.trending_down, size: 20, color: scheme.error),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_spentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        _spentCount == 0
                            ? tr('مفيش حركات · دوس تختار يوم أو شهر أو فترة',
                                'Nothing yet · tap to pick a period')
                            : tr(
                                '${arNum(_spentCount)} حركة · دوس تختار يوم أو شهر أو فترة',
                                '${arNum(_spentCount)} entries · tap to pick a period'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5, color: scheme.onSurfaceVariant)),
                  ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(arMoney(_spent.round()),
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: scheme.error)),
              Row(children: [
                Icon(Icons.calendar_month,
                    size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(_rangeLabel,
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant)),
              ]),
            ]),
          ]),
        ),
      ),
    );
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

  /// اللى ثابت كل شهر — دخلك · فواتير ثابتة · الفاضل بعدهم.
  ///
  /// التلاتة محسوبين من بياناتك مش مكتوبين بالإيد: الدخل من الدخل
  /// المتكرّر، والفواتير من الفواتير الثابتة، والفاضل هو الفرق.
  Widget _fixedMonthly(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // عائد الشهادات دخل ثابت زى المرتب — محسوب عندك بالفعل.
    final income = _monthlyIncome + _certInterest;
    final left = income - _monthlyBills;
    if (income == 0 && _monthlyBills == 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppGroupHead(tr('اللى ثابت كل شهر', 'Every month')),
        AppListRow(
          title: tr('ضيف دخلك الثابت', 'Add your recurring income'),
          sub: tr('عشان تعرف بيفضل معاك كام كل شهر',
              'So you know what is left each month'),
          icon: Icons.payments,
          tint: const Color(0xFF10B981),
          chevron: true,
          onTap: _openRecurringIncome,
        ),
        AppListRow(
          title: tr('ضيف فواتيرك الثابتة', 'Add your fixed bills'),
          sub: tr('كهربا · نت · مدرسة', 'Electricity · internet · school'),
          icon: Icons.receipt_long,
          tint: const Color(0xFFF59E0B),
          chevron: true,
          divider: false,
          onTap: _openBills,
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppGroupHead(tr('اللى ثابت كل شهر', 'Every month')),
      AppListRow(
        title: tr('دخلك', 'Income'),
        sub: tr('الدخل المتكرّر', 'Recurring income'),
        icon: Icons.payments,
        tint: const Color(0xFF10B981),
        chevron: true,
        onTap: _openRecurringIncome,
        trailing: Text(arMoney(_monthlyIncome.round()),
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10B981))),
      ),
      if (_certInterest > 0)
        AppListRow(
          title: tr('عائد الشهادات', 'Certificate interest'),
          sub: tr('بيجيلك كل شهر من البنك', 'From the bank every month'),
          icon: Icons.account_balance,
          tint: const Color(0xFF14B8A6),
          chevron: true,
          onTap: _openWallets,
          trailing: Text(arMoney(_certInterest.round()),
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14B8A6))),
        ),
      AppListRow(
        title: tr('فواتير ثابتة', 'Fixed bills'),
        sub: tr('اللى بيتدفع كل شهر', 'Paid every month'),
        icon: Icons.receipt_long,
        tint: const Color(0xFFF59E0B),
        chevron: true,
        onTap: _openBills,
        trailing: Text(arMoney(_monthlyBills.round()),
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF59E0B))),
      ),
      AppListRow(
        title: tr('الفاضل بعدهم', 'Left after them'),
        sub: tr('دخلك (بالعائد) ناقص فواتيرك',
            'Income (incl. interest) minus bills'),
        icon: Icons.savings,
        tint: left >= 0 ? const Color(0xFF14B8A6) : scheme.error,
        divider: false,
        trailing: Text(arMoney(left.round()),
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: left >= 0 ? const Color(0xFF14B8A6) : scheme.error)),
      ),
    ]);
  }

  Future<void> _openRecurringIncome() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RecurringIncomeScreen()));
    if (mounted) await _load();
  }

  Future<void> _openBills() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FixedBillsScreen()));
    if (mounted) await _load();
  }
}
