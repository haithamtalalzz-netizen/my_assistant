import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/income_repo.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';

/// تسجيل دخل بسرعة — مبلغ + مصدر وخلاص.
Future<bool?> showIncomeSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _IncomeForm(),
    ),
  );
}

class _IncomeForm extends StatefulWidget {
  const _IncomeForm();

  @override
  State<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<_IncomeForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _source = kIncomeSources.first;
  List<Wallet> _wallets = [];
  int? _walletId;

  @override
  void initState() {
    super.initState();
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
    await IncomeRepo().add(Income(
      amount: value,
      source: _source,
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
          Text(tr('سجل دخل', 'Log income'),
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
              for (final s in kIncomeSources)
                ChoiceChip(
                  label: Text(incomeSourceLabel(s)),
                  selected: _source == s,
                  onSelected: (_) => setState(() => _source = s),
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
