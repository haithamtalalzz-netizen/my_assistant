import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/bar_actions.dart';
import '../../widgets/search_action.dart';
import '../../core/month_summary.dart';
import '../../core/money_export.dart';
import '../../core/money_trends.dart';
import '../../core/budget_calc.dart';
import '../../data/bills_repo.dart';
import '../../data/debts_repo.dart';
import '../../data/gameya_repo.dart';
import '../../data/home_maintenance_repo.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../data/savings_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/history_calendar.dart';
import '../baladna/debts_screen.dart';
import '../baladna/gameya_screen.dart';
import '../baladna/home_maintenance_screen.dart';
import '../baladna/savings_screen.dart';
import 'income_sheet.dart';
import 'quick_expense_sheet.dart';
import 'wallets_screen.dart';
import '../../core/calendar_sync.dart';

class MoneyScreen extends StatefulWidget {
  final Widget? drawer;

  const MoneyScreen({super.key, this.drawer});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _repo = MoneyRepo();
  final _settings = SettingsRepo();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  List<Expense> _expenses = [];
  Map<String, double> _byCategory = {};
  Map<String, double> _categoryBudgets = {};
  List<RecurringBill> _bills = [];
  List<Income> _income = [];
  List<RecurringIncome> _recurringIncome = [];
  double _total = 0;
  double _incomeTotal = 0;
  double _budget = 0;
  double _debtNet = 0;

  /// أرقام بنود «بلدنا» — كارت بيقول «افتح» بس مساحة ضايعة.
  double _savedTotal = 0;
  int _gameyaCount = 0;
  int _maintenanceDue = 0;

  /// مقارنة بالشهر اللى فات + اتجاه آخر ٦ شهور.
  double _prevTotal = 0;
  double _prevIncome = 0;
  List<(String, double)> _sixMonths = [];

