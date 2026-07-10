import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final _repo = WalletsRepo();
  bool _loading = true;
  List<({Wallet wallet, double balance})> _items = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.allWithBalances();
    if (!mounted) return;
    setState(() {
      _items = items;
      _total = items.fold<double>(0, (s, e) => s + e.balance);
      _loading = false;
    });
  }

  IconData _iconFor(String type) => switch (type) {
        'cash' => Icons.payments_outlined,
        'bank' => Icons.account_balance_outlined,
        'card' => Icons.credit_card,
        'mobile' => Icons.phone_android_outlined,
        _ => Icons.wallet_outlined,
      };

  Future<void> _walletForm([Wallet? w]) async {
    final name = TextEditingController(text: w?.name ?? '');
    final opening = TextEditingController(
        text: w == null ? '' : w.openingBalance.toStringAsFixed(0));
    var type = w?.type ?? kWalletTypes.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(w == null ? tr('محفظة جديدة', 'New wallet') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: w == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (كاش، بنك مصر...)',
                        'Name (cash, bank...)')),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in kWalletTypes)
                    ChoiceChip(
                      label: Text(walletTypeLabel(t)),
                      selected: type == t,
                      onSelected: (_) => setD(() => type = t),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: opening,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: tr('الرصيد الحالي (ج.م)', 'Current balance (EGP)')),
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
    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.save(Wallet(
        id: w?.id,
        name: name.text.trim(),
        type: type,
        openingBalance: parseNumber(opening.text) ?? 0,
      ));
      if (mounted) await _load();
    }
    name.dispose();
    opening.dispose();
  }

  Future<void> _transfer() async {
    if (_items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('محتاج محفظتين على الأقل', 'Need at least 2 wallets'))));
      return;
    }
    var from = _items.first.wallet.id!;
    var to = _items[1].wallet.id!;
    final amount = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('تحويل بين المحافظ', 'Transfer between wallets')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(tr('من', 'From'))),
                  DropdownButton<int>(
                    value: from,
                    items: [
                      for (final e in _items)
                        DropdownMenuItem(
                            value: e.wallet.id, child: Text(e.wallet.name)),
                    ],
                    onChanged: (v) => setD(() => from = v ?? from),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(tr('إلى', 'To'))),
                  DropdownButton<int>(
                    value: to,
                    items: [
                      for (final e in _items)
                        DropdownMenuItem(
                            value: e.wallet.id, child: Text(e.wallet.name)),
                    ],
                    onChanged: (v) => setD(() => to = v ?? to),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('المبلغ', 'Amount')),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حوّل', 'Transfer'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      final v = parseNumber(amount.text);
      if (v != null && v > 0 && from != to) {
        await _repo.transfer(from, to, v);
        if (mounted) await _load();
      }
    }
    amount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('المحافظ', 'Wallets')),
        actions: [
          searchAction(context),
          if (_items.length >= 2)
            IconButton(
              onPressed: _transfer,
              tooltip: tr('تحويل', 'Transfer'),
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.account_balance_wallet_outlined,
                  text: tr('ضيف محافظك (كاش، بنك، فودافون كاش) وتابع رصيد كل واحدة',
                      'Add your wallets (cash, bank, mobile) & track each balance'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(tr('إجمالي فلوسك', 'Total balance'),
                                style: TextStyle(
                                    color: scheme.onPrimaryContainer
                                        .withValues(alpha: 0.8))),
                            Text(egp(_total),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onPrimaryContainer)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final e in _items)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          leading: Icon(_iconFor(e.wallet.type),
                              color: scheme.primary),
                          title: Text(e.wallet.name),
                          subtitle: Text(walletTypeLabel(e.wallet.type)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(egp(e.balance),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: e.balance < 0
                                          ? scheme.error
                                          : null)),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await _walletForm(e.wallet);
                                  } else if (v == 'delete') {
                                    if (!await confirmDelete(context,
                                        tr('محفظة «${e.wallet.name}»',
                                            'wallet "${e.wallet.name}"'))) {
                                      return;
                                    }
                                    await _repo.delete(e.wallet.id!);
                                    if (mounted) await _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(tr('تعديل', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(tr('حذف', 'Delete'))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wallets_fab',
        onPressed: () => _walletForm(),
        tooltip: tr('محفظة جديدة', 'New wallet'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
