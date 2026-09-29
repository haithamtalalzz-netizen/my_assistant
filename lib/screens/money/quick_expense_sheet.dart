import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/money_categories.dart';
import '../../widgets/common.dart';
import '../../data/money_repo.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';

/// تسجيل مصروف في أقل من ٣ ثواني — مبلغ + فئة وخلاص.
/// [initialAmount] و[initialNote] بيتملوا تلقائيًا من ماسح الفواتير.
Future<bool?> showQuickExpenseSheet(BuildContext context,
    {double? initialAmount, String? initialNote}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
      child: _QuickExpenseForm(
          initialAmount: initialAmount, initialNote: initialNote),
    ),
  );
}

class _QuickExpenseForm extends StatefulWidget {
  final double? initialAmount;
  final String? initialNote;

  const _QuickExpenseForm({this.initialAmount, this.initialNote});

  @override
  State<_QuickExpenseForm> createState() => _QuickExpenseFormState();
}

class _QuickExpenseFormState extends State<_QuickExpenseForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = kExpenseCategories.first;
  List<Wallet> _wallets = [];
  int? _walletId;

  @override
  void initState() {
    super.initState();
    final amount = widget.initialAmount;
    if (amount != null) {
      _amount.text = amount == amount.roundToDouble()
          ? amount.toInt().toString()
          : amount.toStringAsFixed(2);
    }
    if (widget.initialNote != null) _note.text = widget.initialNote!;
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await WalletsRepo().all();
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      if (wallets.isNotEmpty) _walletId = wallets.first.id;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = parseNumber(_amount.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اكتب مبلغ صح الأول', 'Enter a valid amount first'))));
      return;
    }
    await MoneyRepo().add(Expense(
      amount: value,
      category: _category,
      note: _note.text.trim(),
      day: dayKey(DateTime.now()),
      walletId: _walletId,
    ));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('سجل مصروف', 'Log expense'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: tr('المبلغ (ج.م)', 'Amount (EGP)')),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in MoneyCategories.expense)
                // الدوسة المطوّلة بتشيل البند اللى انت ضفته بس.
                // (ChoiceChip نفسها مالهاش onLongPress.)
                GestureDetector(
                  onLongPress: MoneyCategories.isCustomExpense(c)
                      ? () async {
                          await MoneyCategories.removeExpense(c);
                          if (!mounted) return;
                          setState(() {
                            if (_category == c) {
                              _category = kExpenseCategories.first;
                            }
                          });
                        }
                      : null,
                  child: ChoiceChip(
                    label: Text(expenseCategoryLabel(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 17),
                label: Text(tr('بند جديد', 'New')),
                onPressed: () async {
                  final n =
                      await askNewCategory(context, tr('بند مصروف جديد', 'New category'));
                  if (n == null) return;
                  await MoneyCategories.addExpense(n);
                  if (mounted) setState(() => _category = n);
                },
              ),
            ],
          ),
          if (_wallets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in _wallets)
                  ChoiceChip(
                    avatar: const Icon(Icons.wallet_outlined, size: 16),
                    label: Text(w.name),
                    selected: _walletId == w.id,
                    onSelected: (_) => setState(() => _walletId = w.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(
                labelText: tr('ملاحظة (اختياري)', 'Note (optional)')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _save, child: Text(tr('حفظ', 'Save'))),
          ),
        ],
      ),
    );
  }
}