  /// مقارنة كل فئة + تدفّق الشهور (للرصيد التراكمى).
  List<CategoryDelta> _deltas = [];
  List<MonthFlow> _flow = [];

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _repo.forMonth(_month.year, _month.month);
    final byCat = await _repo.byCategory(_month.year, _month.month);
    final total = await _repo.totalForMonth(_month.year, _month.month);
    final budget = await _settings.monthlyBudget();
    final catBudgets = await _settings.categoryBudgets();
    final bills = await BillsRepo().all();
    final now = DateTime.now();
    bills.sort((a, b) {
      final ad = a.isDue(now), bd = b.isDue(now);
      if (ad != bd) return ad ? -1 : 1; // المستحقة الأول
      return a.dayOfMonth.compareTo(b.dayOfMonth);
    });
    final (owedToMe, iOwe) = await DebtsRepo().totals();
    final incomeRepo = IncomeRepo();
    final income = await incomeRepo.forMonth(_month.year, _month.month);
    final incomeTotal =
        await incomeRepo.totalForMonth(_month.year, _month.month);
    final recurringIncome = await incomeRepo.allRecurring();
    // الشهر السابق + آخر ٦ شهور (للمقارنة والاتجاه).
    final prev = DateTime(_month.year, _month.month - 1);
    final prevTotal = await _repo.totalForMonth(prev.year, prev.month);
    final prevIncome = await incomeRepo.totalForMonth(prev.year, prev.month);
    final six = <(String, double)>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(_month.year, _month.month - i);
      six.add((
        arMonthShort(m),
        await _repo.totalForMonth(m.year, m.month),
      ));
    }
    final goals = await SavingsRepo().all();
    final savedTotal = goals.fold<double>(0, (t, g) => t + g.saved);
    final gameyas = await GameyaRepo().all();
    final maintenanceDue = (await HomeMaintenanceRepo().due(now)).length;
    final deltas = await MoneyTrends.categoryDeltas(_month.year, _month.month);
    final flow = await MoneyTrends.monthlyFlow(_month.year, _month.month);
    if (!mounted) return;
    setState(() {
      _deltas = deltas;
      _flow = flow;
      _savedTotal = savedTotal;
      _gameyaCount = gameyas.length;
      _maintenanceDue = maintenanceDue;
      _expenses = expenses;
      _byCategory = byCat;
      _categoryBudgets = catBudgets;
      _total = total;
      _budget = budget;
      _bills = bills;
      _income = income;
      _incomeTotal = incomeTotal;
      _recurringIncome = recurringIncome;
      _debtNet = owedToMe - iOwe;
      _prevTotal = prevTotal;
      _prevIncome = prevIncome;
      _sixMonths = six;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  Future<void> _editBudget() async {
    final controller =
        TextEditingController(text: _budget > 0 ? _budget.toStringAsFixed(0) : '');
    final suggested = await MonthSummary.suggestedBudget();
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(tr('ميزانية الشهر', 'Monthly budget')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
            ),
            if (suggested != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () =>
                      controller.text = suggested.round().toString(),
                  child: Text(tr(
                      'اقتراح من متوسط آخر شهور: ${egp(suggested)} — استخدمه',
                      'Suggested from recent months: ${egp(suggested)} — use it')),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    if (saved == true) {
      final value = parseNumber(controller.text);
      await _settings.set(
          'monthly_budget', value == null || value <= 0 ? '' : '$value');
      if (mounted) await _load();
    }
    controller.dispose();
  }

  Future<void> _addExpense() async {
    final added = await showQuickExpenseSheet(context);
    if (added == true && mounted) await _load();
  }

  /// تقويم/سجل الفلوس — ترجع للأيام الماضية تشوف صرفت وقبضت كام.
  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryCalendar(
          title: tr('سجل الفلوس', 'Money history'),
          accent: Colors.green,
          activeDays: (y, m) => _repo.activeDaysInMonth(y, m),
          dayReport: (day) async {
            final r = await _repo.dayReport(dayKey(day));
            return [
              if (r.income > 0)
                HistoryRow('💰', tr('دخل', 'Income'), egp(r.income)),
              HistoryRow('🧾', tr('مصروف', 'Spent'), egp(r.spent)),
              if (r.expenseCount > 0)
                HistoryRow('🔢', tr('عدد المصاريف', 'Expenses'),
                    arNum(r.expenseCount)),
              if (r.income > 0 || r.spent > 0)
                HistoryRow('⚖️', tr('صافى اليوم', 'Net'),
                    egp(r.income - r.spent)),
              for (final e in r.byCategory.entries)
                HistoryRow('•', expenseCategoryLabel(e.key), egp(e.value)),
            ];
          },
        ),
      ),
    );
  }

  /// صوّر الفاتورة → OCR محلي → شيت المصروف متملي بالإجمالي.
  Future<void> _delete(Expense e) async {
    if (!await confirmDelete(
        context, tr('المصروف ده (${egp(e.amount)})', 'this expense (${egp(e.amount)})'))) {
      return;
    }
    await _repo.delete(e.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('المحفظة', 'Wallet')),
        actions: barActions(context, [
          BarAction(Icons.search, tr('بحث', 'Search'),
              () => openSearch(context)),
          BarAction(Icons.calendar_month_outlined,
              tr('سجل الفلوس', 'Money history'), _openHistory),
          BarAction(Icons.account_balance_wallet_outlined,
              tr('المحافظ', 'Wallets'), () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletsScreen()));
            if (mounted) await _load();
          }),
          BarAction(Icons.file_download_outlined,
              tr('تصدير Excel', 'Export Excel'), () async {
            await MoneyExport.exportMonthCsv(_month.year, _month.month);
          }),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  _monthNav(context),
                  const SizedBox(height: 8),
                  _netCard(context),
                  _safeToSpendLine(context),
                  const SizedBox(height: 14),
                  _hubGrid(context),
                  const SizedBox(height: 18),
                  _recentSection(context),
                ],
              ),
            ),
      floatingActionButton: _isCurrentMonth
          ? FloatingActionButton(
              heroTag: 'money_fab',
              onPressed: _addExpense,
              tooltip: tr('سجل مصروف', 'Log expense'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// **شبكة البنود** — الرئيسية بقت تقعد فى شاشة واحدة، وكل بند صفحة
  /// لوحده. قبل كده كانت الصفحة فيها ٧ كروت تحليل فوق بعض و٥ أقسام
  /// تحتهم، فالمصاريف (أكتر حاجة بتتسجّل) كانت **آخر حاجة فى الصفحة**.
  Widget _hubGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fixedTotal = _bills.fold<double>(0, (t, b) => t + b.amount);
    final items = <_Hub>[
      _Hub(tr('المصاريف', 'Expenses'), egp(_total),
          Icons.receipt_long_outlined, scheme.error, _openExpenses),
      _Hub(tr('الدخل', 'Income'), egp(_incomeTotal), Icons.south_west,
          Colors.green, _openIncome),
      _Hub(tr('الثابت والفواتير', 'Fixed & bills'), egp(fixedTotal),
          Icons.repeat, scheme.primary, _openFixed),
      _Hub(tr('التحليل', 'Analysis'), tr('راحت فين؟', 'Where did it go?'),
          Icons.insights_outlined, const Color(0xFFA855F7), _openAnalysis),
      _Hub(
          tr('الديون', 'Debts'),
          _debtNet == 0
              ? tr('متعادل', 'Even')
              : (_debtNet > 0
                  ? tr('ليك ${egp(_debtNet)}', 'owed ${egp(_debtNet)}')
                  : tr('عليك ${egp(-_debtNet)}', 'you owe ${egp(-_debtNet)}')),
          Icons.handshake_outlined,
          const Color(0xFFF59E0B),
          () => _push(const DebtsScreen())),
      _Hub(
          tr('الجمعيات', 'Savings circles'),
          _gameyaCount == 0
              ? tr('مفيش', 'None')
              : tr('${arNum(_gameyaCount)} جمعية',
                  '${arNum(_gameyaCount)} circles'),
          Icons.groups_2_outlined,
          const Color(0xFF0EA5E9),
          () => _push(const GameyaScreen())),
      _Hub(
          tr('الادخار', 'Savings'),
          _savedTotal == 0 ? tr('ابدأ هدف', 'Start a goal') : egp(_savedTotal),
          Icons.savings_outlined,
          const Color(0xFF14B8A6),
          () => _push(const SavingsScreen())),
      _Hub(
          tr('صيانة البيت', 'Home upkeep'),
          _maintenanceDue == 0
              ? tr('مفيش مستحق', 'Nothing due')
              : tr('${arNum(_maintenanceDue)} مستحقة',
                  '${arNum(_maintenanceDue)} due'),
          Icons.home_repair_service_outlined,
          const Color(0xFF8B5CF6),
          () => _push(const HomeMaintenanceScreen())),
    ];
    return LayoutBuilder(builder: (context, box) {
      // ٣ أعمدة على التابلت — الكارت مايبقاش عريض فاضى.
      final cols = box.maxWidth >= 620 ? 3 : 2;
      final w = (box.maxWidth - 11 * (cols - 1)) / cols;
      return Wrap(
        spacing: 11,
        runSpacing: 11,
        children: [
          for (final h in items)
            SizedBox(width: w, child: _hubCard(context, h)),
        ],
      );
    });
  }

  Widget _hubCard(BuildContext context, _Hub h) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: h.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 104,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: h.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(h.icon, size: 19, color: h.color),
              ),
              const Spacer(),
              Text(h.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(h.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) => _reloadAfter(
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)));

  Future<void> _reloadAfter(Future<void> Function() action) async {
    await action();
    if (mounted) await _load();
  }

  /// بيفتح قسم كصفحة كاملة. الصفحة بتبنى محتواها من **نفس** دوال الكروت
  /// اللى فى الشاشة دى، فمفيش تكرار ولا تحميل تانى للبيانات.
  void _openSection(String title, List<Widget> Function(String filter) body,
      {List<String> filters = const [],
      String? addLabel,
      Future<void> Function()? onAdd}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MoneySectionPage(
          title: title,
          body: body,
          filters: filters,
          onRefresh: _load,
          addLabel: addLabel,
          onAdd: onAdd,
        ),
      ),
    );
  }

  /// **المصاريف — الفئات أولاً** (الشكل اللى اختاره).
  ///
  /// بتجاوب «راحت فين؟» من نظرة بدل ما تدوّر فى قايمة طويلة: كل فئة
  /// بمبلغها ونسبتها، والضغط عليها بيفتح عملياتها. كروت التحليل اتشالت
  /// من هنا خالص — مكانها بند «التحليل».
  void _openExpenses() => _openSection(tr('المصاريف', 'Expenses'), (_) {
        final cats = _byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return [
          _spentHeader(context),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text(tr('راحت فين؟', 'Where did it go?'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700))),
            TextButton(
                onPressed: _openAllExpenses,
                child: Text(tr('كل العمليات', 'All'))),
          ]),
          if (cats.isEmpty)
            EmptyHint(
                icon: Icons.receipt_long_outlined,
                text: tr('مفيش مصاريف متسجلة الشهر ده',
                    'No expenses logged this month'))
          else ...[
            for (final c in cats) _categoryRow(context, c.key, c.value),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _editCategoryBudgets,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(tr('ميزانيات الفئات', 'Category budgets')),
              ),
            ),
          ],
        ];
      }, addLabel: tr('سجل مصروف', 'Log expense'), onAdd: _addExpense);

  /// رأس «صرفت الشهر ده» + شريط الميزانية (لو محدَّدة).
  Widget _spentHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('صرفت الشهر ده', 'Spent this month'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(egp(_total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: scheme.error)),
          ]),
        ),
        if (_budget > 0) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(tr('من ${egp(_budget)}', 'of ${egp(_budget)}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: (_total / _budget).clamp(0, 1).toDouble(),
                    minHeight: 7),
              ),
            ]),
          ),
        ] else
          TextButton(
              onPressed: _editBudget,
              child: Text(tr('حدد ميزانية', 'Set a budget'))),
      ]),
    );
  }

  /// صفّ فئة: المبلغ + النسبة + شريط — والضغط بيفتح عملياتها.
  Widget _categoryRow(BuildContext context, String cat, double amount) {
    final scheme = Theme.of(context).colorScheme;
    final color = expenseCategoryColor(cat);
    final pct = _total <= 0 ? 0.0 : amount / _total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openCategory(cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(expenseCategoryIcon(cat), size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(expenseCategoryLabel(cat),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5))),
                        const SizedBox(width: 8),
                        Text(egp(amount),
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            color: color,
                            backgroundColor: color.withValues(alpha: 0.13)),
                      ),
                    ]),
              ),
              const SizedBox(width: 10),
              Text('${arNum((pct * 100).round())}٪',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }

  void _openCategory(String cat) {
    final rows = [
      for (final e in _expenses)
        if (e.category == cat) e
    ];
    _openSection(expenseCategoryLabel(cat), (_) => [
          _sumStrip(context, egp(rows.fold<double>(0, (t, e) => t + e.amount)),
              tr('${arNum(rows.length)} عملية', '${arNum(rows.length)} items')),
          const SizedBox(height: 10),
          ...rows.map((e) => _expenseTile(context, e)),
        ], addLabel: tr('سجل مصروف', 'Log expense'), onAdd: _addExpense);
  }

  void _openAllExpenses() =>
      _openSection(tr('كل العمليات', 'All expenses'), (_) => [
            _sumStrip(context, egp(_total),
                tr('${arNum(_expenses.length)} عملية',
                    '${arNum(_expenses.length)} items')),
            const SizedBox(height: 10),
            ..._expenses.map((e) => _expenseTile(context, e)),
          ], addLabel: tr('سجل مصروف', 'Log expense'), onAdd: _addExpense);

  /// شريط مجموع بسيط فوق أى قايمة.
  Widget _sumStrip(BuildContext context, String total, String count) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
            child: Text(count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant))),
        const SizedBox(width: 8),
        Text(total,
            maxLines: 1,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  /// **الدخل — قايمة بسيطة بفلاتر** (الشكل اللى اختاره).
  /// «ثابت» شريحة زى أى فلتر، فالدخل الدورى مالوش قسم منفصل يزحم الشاشة.
  void _openIncome() {
    final sources = <String>{for (final i in _income) i.source}.toList();
    _openSection(tr('الدخل', 'Income'), (f) {
      if (f == tr('ثابت', 'Recurring')) {
        return [
          _sumStrip(
              context,
              egp(_recurringIncome.fold<double>(0, (t, i) => t + i.amount)),
              tr('${arNum(_recurringIncome.length)} دخل شهرى',
                  '${arNum(_recurringIncome.length)} monthly')),
          const SizedBox(height: 10),
          if (_recurringIncome.isEmpty)
            EmptyHint(
                icon: Icons.event_repeat,
                text: tr('سجّل مرتبك مرة واحدة — وهفكرك يوم القبض',
                    'Log your salary once — reminded on payday'),
                actionLabel: tr('ضيف دخل ثابت', 'Add'),
                onAction: () => _recurringIncomeForm())
          else
            ..._recurringIncome.map((i) => _recurringIncomeTile(context, i)),
        ];
      }
      final rows = [
        for (final i in _income)
          if (f == tr('الكل', 'All') || i.source == f) i
      ];
      return [
        _sumStrip(
            context,
            egp(rows.fold<double>(0, (t, i) => t + i.amount)),
            tr('${arNum(rows.length)} عملية', '${arNum(rows.length)} items')),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          EmptyHint(
              icon: Icons.south_west,
              text: tr('مفيش دخل متسجل', 'No income logged'))
        else
          ...rows.map((i) => _incomeTile(context, i)),
      ];
    },
        filters: [
          tr('الكل', 'All'),
          tr('ثابت', 'Recurring'),
          for (final s in sources) incomeSourceLabel(s),
        ],
        addLabel: tr('سجل دخل', 'Log income'),
        onAdd: _addIncome);
  }

  /// **الثابت والفواتير — قايمة بسيطة بفلاتر** (الشكل اللى اختاره).
  void _openFixed() {
    final now = DateTime.now();
    _openSection(tr('الثابت والفواتير', 'Fixed & bills'), (f) {
      final rows = [
        for (final b in _bills)
          if (f == tr('مستحقة', 'Due')
              ? b.isDue(now)
              : f == tr('اتدفعت', 'Paid')
                  ? !b.isDue(now)
                  : true)
            b
      ];
      return [
        _sumStrip(
            context,
            egp(rows.fold<double>(0, (t, b) => t + b.amount)),
            tr('${arNum(rows.length)} فاتورة', '${arNum(rows.length)} bills')),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          EmptyHint(
              icon: Icons.repeat,
              text: tr('سجل الكهربا والنت والاشتراكات مرة واحدة — وهفكرك كل شهر',
                  'Log electricity, internet & subscriptions once'))
        else
          ...rows.map((b) => _billTile(context, b)),
      ];
    },
        filters: [
          tr('الكل', 'All'),
          tr('مستحقة', 'Due'),
          tr('اتدفعت', 'Paid'),
        ],
        addLabel: tr('ضيف فاتورة', 'Add bill'),
        onAdd: () => _billForm());
  }

  void _openAnalysis() => _openSection(tr('التحليل', 'Analysis'), (_) => [
        // الكارت الكامل مكانه هنا؛ الرئيسية فيها السطر المختصر بس.
        _safeToSpendCard(context),
        _compareCard(context),
        const SizedBox(height: 8),
        _categoryDeltaCard(context),
        const SizedBox(height: 8),
        _balanceTrendCard(context),
        const SizedBox(height: 8),
        _whereCard(context),
        const SizedBox(height: 8),
        _billsProjectionCard(context),
      ]);

  /// **آخر العمليات** — دخل ومصروف مخلوطين بالتاريخ، زى ما بتشوفهم فى
  /// الحقيقة. قبل كده كانوا فى قسمين متباعدين فى نفس الصفحة الطويلة.
  Widget _recentSection(BuildContext context) {
    final rows = <(String, Widget)>[
      for (final e in _expenses) (e.day, _expenseTile(context, e)),
      for (final i in _income) (i.day, _incomeTile(context, i)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(tr('آخر العمليات', 'Recent'),
          trailing: TextButton(
              onPressed: _openExpenses, child: Text(tr('الكل', 'All')))),
      if (rows.isEmpty)
        EmptyHint(
            icon: Icons.receipt_long_outlined,
            text: tr('مفيش عمليات الشهر ده', 'Nothing logged this month'))
      else
        ...rows.take(5).map((r) => r.$2),
    ]);
  }

  Widget _monthNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () => _shiftMonth(-1),
            tooltip: tr('الشهر اللي فات', 'Previous month'),
            icon: const Icon(Icons.chevron_right)),
        SizedBox(
          width: 160,
          child: Text(arMonth(_month),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        IconButton(
            onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
            tooltip: tr('الشهر اللي جاي', 'Next month'),
            icon: const Icon(Icons.chevron_left)),
      ],
    );
  }

  /// مقارنة بالشهر اللى فات + شريط اتجاه آخر ٦ شهور.
  Widget _compareCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diff = _total - _prevTotal;
    final pct = _prevTotal <= 0 ? null : (diff / _prevTotal * 100);
    final up = diff > 0; // صرف أكتر = وحش (أحمر)
    final maxSpend = _sixMonths.fold<double>(
        1, (m, e) => e.$2 > m ? e.$2 : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('مقارنة بالشهر اللى فات', 'vs last month'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (_prevTotal > 0 || _total > 0)
                  Text(
                    pct == null
                        ? '—'
                        : '${up ? '▲' : '▼'} ${arNum(pct.abs().round())}٪',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: up ? scheme.error : Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                  'مصروف الشهر ده ${egp(_total)} — الشهر اللى فات ${egp(_prevTotal)}'
                  '${_prevIncome > 0 ? ' (دخله ${egp(_prevIncome)})' : ''}',
                  'This month ${egp(_total)} — last month ${egp(_prevTotal)}'
                  '${_prevIncome > 0 ? ' (income ${egp(_prevIncome)})' : ''}'),
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
            const SizedBox(height: 10),
            // شريط آخر ٦ شهور — أعمدة نسبية بسيطة.
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (label, v) in _sixMonths)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: maxSpend <= 0
                                  ? 2
                                  : (44 * (v / maxSpend)).clamp(2, 44),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(
                                    alpha: v == _total &&
                                            label == _sixMonths.last.$1
                                        ? 0.9
                                        : 0.45),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 10, color: scheme.outline)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «إيه اللى اتغيّر؟» — الفئات مرتّبة بأكبر فرق عن الشهر اللى فات.
  Widget _categoryDeltaCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // بنعرض اللى اتغير فعلًا بس (فرق ≥ ١ جنيه) — الباقى ضوضاء.
    final shown = [for (final d in _deltas) if (d.diff.abs() >= 1) d].take(5);
    if (shown.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🔀', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('إيه اللى اتغيّر عن الشهر اللى فات؟',
                    'What changed vs last month?'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 10),
            for (final d in shown) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Icon(d.diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: d.diff > 0 ? scheme.error : Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(expenseCategoryLabel(d.category),
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    d.isNew
                        ? tr('جديد', 'new')
                        : d.stopped
                            ? tr('وقف', 'stopped')
                            : d.percent == null
                                ? '—'
                                : '${arNum(d.percent!.abs().round())}٪',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${d.diff > 0 ? '+' : '−'}${egp(d.diff.abs())}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: d.diff > 0 ? scheme.error : Colors.green),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ترند الرصيد: الصافى التراكمى عبر آخر ٦ شهور — بيوضّح لو بتاكل من رصيدك.
  Widget _balanceTrendCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_flow.isEmpty) return const SizedBox.shrink();
    final cum = MoneyTrends.cumulativeNet(_flow);
    final hasData = _flow.any((f) => f.income > 0 || f.spent > 0);
    if (!hasData) return const SizedBox.shrink();
    final maxAbs = cum.fold<double>(1, (m, v) => v.abs() > m ? v.abs() : m);
    final last = cum.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('📈', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('ترند الرصيد (صافى تراكمى)',
                    'Balance trend (cumulative net)'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text(egp(last),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: last >= 0 ? Colors.green : scheme.error)),
            ]),
            const SizedBox(height: 4),
            Text(
              last >= 0
                  ? tr('بتوفّر على مدى الشهور دى.', 'You are net positive.')
                  : tr('بتاكل من رصيدك على مدى الشهور دى.',
                      'You are running a deficit over these months.'),
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            const SizedBox(height: 10),
            // أعمدة فوق/تحت خط الصفر.
            SizedBox(
              height: 76,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < _flow.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // النص العلوى = العمود الموجب.
                            SizedBox(
                              height: 28,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: cum[i] > 0
                                      ? (26 * (cum[i] / maxAbs)).clamp(2, 26)
                                      : 0,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.7),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3)),
                                  ),
                                ),
                              ),
                            ),
                            Container(height: 1, color: scheme.outlineVariant),
                            SizedBox(
                              height: 28,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: cum[i] < 0
                                      ? (26 * (cum[i].abs() / maxAbs))
                                          .clamp(2, 26)
                                      : 0,
                                  decoration: BoxDecoration(
                                    color: scheme.error.withValues(alpha: 0.7),
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_flow[i].label,
                                  style: TextStyle(
                                      fontSize: 10, color: scheme.outline)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «فين فلوسى؟» — تدفّق مبسّط: الدخل ← الفئات بعرض متناسب مع نصيبها.
  /// (Sankey حقيقى محتاج مكتبة؛ ده بيوصّل نفس المعنى بويدجتس عادية.)
  Widget _whereCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_byCategory.isEmpty || _total <= 0) return const SizedBox.shrink();
    final entries = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final rest = entries.skip(6).fold<double>(0, (s, e) => s + e.value);
    final base = _incomeTotal > 0 ? _incomeTotal : _total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🔎', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('فين فلوسى؟', 'Where did my money go?'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              _incomeTotal > 0
                  ? tr('من ${egp(_incomeTotal)} دخل، اتصرف ${egp(_total)}',
                      'Of ${egp(_incomeTotal)} income, ${egp(_total)} spent')
                  : tr('إجمالى المصروف ${egp(_total)}',
                      'Total spent ${egp(_total)}'),
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            const SizedBox(height: 10),
            for (final e in top) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  SizedBox(
                    width: 74,
                    child: Text(expenseCategoryLabel(e.key),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (e.value / base).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 78,
                    child: Text(egp(e.value),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 11.5)),
                  ),
                ]),
              ),
            ],
            if (rest > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tr('+ ${egp(rest)} فى فئات تانية', '+ ${egp(rest)} in others'),
                  style: TextStyle(fontSize: 11.5, color: scheme.outline),
                ),
              ),
            if (_incomeTotal > _total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Text('💚', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    tr('فضل ${egp(_incomeTotal - _total)} من دخل الشهر',
                        '${egp(_incomeTotal - _total)} left from this month'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _netCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final net = _incomeTotal - _total;
    final savingsRate =
        _incomeTotal > 0 ? (net / _incomeTotal * 100).round() : null;
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: scheme.outline)),
              const SizedBox(height: 2),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                cell(tr('دخل', 'Income'), egp(_incomeTotal), Colors.green),
                cell(tr('مصروف', 'Spent'), egp(_total), scheme.error),
                cell(tr('صافي', 'Net'), egp(net),
                    net >= 0 ? scheme.primary : scheme.error),
              ],
            ),
            if (savingsRate != null) ...[
              const SizedBox(height: 8),
              Text(
                  net >= 0
                      ? tr('وفّرت ٪${arNum(savingsRate)} من دخلك الشهر ده',
                          'You saved ${arNum(savingsRate)}% of your income this month')
                      : tr('صرفت أكتر من دخلك بـ ${egp(-net)}',
                          'You spent ${egp(-net)} more than your income'),
                  style: TextStyle(
                      fontSize: 12,
                      color: net >= 0 ? Colors.green : scheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addIncome() async {
    final added = await showIncomeSheet(context);
    if (added == true && mounted) await _load();
  }

  Widget _incomeTile(BuildContext context, Income i) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.south_west, color: Colors.green),
        title: Text(incomeSourceLabel(i.source)),
        subtitle: i.note.isEmpty
            ? Text(arShortDate(DateTime.parse(i.day)))
            : Text('${i.note} • ${arShortDate(DateTime.parse(i.day))}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(egp(i.amount),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: tr('حذف', 'Delete'),
              onPressed: () async {
                await IncomeRepo().delete(i.id!);
                if (mounted) await _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _recurringIncomeTile(BuildContext context, RecurringIncome i) {
    final scheme = Theme.of(context).colorScheme;
    final due = i.isDue(DateTime.now());
    // 🔴 كان ListTile و«قبضته ✓» فى trailing — الـtrailing بياخد العرض
    // الفاضل بعد العنوان، فالزرار كان **بيتقصّ** على شاشة ضيقة. دلوقتى
    // النص Expanded والزرار بياخد مقاسه الطبيعى فمستحيل يتقصّ.
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: due ? scheme.tertiary.withValues(alpha: .13) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(children: [
          Icon(Icons.event_repeat,
              size: 20, color: due ? scheme.tertiary : Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incomeSourceLabel(i.source),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            due ? FontWeight.w700 : FontWeight.w600,
                        color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                    tr('${egp(i.amount)} • يوم ${arNum(i.dayOfMonth)}${due ? ' — قبضته؟' : ''}',
                        '${egp(i.amount)} • day ${arNum(i.dayOfMonth)}${due ? ' — received?' : ''}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
                if (i.note.isNotEmpty)
                  Text(i.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: scheme.outline)),
              ],
            ),
          ),
          if (due)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.tonal(
                onPressed: () async {
                  await IncomeRepo().markReceived(i, now: DateTime.now());
                  if (mounted) await _load();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(tr('قبضته', 'Received'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await _recurringIncomeForm(i);
                case 'delete':
                  if (!await confirmDelete(
                      context,
                      tr('الدخل الدوري "${incomeSourceLabel(i.source)}"',
                          'recurring income "${incomeSourceLabel(i.source)}"'))) {
                    return;
                  }
                  await IncomeRepo().deleteRecurring(i.id!);
                  if (mounted) await _load();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
              PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ]),
      ),
    );
  }

  Future<void> _recurringIncomeForm([RecurringIncome? inc]) async {
    final amount = TextEditingController(
        text: inc == null ? '' : inc.amount.toStringAsFixed(0));
    final note = TextEditingController(text: inc?.note ?? '');
    var source = inc?.source ?? kIncomeSources.first;
    var dayOfMonth = inc?.dayOfMonth ?? 1;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        scrollable: true,
          title: Text(inc == null
              ? tr('دخل دوري جديد', 'New recurring income')
              : tr('تعديل الدخل الدوري', 'Edit recurring income')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in kIncomeSources)
                    ChoiceChip(
                      label: Text(incomeSourceLabel(s)),
                      selected: source == s,
                      onSelected: (_) => setDialogState(() => source = s),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                autofocus: inc == null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr('ملاحظة — الفلوس دى خاصة بإيه؟',
                      'Note — what is this money for?'),
                  hintText: tr('مثلًا: إيجار الشقة', 'e.g. flat rent'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(tr('يوم القبض', 'Payday'))),
                  DropdownButton<int>(
                    value: dayOfMonth,
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text(arNum(d))),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => dayOfMonth = v ?? dayOfMonth),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      final value = parseNumber(amount.text);
      if (value != null && value > 0) {
        await IncomeRepo().saveRecurring(RecurringIncome(
          id: inc?.id,
          note: note.text.trim(),
          source: source,
          amount: value,
          dayOfMonth: dayOfMonth,
          lastReceivedMonth: inc?.lastReceivedMonth ?? '',
        ));
        if (mounted) await _load();
      }
    }
    amount.dispose();
    note.dispose();
  }

  /// «المتاح للصرف النهاردة» — للشهر الحالى فقط، لما فيه ميزانية.
  /// **سطر «تقدر تصرف النهاردة»** فى الرئيسية — سطر واحد مش كارت، عشان
  /// الرئيسية تفضل قصيرة. الكارت الكامل (بالتفاصيل) مكانه «المصاريف».
  /// بيظهر بس لو فيه ميزانية والشهر هو الحالى، وإلا مايشغلش مكان.
  Widget _safeToSpendLine(BuildContext context) {
    final now = DateTime.now();
    if (!_isCurrentMonth || _budget <= 0) return const SizedBox.shrink();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final obligations = _bills
        .where((b) => b.lastPaidMonth != monthKey)
        .fold<double>(0, (s, b) => s + b.amount);
    final r = safeToSpend(
        budget: _budget,
        spent: _total,
        upcomingObligations: obligations,
        now: now);
    final scheme = Theme.of(context).colorScheme;
    final over = r.perDay < 0;
    final color = over ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openExpenses,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Icon(over ? Icons.warning_amber_rounded : Icons.savings_outlined,
                  size: 19, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  over
                      ? tr('عدّيت الميزانية', 'Over budget')
                      : tr('تقدر تصرف النهاردة', 'You can spend today'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              // مدوّر للجنيه: «996.33» رقم يومى بكسور مالهاش معنى عملى.
              Text(egp((over ? -r.perDay : r.perDay).roundToDouble()),
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _safeToSpendCard(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;
    if (!isCurrentMonth || _budget <= 0) return const SizedBox.shrink();

    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final obligations = _bills
        .where((b) => b.lastPaidMonth != monthKey)
        .fold<double>(0, (s, b) => s + b.amount);
    final r = safeToSpend(
        budget: _budget,
        spent: _total,
        upcomingObligations: obligations,
        now: now);
    final scheme = Theme.of(context).colorScheme;
    final over = r.perDay < 0;
    final color = over ? scheme.error : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.savings_outlined, size: 18, color: color),
              const SizedBox(width: 6),
              Text(tr('المتاح للصرف النهاردة', "Safe to spend today"),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(over ? tr('تعدّيت الميزانية', 'Over budget') : egp(r.perDay),
                style: TextStyle(
                    fontSize: 27, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(
              over
                  ? tr('المتبقّى بعد الالتزامات: ${egp(r.remaining)}',
                      'After obligations: ${egp(r.remaining)}')
                  : tr(
                      'المتبقّى ${egp(r.remaining)} على ${arNum(r.daysLeft)} يوم'
                      '${obligations > 0 ? ' · بعد خصم فواتير ${egp(obligations)}' : ''}',
                      'Remaining ${egp(r.remaining)} over ${arNum(r.daysLeft)} days'
                      '${obligations > 0 ? ' · after ${egp(obligations)} bills' : ''}'),
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategoryBudgets() async {
    final controllers = {
      for (final c in kExpenseCategories)
        c: TextEditingController(
            text: (_categoryBudgets[c] ?? 0) > 0
                ? _categoryBudgets[c]!.toStringAsFixed(0)
                : ''),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(tr('ميزانيات الفئات', 'Category budgets')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in kExpenseCategories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(expenseCategoryIcon(c),
                        size: 18, color: expenseCategoryColor(c)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(expenseCategoryLabel(c))),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: controllers[c],
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                            hintText: tr('ج.م', 'EGP'),
                            isDense: true),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );
    if (saved == true) {
      for (final c in kExpenseCategories) {
        await _settings.setCategoryBudget(
            c, parseNumber(controllers[c]!.text) ?? 0);
      }
      if (mounted) await _load();
    }
    for (final ctl in controllers.values) {
      ctl.dispose();
    }
  }

  /// كارت توقّع الالتزامات الشهرية: إجمالى الفواتير الدورية + المتبقى الشهر ده.
  Widget _billsProjectionCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final total = _bills.fold<double>(0, (s, b) => s + b.amount);
    final paid = _bills
        .where((b) => b.lastPaidMonth == monthKey)
        .fold<double>(0, (s, b) => s + b.amount);
    final remaining = total - paid;
    // الفواتير اللى لسه مادفعتش الشهر ده، مرتبة بأقرب يوم استحقاق.
    final upcoming = _bills.where((b) => b.lastPaidMonth != monthKey).toList()
      ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    final next = upcoming.isEmpty ? null : upcoming.first;

    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('التزاماتك الشهرية', 'Monthly commitments'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text(egp(total),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              _projCell(tr('اتدفع', 'Paid'), egp(paid), Colors.green),
              const SizedBox(width: 8),
              _projCell(tr('متبقّى الشهر', 'Left this month'), egp(remaining),
                  remaining > 0 ? scheme.error : Colors.green),
            ]),
            if (next != null) ...[
              const SizedBox(height: 8),
              Text(
                  tr('التالى: ${next.name} — ${egp(next.amount)} يوم ${arNum(next.dayOfMonth)}',
                      'Next: ${next.name} — ${egp(next.amount)} on day ${arNum(next.dayOfMonth)}'),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _projCell(String label, String value, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: scheme.outline)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _billTile(BuildContext context, RecurringBill b) {
    final scheme = Theme.of(context).colorScheme;
    final due = b.isDue(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: due ? scheme.tertiary.withValues(alpha: .13) : null,
      // 🔴 `dense: true` بتضغط ارتفاع الـtrailing، فزرار «اتدفعت» كان
      // **نصّه متقصوص من تحت** (٢٢px والكلمة محتاجة ٢٨). مافيش خطأ بيترمى
      // ومافيش اختبار كان بيشوفه — الصورة اللى بعتها هى اللى كشفته.
      child: ListTile(
        title: Text(b.name,
            style: due
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null),
        subtitle: Text(
            tr('${egp(b.amount)} • يوم ${arNum(b.dayOfMonth)} من الشهر${due ? ' — مستحقة!' : ''}',
                '${egp(b.amount)} • day ${arNum(b.dayOfMonth)}${due ? ' — due!' : ''}')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (due)
              FilledButton.tonal(
                onPressed: () async {
                  await BillsRepo().markPaid(b.id!);
                  if (mounted) await _load();
                },
                child: Text(tr('اتدفعت ✓', 'Paid ✓')),
              ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    await _billForm(b);
                  case 'calendar':
                    // حدث شهرى فى يوم الاستحقاق — التذكير بيفضل شغّال
                    // حتى لو التطبيق مش مفتوح.
                    await CalendarSync.addBill(b);
                  case 'delete':
                    if (!await confirmDelete(
                        context, tr('الفاتورة "${b.name}"', 'bill "${b.name}"'))) {
                      return;
                    }
                    await BillsRepo().delete(b.id!);
                    if (mounted) await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                PopupMenuItem(
                    value: 'calendar',
                    child: Text(
                        tr('أضف لتقويم الموبايل', 'Add to phone calendar'))),
                PopupMenuItem(
                    value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _billForm([RecurringBill? bill]) async {
    final name = TextEditingController(text: bill?.name ?? '');
    final amount = TextEditingController(
        text: bill == null ? '' : bill.amount.toStringAsFixed(0));
    var dayOfMonth = bill?.dayOfMonth ?? 1;
    var category = bill?.category ?? 'فواتير';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        scrollable: true,
          title: Text(bill == null
              ? tr('فاتورة دورية جديدة', 'New recurring bill')
              : tr('تعديل فاتورة', 'Edit bill')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: bill == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (كهربا، نت، اشتراك جيم...)',
                        'Name (electricity, internet, gym...)')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText:
                        tr('المبلغ التقريبي (ج.م)', 'Approx. amount (EGP)')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(tr('يوم الاستحقاق', 'Due day'))),
                  DropdownButton<int>(
                    value: dayOfMonth,
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text(arNum(d))),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => dayOfMonth = v ?? dayOfMonth),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration:
                    InputDecoration(labelText: tr('الفئة', 'Category')),
                items: [
                  for (final c in kExpenseCategories)
                    DropdownMenuItem(
                        value: c, child: Text(expenseCategoryLabel(c))),
                ],
                onChanged: (v) => category = v ?? category,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      final value = parseNumber(amount.text);
      if (name.text.trim().isNotEmpty && value != null && value > 0) {
        await BillsRepo().save(RecurringBill(
          id: bill?.id,
          name: name.text.trim(),
          amount: value,
          dayOfMonth: dayOfMonth,
          category: category,
          lastPaidMonth: bill?.lastPaidMonth ?? '',
        ));
        if (mounted) await _load();
      }
    }
    name.dispose();
    amount.dispose();
  }

  Widget _expenseTile(BuildContext context, Expense e) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: expenseCategoryColor(e.category).withValues(alpha: .15),
          child: Icon(expenseCategoryIcon(e.category),
              size: 18, color: expenseCategoryColor(e.category)),
        ),
        title: Text(e.note.isEmpty ? expenseCategoryLabel(e.category) : e.note),
        subtitle: Text(
            '${expenseCategoryLabel(e.category)} • ${arShortDate(DateTime.parse(e.day))}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(egp(e.amount),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') await _delete(e);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// بند فى شبكة «فلوسى».
class _Hub {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Hub(this.title, this.value, this.icon, this.color, this.onTap);
}

/// صفحة قسم داخل «فلوسى». بتاخد **دالة** بتبنى المحتوى من حالة
/// `MoneyScreen` نفسها، فلمّا تعدّل حاجة جوّه القسم بننادى `onRefresh`
/// وبعدين نعيد البناء — من غير ما نكرّر تحميل البيانات فى كل صفحة.
class _MoneySectionPage extends StatefulWidget {
  final String title;

  /// بتاخد الفلتر المختار وترجّع محتوى الصفحة.
  final List<Widget> Function(String filter) body;

  /// شرائح فوق القايمة — فاضية = مفيش فلاتر.
  final List<String> filters;
  final Future<void> Function() onRefresh;

  /// زرار الإضافة جوّه القسم — إنت جوّاه لمّا تحبّ تسجّل، فالرجوع
  /// للرئيسية عشان تضيف كان هيبقى لفّة زيادة.
  final String? addLabel;
  final Future<void> Function()? onAdd;

  const _MoneySectionPage({
    required this.title,
    required this.body,
    required this.onRefresh,
    this.filters = const [],
    this.addLabel,
    this.onAdd,
  });

  @override
  State<_MoneySectionPage> createState() => _MoneySectionPageState();
}

class _MoneySectionPageState extends State<_MoneySectionPage> {
  late String _filter = widget.filters.isEmpty ? '' : widget.filters.first;

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (mounted) setState(() {});
  }

  /// شرائح الفلتر — بتمرّر أفقيًا فمهما كان عددها مابتتقصّش.
  Widget _filterBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in widget.filters)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 7),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _filter == f
                        ? scheme.primary
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: _filter == f
                            ? scheme.primary
                            : scheme.outlineVariant),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _filter == f
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
          tooltip: tr('تحديث', 'Refresh'),
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            if (widget.filters.isNotEmpty) ...[
              _filterBar(context),
              const SizedBox(height: 12),
            ],
            ...widget.body(_filter),
          ],
        ),
      ),
      floatingActionButton: widget.onAdd == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await widget.onAdd!();
                await _refresh();
              },
              icon: const Icon(Icons.add),
              label: Text(widget.addLabel ?? tr('إضافة', 'Add')),
            ),
    );
  }
}
