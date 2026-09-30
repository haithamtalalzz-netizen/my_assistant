import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/bills_repo.dart';
import '../../data/income_repo.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import 'fixed_bills_screen.dart';
import 'recurring_income_screen.dart';
import 'wallets_screen.dart';

/// **اللى ثابت كل شهر** — بيجيلك إيه وبيروح عليك إيه، وبيفضل كام.
///
/// كانت ٣ سطور فى آخر «فلوسى» — بتقول الإجمالى من غير ما تقول جاى منين
/// ولا رايح فين. هنا البنود نفسها مكتوبة، وكل واحد بيودّيك على شاشته.
class FixedMonthlyScreen extends StatefulWidget {
  const FixedMonthlyScreen({super.key});

  @override
  State<FixedMonthlyScreen> createState() => _FixedMonthlyScreenState();
}

class _FixedMonthlyScreenState extends State<FixedMonthlyScreen> {
  final _income = IncomeRepo();
  final _bills = BillsRepo();
  final _wallets = WalletsRepo();

  bool _loading = true;
  List<RecurringIncome> _incomes = [];
  List<RecurringBill> _billList = [];
  List<Wallet> _certs = [];

  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _teal = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inc = await _income.allRecurring();
    final bills = await _bills.all();
    final all = await _wallets.all();
    if (!mounted) return;
    setState(() {
      _incomes = inc;
      _billList = bills;
      _certs = [
        for (final w in all)
          if (w.type == 'bank' &&
              w.bankKind == 'certificate' &&
              w.monthlyInterest > 0)
            w
      ];
      _loading = false;
    });
  }

  double get _inTotal =>
      _incomes.fold<double>(0, (s, e) => s + e.amount) +
      _certs.fold<double>(0, (s, e) => s + e.monthlyInterest);

  double get _outTotal => _billList.fold<double>(0, (s, e) => s + e.amount);

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = _inTotal - _outTotal;
    final empty = _incomes.isEmpty && _billList.isEmpty && _certs.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(tr('اللى ثابت كل شهر', 'Every month'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  AppCard(
                    Column(children: [
                      Text(tr('بيفضل معاك كل شهر', 'Left every month'),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(arMoney(left.round()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: left >= 0 ? _teal : scheme.error)),
                      const SizedBox(height: 4),
                      Text(
                          tr('بيجيلك ${arMoney(_inTotal.round())} · بيروح ${arMoney(_outTotal.round())}',
                              'in ${arMoney(_inTotal.round())} · out ${arMoney(_outTotal.round())}'),
                          style: TextStyle(
                              fontSize: 11.5, color: scheme.onSurfaceVariant)),
                    ]),
                    padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
                  ),
                  if (empty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: EmptyHint(
                        icon: Icons.event_repeat,
                        text: tr(
                            'سجّل دخلك الثابت وفواتيرك مرة واحدة — وتعرف بيفضل معاك كام كل شهر',
                            'Log your recurring income and bills once'),
                        actionLabel: tr('ضيف دخل ثابت', 'Add income'),
                        onAction: () => _open(const RecurringIncomeScreen()),
                      ),
                    ),

                  // ———— بيجيلك ————
                  if (_incomes.isNotEmpty || _certs.isNotEmpty)
                    AppGroupHead(tr('بيجيلك', 'Coming in'),
                        trail: arMoney(_inTotal.round())),
                  for (var i = 0; i < _incomes.length; i++)
                    AppListRow(
                      title: incomeSourceLabel(_incomes[i].source),
                      sub: _incomes[i].note.isNotEmpty
                          ? tr(
                              'يوم ${arNum(_incomes[i].dayOfMonth)} · ${_incomes[i].note}',
                              'day ${arNum(_incomes[i].dayOfMonth)} · ${_incomes[i].note}')
                          : tr('يوم ${arNum(_incomes[i].dayOfMonth)} من الشهر',
                              'day ${arNum(_incomes[i].dayOfMonth)}'),
                      icon: Icons.payments,
                      tint: _green,
                      chevron: true,
                      divider: i != _incomes.length - 1 || _certs.isNotEmpty,
                      onTap: () => _open(const RecurringIncomeScreen()),
                      trailing: Text(arMoney(_incomes[i].amount.round()),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: _green)),
                    ),
                  for (var i = 0; i < _certs.length; i++)
                    AppListRow(
                      title: tr('عائد ${_certs[i].name}',
                          '${_certs[i].name} interest'),
                      sub: tr('شهادة بنكية', 'Bank certificate'),
                      icon: Icons.account_balance,
                      tint: _teal,
                      chevron: true,
                      divider: i != _certs.length - 1,
                      onTap: () => _open(const WalletsScreen()),
                      trailing: Text(
                          arMoney(_certs[i].monthlyInterest.round()),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: _teal)),
                    ),

                  // ———— بيروح عليك ————
                  if (_billList.isNotEmpty)
                    AppGroupHead(tr('بيروح عليك', 'Going out'),
                        trail: arMoney(_outTotal.round())),
                  for (var i = 0; i < _billList.length; i++)
                    AppListRow(
                      title: _billList[i].name,
                      sub: tr('يوم ${arNum(_billList[i].dayOfMonth)} من الشهر',
                          'day ${arNum(_billList[i].dayOfMonth)}'),
                      icon: Icons.receipt_long,
                      tint: _amber,
                      chevron: true,
                      divider: i != _billList.length - 1,
                      onTap: () => _open(const FixedBillsScreen()),
                      trailing: Text(arMoney(_billList[i].amount.round()),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: _amber)),
                    ),

                  // ———— إدارة ————
                  AppGroupHead(tr('تضيف أو تعدّل', 'Add or edit')),
                  AppListRow(
                    title: tr('دخلك الثابت', 'Recurring income'),
                    sub: tr('${arNum(_incomes.length)} بند',
                        '${arNum(_incomes.length)} items'),
                    icon: Icons.add_circle_outline,
                    tint: _green,
                    chevron: true,
                    onTap: () => _open(const RecurringIncomeScreen()),
                  ),
                  AppListRow(
                    title: tr('فواتيرك الثابتة', 'Fixed bills'),
                    sub: tr('${arNum(_billList.length)} فاتورة',
                        '${arNum(_billList.length)} bills'),
                    icon: Icons.add_circle_outline,
                    tint: _amber,
                    chevron: true,
                    divider: false,
                    onTap: () => _open(const FixedBillsScreen()),
                  ),
                ],
              ),
            ),
    );
  }
}
