import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/bills_repo.dart';
import '../../data/money_categories.dart';
import '../../data/money_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';

/// **الفواتير الثابتة** — كهربا · نت · مدرسة · اشتراكات.
///
/// كانت جوّه شاشة فلوسى القديمة كقسم، ولما الشاشة اتبنت من الأول كان
/// لازم يبقى ليها مكان ظاهر — من غيره مش هتقدر تضيف فاتورة ثابتة تانى.
class FixedBillsScreen extends StatefulWidget {
  const FixedBillsScreen({super.key});

  @override
  State<FixedBillsScreen> createState() => _FixedBillsScreenState();
}

class _FixedBillsScreenState extends State<FixedBillsScreen> {
  final _repo = BillsRepo();
  List<RecurringBill> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await _repo.all();
    if (!mounted) return;
    setState(() {
      _bills = b;
      _loading = false;
    });
  }

  Future<void> _form([RecurringBill? bill]) async {
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
              ? tr('فاتورة ثابتة جديدة', 'New fixed bill')
              : tr('تعديل الفاتورة', 'Edit bill')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: name,
              autofocus: bill == null,
              decoration: InputDecoration(
                  labelText: tr('الاسم (كهربا · نت · مدرسة…)',
                      'Name (electricity, internet…)')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('المبلغ التقريبى', 'Approx. amount')),
            ),
            const SizedBox(height: 12),
            Row(children: [
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
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(labelText: tr('الفئة', 'Category')),
              items: [
                for (final c in MoneyCategories.expense)
                  DropdownMenuItem(
                      value: c, child: Text(expenseCategoryLabel(c))),
              ],
              onChanged: (v) => category = v ?? category,
            ),
          ]),
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
        await _repo.save(RecurringBill(
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

  Future<void> _markPaid(RecurringBill b) async {
    await _repo.markPaid(b.id!);
    if (mounted) await _load();
  }

  /// الشهر الحالى YYYY-MM — عشان نعرف الفاتورة اتدفعت ولا لأ.
  String get _thisMonth {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}';
  }

  Future<void> _delete(RecurringBill b) async {
    if (!await confirmDelete(
        context, tr('فاتورة "${b.name}"', 'bill "${b.name}"'))) {
      return;
    }
    await _repo.delete(b.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final total = _bills.fold<double>(0, (t, b) => t + b.amount);

    return Scaffold(
      appBar: AppBar(title: Text(tr('فواتير ثابتة', 'Fixed bills'))),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bills_fab',
        onPressed: () => _form(),
        tooltip: tr('ضيف فاتورة', 'Add bill'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? EmptyHint(
                  icon: Icons.repeat,
                  text: tr(
                      'سجّل الكهربا والنت والاشتراكات مرة واحدة — وهفكّرك كل شهر',
                      'Log electricity, internet and subscriptions once'),
                  actionLabel: tr('ضيف فاتورة', 'Add bill'),
                  onAction: _form,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: [
                      AppCard(
                        Row(children: [
                          Expanded(
                            child: Text(
                                tr('إجمالى الثابت كل شهر', 'Fixed every month'),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurfaceVariant)),
                          ),
                          Text(arMoney(total.round()),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                        ]),
                        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      ),
                      AppGroupHead(tr('فواتيرك', 'Your bills'),
                          trail: arNum(_bills.length)),
                      for (var i = 0; i < _bills.length; i++)
                        AppListRow(
                          title: _bills[i].name,
                          sub: tr(
                              'يوم ${arNum(_bills[i].dayOfMonth)} · ${expenseCategoryLabel(_bills[i].category)}',
                              'day ${arNum(_bills[i].dayOfMonth)} · ${expenseCategoryLabel(_bills[i].category)}'),
                          icon: Icons.receipt_long,
                          tint: _bills[i].isDue(now)
                              ? scheme.error
                              : const Color(0xFFF59E0B),
                          divider: i != _bills.length - 1,
                          onTap: () => _form(_bills[i]),
                          onLongPress: () => _delete(_bills[i]),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // زى «قبضته» فى الدخل بالظبط.
                                if (_bills[i].lastPaidMonth == _thisMonth)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(Icons.check_circle,
                                        size: 16,
                                        color: const Color(0xFF10B981)),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: TextButton(
                                      onPressed: () => _markPaid(_bills[i]),
                                      style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8)),
                                      child: Text(tr('اتدفعت', 'Paid'),
                                          style:
                                              const TextStyle(fontSize: 11.5)),
                                    ),
                                  ),
                                Text(arMoney(_bills[i].amount.round()),
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900)),
                              ]),
                        ),
                      const SizedBox(height: 10),
                      Text(
                          tr('دوس على الفاتورة تعدّلها · دوس مطوّل تمسحها',
                              'Tap to edit · long-press to delete'),
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
    );
  }
}
