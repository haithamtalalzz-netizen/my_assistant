import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../core/month_summary.dart';
import '../../core/ocr.dart';
import '../../data/bills_repo.dart';
import '../../data/debts_repo.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../baladna/debts_screen.dart';
import '../baladna/gameya_screen.dart';
import '../baladna/home_maintenance_screen.dart';
import '../baladna/savings_screen.dart';
import 'income_sheet.dart';
import 'quick_expense_sheet.dart';
import 'wallets_screen.dart';

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
  List<RecurringBill> _bills = [];
  List<Income> _income = [];
  List<RecurringIncome> _recurringIncome = [];
  double _total = 0;
  double _incomeTotal = 0;
  double _budget = 0;
  double _debtNet = 0;

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
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _byCategory = byCat;
      _total = total;
      _budget = budget;
      _bills = bills;
      _income = income;
      _incomeTotal = incomeTotal;
      _recurringIncome = recurringIncome;
      _debtNet = owedToMe - iOwe;
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

  /// صوّر الفاتورة → OCR محلي → شيت المصروف متملي بالإجمالي.
  Future<void> _scanReceipt() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 2200);
    if (picked == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('بقرا الفاتورة...', 'Reading receipt...'))));
    final text = await OcrService.recognizeFromPath(picked.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('معرفتش أقرا الصورة — جرب إضاءة أحسن',
              "Couldn't read the image — try better lighting"))));
      return;
    }
    final total = extractReceiptTotal(text);
    dev.log('OCR receipt total: $total');
    if (total == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('ملقتش إجمالي واضح — سجله يدوي',
              'No clear total found — log it manually'))));
      final added = await showQuickExpenseSheet(context);
      if (added == true && mounted) await _load();
      return;
    }
    final added = await showQuickExpenseSheet(context,
        initialAmount: total, initialNote: tr('فاتورة', 'Receipt'));
    if (added == true && mounted) await _load();
  }

  /// «أشتري ولا أستنى؟» — حسبة من ميزانيتك ومعدل صرفك الفعلي.
  Future<void> _buyOrWait() async {
    final controller = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(tr('أشتري ولا أستنى؟', 'Buy or wait?')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: tr('سعر الحاجة (ج.م)', 'Item price (EGP)')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, parseNumber(controller.text)),
              child: Text(tr('احسبها', 'Calculate'))),
        ],
      ),
    );
    controller.dispose();
    if (price == null || price <= 0 || !mounted) return;

    final now = DateTime.now();
    final spent = await _repo.totalForMonth(now.year, now.month);
    final budget = await _settings.monthlyBudget();
    final daysPassed = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - daysPassed;
    final dailyAvg = daysPassed == 0 ? 0.0 : spent / daysPassed;
    final projected = spent + dailyAvg * daysLeft;

    final lines = <String>[];
    if (budget > 0) {
      final remaining = budget - spent;
      lines.add(tr(
          'المتبقي من ميزانيتك: ${egp(remaining)} لمدة ${arNum(daysLeft)} يوم.',
          'Budget remaining: ${egp(remaining)} for ${arNum(daysLeft)} days.'));
      final afterPurchase = remaining - price;
      if (afterPurchase < 0) {
        lines.add(tr(
            'الشراء دلوقتي هيخليك تعدي الميزانية بـ ${egp(-afterPurchase)} — استنى أول الشهر أحسن.',
            'Buying now goes ${egp(-afterPurchase)} over budget — better wait for next month.'));
      } else if (price > remaining * 0.5) {
        lines.add(tr(
            'الحاجة دي هتاكل ٪${arNum((price * 100 / remaining).round())} من المتبقي — تتحمل، بس هتضيّق باقي الشهر.',
            'This eats ${arNum((price * 100 / remaining).round())}% of what remains — affordable but tight.'));
      } else {
        lines.add(tr(
            'تقدر تشتريها براحتك — هتاخد ٪${arNum((price * 100 / remaining).round())} بس من المتبقي.',
            'Go ahead — only ${arNum((price * 100 / remaining).round())}% of what remains.'));
      }
    } else {
      lines.add(tr(
          'مصاريفك الشهر ده: ${egp(spent)} (متوسط ${egp(dailyAvg)} يوميًا).',
          "This month's spend: ${egp(spent)} (avg ${egp(dailyAvg)}/day)."));
      lines.add(tr(
          'بمعدلك الحالي هتقفل الشهر على ${egp(projected)} — الحاجة دي هتزود ٪${arNum((price * 100 / (projected == 0 ? price : projected)).round())} فوقهم.',
          'At your pace the month ends at ${egp(projected)} — this adds ${arNum((price * 100 / (projected == 0 ? price : projected)).round())}% on top.'));
      lines.add(tr('حدد ميزانية شهرية من الإعدادات عشان الحسبة تبقى أدق.',
          'Set a monthly budget in settings for a sharper estimate.'));
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(tr('حسبة شراء ${egp(price)}', 'Purchase check ${egp(price)}')),
        content: Text(lines.join('\n\n'), style: const TextStyle(height: 1.7)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('تمام', 'OK'))),
        ],
      ),
    );
  }

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
        actions: [
          searchAction(context),
          IconButton(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WalletsScreen()));
              if (mounted) await _load();
            },
            tooltip: tr('المحافظ', 'Wallets'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            onPressed: _scanReceipt,
            tooltip: tr('صوّر فاتورة', 'Scan receipt'),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          IconButton(
            onPressed: _buyOrWait,
            tooltip: tr('أشتري ولا أستنى؟', 'Buy or wait?'),
            icon: const Icon(Icons.calculate_outlined),
          ),
        ],
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
                  const SizedBox(height: 8),
                  _budgetCard(context),
                  SectionHeader(tr('الدخل', 'Income'),
                      trailing: TextButton(
                          onPressed: _addIncome,
                          child: Text(tr('سجل دخل', 'Log income')))),
                  ..._recurringIncome
                      .map((i) => _recurringIncomeTile(context, i)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => _recurringIncomeForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(tr('دخل دوري (مرتب)', 'Recurring income (salary)')),
                    ),
                  ),
                  if (_income.isEmpty)
                    Text(
                        tr('مفيش دخل متسجل الشهر ده',
                            'No income logged this month'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 13))
                  else
                    ..._income.map((i) => _incomeTile(context, i)),
                  SectionHeader(tr('الفواتير الدورية', 'Recurring bills'),
                      trailing: TextButton(
                          onPressed: () => _billForm(),
                          child: Text(tr('ضيف فاتورة', 'Add bill')))),
                  if (_bills.isEmpty)
                    Text(
                        tr('سجل الكهربا والنت والاشتراكات مرة واحدة — وهفكرك كل شهر',
                            'Log electricity, internet & subscriptions once — reminded monthly'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 13))
                  else
                    ..._bills.map((b) => _billTile(context, b)),
                  if (_byCategory.isNotEmpty) ...[
                    SectionHeader(tr('حسب الفئة', 'By category')),
                    _categoryBreakdown(context),
                  ],
                  SectionHeader(tr('بلدنا', 'Local')),
                  _baladnaGrid(context),
                  SectionHeader(tr('المصاريف', 'Expenses')),
                  if (_expenses.isEmpty)
                    EmptyHint(
                        icon: Icons.receipt_long_outlined,
                        text: tr('مفيش مصاريف متسجلة الشهر ده',
                            'No expenses logged this month'))
                  else
                    ..._expenses.map((e) => _expenseTile(context, e)),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: due ? scheme.tertiary.withValues(alpha: .13) : null,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.event_repeat,
            color: due ? scheme.tertiary : Colors.green),
        title: Text(incomeSourceLabel(i.source),
            style: due
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null),
        subtitle: Text(
            tr('${egp(i.amount)} • يوم ${arNum(i.dayOfMonth)}${due ? ' — قبضته؟' : ''}',
                '${egp(i.amount)} • day ${arNum(i.dayOfMonth)}${due ? ' — received?' : ''}')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (due)
              FilledButton.tonal(
                onPressed: () async {
                  await IncomeRepo()
                      .markReceived(i, now: DateTime.now());
                  if (mounted) await _load();
                },
                child: Text(tr('قبضته ✓', 'Received ✓')),
              ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    await _recurringIncomeForm(i);
                  case 'delete':
                    if (!await confirmDelete(context,
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
                PopupMenuItem(
                    value: 'delete', child: Text(tr('حذف', 'Delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recurringIncomeForm([RecurringIncome? inc]) async {
    final amount = TextEditingController(
        text: inc == null ? '' : inc.amount.toStringAsFixed(0));
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
          source: source,
          amount: value,
          dayOfMonth: dayOfMonth,
          lastReceivedMonth: inc?.lastReceivedMonth ?? '',
        ));
        if (mounted) await _load();
      }
    }
    amount.dispose();
  }

  Widget _budgetCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = _budget > 0 && _total > _budget;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _budget <= 0
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('إجمالي الشهر', 'Month total'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: scheme.outline)),
                        Text(egp(_total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: _editBudget,
                      child: Text(tr('حدد ميزانية', 'Set budget'))),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(tr('ميزانية الشهر', 'Monthly budget'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: scheme.outline)),
                      ),
                      IconButton(
                          onPressed: _editBudget,
                          tooltip: tr('تعديل الميزانية', 'Edit budget'),
                          icon: const Icon(Icons.edit_outlined, size: 18)),
                    ],
                  ),
                  LinearProgressIndicator(
                    value: (_total / _budget).clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: over ? scheme.error : scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('${egp(_total)} من ${egp(_budget)}${over ? ' — عدّيت الميزانية!' : ''}',
                        '${egp(_total)} of ${egp(_budget)}${over ? ' — over budget!' : ''}'),
                    style: TextStyle(
                        color: over ? scheme.error : null,
                        fontWeight: over ? FontWeight.w600 : null),
                  ),
                  if (_isCurrentMonth && !over) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final now = DateTime.now();
                      final daysLeft =
                          DateTime(now.year, now.month + 1, 0).day - now.day + 1;
                      final perDay = (_budget - _total) / daysLeft;
                      return Text(
                        tr('متاح ليك ${egp(perDay)} يوميًا للـ ${arNum(daysLeft)} يوم الباقيين',
                            '${egp(perDay)}/day left for the remaining ${arNum(daysLeft)} days'),
                        style: TextStyle(fontSize: 12, color: scheme.primary),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _categoryBreakdown(BuildContext context) {
    final maxValue =
        _byCategory.values.fold<double>(0, (m, v) => v > m ? v : m);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final e in _byCategory.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(expenseCategoryIcon(e.key),
                            size: 16, color: expenseCategoryColor(e.key)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(expenseCategoryLabel(e.key))),
                        Text(
                            _total > 0
                                ? '${egp(e.value)} • ٪${arNum((e.value * 100 / _total).round())}'
                                : egp(e.value),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : e.value / maxValue,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                      color: expenseCategoryColor(e.key),
                    ),
                  ],
                ),
              ),
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
      child: ListTile(
        dense: true,
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

  Widget _baladnaGrid(BuildContext context) {
    Widget tile(IconData icon, String label, String? sub, Widget screen) {
      return Expanded(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => screen));
              if (mounted) await _load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (sub != null)
                    Text(sub,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final debtSub = _debtNet == 0
        ? tr('متعادل', 'Even')
        : _debtNet > 0
            ? tr('ليك ${egp(_debtNet)}', 'owed ${egp(_debtNet)}')
            : tr('عليك ${egp(-_debtNet)}', 'you owe ${egp(-_debtNet)}');
    return Row(
      children: [
        tile(Icons.handshake_outlined, tr('الديون', 'Debts'), debtSub,
            const DebtsScreen()),
        tile(Icons.groups_outlined, tr('الجمعيات', "Gam'iyas"), null,
            const GameyaScreen()),
        tile(Icons.savings_outlined, tr('الادخار', 'Savings'), null,
            const SavingsScreen()),
        tile(Icons.home_repair_service_outlined,
            tr('صيانة البيت', 'Home upkeep'), null,
            const HomeMaintenanceScreen()),
      ],
    );
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
