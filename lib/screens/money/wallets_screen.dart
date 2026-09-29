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



  /// قايمة السحب — نفس البيانات، بس كل محفظة معاها مقبض تسحب منه.
  Widget _reorderList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          Icon(Icons.swap_vert, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                tr('اسحب المحفظة لمكانها — الترتيب ده هو اللى هتشوفه فى فلوسى',
                    'Drag to reorder — this is the order you see in My money'),
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
        ]),
      ),
      Expanded(
        child: ReorderableListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
          onReorderItem: _onReorder,
          children: [
            for (var i = 0; i < _items.length; i++)
              Card(
                key: ValueKey(_items[i].wallet.id),
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: Icon(walletTypeIcon(_items[i].wallet.type),
                      color: walletTypeColor(_items[i].wallet.type)),
                  title: Text(_items[i].wallet.name),
                  subtitle: Text(walletTypeLabel(_items[i].wallet.type)),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  /// وضع الترتيب: بيقلب القايمة لسحب وإفلات.
  bool _reordering = false;

  /// onReorderItem بيظبّط الرقم الجديد بنفسه بعد شيل العنصر، فمفيش
  /// تعديل يدوى هنا (اللى كان لازم مع onReorder القديمة).
  Future<void> _onReorder(int oldI, int newI) async {
    final list = [..._items];
    list.insert(newI, list.removeAt(oldI));
    setState(() => _items = list);
    await _repo.saveOrder([for (final e in list) e.wallet.id!]);
  }

  /// وصف المحفظة تحت اسمها — بيقول اللى يخصّ نوعها:
  /// المعدن وزنه وعياره، والشهادة عائدها وميعاد انتهائها، والباقى
  /// نصيبه من إجمالى فلوسك.
  String _walletSub(Wallet w, double balance) {
    final type = walletTypeLabel(w.type);
    if (isMetalWallet(w.type) && w.grams > 0) {
      return '$type · ${arNum(w.grams.round())} '
          '${tr('جرام', 'g')} · ${metalKaratLabel(w.type, w.karat)}';
    }
    if (w.type == 'bank' && w.bankKind == 'certificate') {
      final bits = <String>[tr('شهادة', 'Certificate')];
      if (w.monthlyInterest > 0) {
        bits.add(tr('عائد ${arMoney(w.monthlyInterest.round())} فى الشهر',
            '${arMoney(w.monthlyInterest.round())} monthly'));
      }
      final end = DateTime.tryParse(w.maturity);
      if (end != null) {
        final left = end.difference(dateOnly(DateTime.now())).inDays;
        bits.add(left >= 0
            ? tr('تنتهى ${arShortDate(end)} (باقى ${arNum(left)} يوم)',
                'matures ${arShortDate(end)} (${arNum(left)}d)')
            : tr('انتهت ${arShortDate(end)}', 'matured ${arShortDate(end)}'));
      }
      return bits.join(' · ');
    }
    if (_total > 0 && balance > 0) {
      return '$type · ${arNum((balance / _total * 100).round())}٪ '
          '${tr('من إجمالى فلوسك', 'of total')}';
    }
    return type;
  }

  Future<void> _walletForm([Wallet? w]) async {
    final name = TextEditingController(text: w?.name ?? '');
    final opening = TextEditingController(
        text: w == null || w.openingBalance == 0
            ? ''
            : w.openingBalance.toStringAsFixed(0));
    final grams = TextEditingController(
        text: w == null || w.grams == 0 ? '' : w.grams.toStringAsFixed(0));
    final gramPrice = TextEditingController(
        text: w == null || w.gramPrice == 0
            ? ''
            : w.gramPrice.toStringAsFixed(0));
    final interest = TextEditingController(
        text: w == null || w.monthlyInterest == 0
            ? ''
            : w.monthlyInterest.toStringAsFixed(0));

    var type = w?.type ?? kWalletTypes.first;
    var karat = w != null && w.karat > 0 ? w.karat : metalKarats(type).first;
    var bankKind = w?.bankKind ?? kBankKinds.first;
    DateTime? maturity =
        w == null || w.maturity.isEmpty ? null : DateTime.tryParse(w.maturity);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final metal = isMetalWallet(type);
          // القيمة بتتحدّث وأنت بتكتب — عشان تشوف الحساب قبل ما تحفظ.
          final live = metalValue(
              type: type,
              grams: parseNumber(grams.text) ?? 0,
              karat: karat,
              gramPrice: parseNumber(gramPrice.text) ?? 0);
          return AlertDialog(
            scrollable: true,
            title: Text(w == null
                ? tr('محفظة جديدة', 'New wallet')
                : tr('تعديل', 'Edit')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: name,
                autofocus: w == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (كاش · بنك مصر · شقة المعادى…)',
                        'Name (cash, bank, flat…)')),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in kWalletTypes)
                  ChoiceChip(
                    label: Text(walletTypeLabel(t)),
                    selected: type == t,
                    onSelected: (_) => setD(() {
                      type = t;
                      if (isMetalWallet(t)) karat = metalKarats(t).first;
                    }),
                  ),
              ]),
              const SizedBox(height: 10),

              // ——— ذهب / فضة: الوزن والعيار وسعر الجرام ———
              if (metal) ...[
                TextField(
                  controller: grams,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setD(() {}),
                  decoration: InputDecoration(
                      labelText: tr('الوزن بالجرام', 'Weight in grams')),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(tr('العيار', 'Karat'),
                      style: const TextStyle(fontSize: 12.5)),
                ),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final k in metalKarats(type))
                    ChoiceChip(
                      label: Text(metalKaratLabel(type, k)),
                      selected: karat == k,
                      onSelected: (_) => setD(() => karat = k),
                    ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: gramPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setD(() {}),
                  decoration: InputDecoration(
                    labelText: tr(
                        'سعر جرام ${metalKaratLabel(type, metalBaseKarat(type))} فى السوق',
                        'Market price per gram (${metalKaratLabel(type, metalBaseKarat(type))})'),
                    helperText: tr('سعر السوق النهاردة — عدّله وقت ما تحب',
                        "Today's market price — edit any time"),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: walletTypeColor(type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('قيمتها', 'Its value'),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(live > 0 ? arMoney(live.round()) : '—',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: walletTypeColor(type))),
                        Text(
                            tr('الوزن × سعر الجرام × نقاوة العيار',
                                'grams × price × purity'),
                            style: const TextStyle(fontSize: 11)),
                      ]),
                ),
              ]

              // ——— بنك: متاح ولا شهادة ———
              else ...[
                if (type == 'bank') ...[
                  Wrap(spacing: 6, children: [
                    for (final b in kBankKinds)
                      ChoiceChip(
                        label: Text(bankKindLabel(b)),
                        selected: bankKind == b,
                        onSelected: (_) => setD(() => bankKind = b),
                      ),
                  ]),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: opening,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: type == 'bank' && bankKind == 'certificate'
                          ? tr('قيمة الشهادة', 'Certificate amount')
                          : isValueOnlyWallet(type)
                              ? tr('قيمتها التقديرية', 'Estimated value')
                              : tr('الرصيد الحالى', 'Current balance')),
                ),
                if (type == 'bank' && bankKind == 'certificate') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: interest,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: tr('العائد الشهرى', 'Monthly interest')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: maturity ??
                            DateTime(now.year + 1, now.month, now.day),
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 30),
                      );
                      if (d != null) setD(() => maturity = d);
                    },
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(maturity == null
                        ? tr('تاريخ انتهاء الشهادة', 'Maturity date')
                        : tr('تنتهى ${arShortDate(maturity!)}',
                            'Matures ${arShortDate(maturity!)}')),
                  ),
                ],
              ],
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('إلغاء', 'Cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr('حفظ', 'Save'))),
            ],
          );
        },
      ),
    );

    if (saved == true && name.text.trim().isNotEmpty) {
      final metal = isMetalWallet(type);
      await _repo.save(Wallet(
        id: w?.id,
        name: name.text.trim(),
        type: type,
        openingBalance: metal ? 0 : (parseNumber(opening.text) ?? 0),
        grams: metal ? (parseNumber(grams.text) ?? 0) : 0,
        karat: metal ? karat : 0,
        gramPrice: metal ? (parseNumber(gramPrice.text) ?? 0) : 0,
        bankKind: type == 'bank' ? bankKind : 'available',
        monthlyInterest: type == 'bank' && bankKind == 'certificate'
            ? (parseNumber(interest.text) ?? 0)
            : 0,
        maturity: type == 'bank' && bankKind == 'certificate' && maturity != null
            ? dayKey(maturity!)
            : '',
      ));
      if (mounted) await _load();
    }
    name.dispose();
    opening.dispose();
    grams.dispose();
    gramPrice.dispose();
    interest.dispose();
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
              // العنوان كان Expanded والمنسدلة بتاخد عرضها الطبيعى،
              // فاسم محفظة طويل كان بيخنق العنوان لحد ما يختفى.
              Row(
                children: [
                  Text(tr('من', 'From')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                    isExpanded: true,
                    value: from,
                    items: [
                      for (final e in _items)
                        DropdownMenuItem(
                            value: e.wallet.id, child: Text(e.wallet.name)),
                    ],
                    onChanged: (v) => setD(() => from = v ?? from),
                  ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(tr('إلى', 'To')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                    isExpanded: true,
                    value: to,
                    items: [
                      for (final e in _items)
                        DropdownMenuItem(
                            value: e.wallet.id, child: Text(e.wallet.name)),
                    ],
                    onChanged: (v) => setD(() => to = v ?? to),
                  ),
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
          if (_items.length >= 2)
            IconButton(
              onPressed: () => setState(() => _reordering = !_reordering),
              tooltip: _reordering
                  ? tr('خلصت الترتيب', 'Done')
                  : tr('رتّب المحافظ', 'Reorder wallets'),
              icon: Icon(_reordering ? Icons.check : Icons.swap_vert),
            ),
          if (!_reordering) searchAction(context),
          if (_items.length >= 2 && !_reordering)
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
              : _reordering
                  ? _reorderList(context)
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
                            Text(egp(_total.round()),
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
                          leading: Icon(walletTypeIcon(e.wallet.type),
                              color: walletTypeColor(e.wallet.type)),
                          title: Text(e.wallet.name),
                          subtitle: Text(_walletSub(e.wallet, e.balance)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(egp(e.balance.round()),
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
