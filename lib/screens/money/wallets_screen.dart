import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/wallets_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/search_action.dart';
import '../../core/privacy.dart';

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
    await _repo.adoptLegacyMetalPrices();
    await MetalPrices.load(force: true);
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

  /// **سعر الجرام — واحد لكل معدن.**
  ///
  /// تحدّثه مرة وكل قطع الذهب (أو الفضة) تتحسب من جديد، بدل ما تعدّل
  /// كل قطعة لوحدها.
  List<Widget> _metalPriceCards(BuildContext context) {
    final types = <String>{
      for (final e in _items)
        if (isMetalWallet(e.wallet.type)) e.wallet.type
    }.toList()
      ..sort();
    if (types.isEmpty) return const [];
    final scheme = Theme.of(context).colorScheme;
    return [
      const SizedBox(height: 8),
      for (final t in types)
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            leading: Icon(walletTypeIcon(t), color: walletTypeColor(t)),
            title: Text(tr(
                'سعر جرام ${walletTypeLabel(t)} ${metalKaratLabel(t, metalBaseKarat(t))}',
                '${walletTypeLabel(t)} price per gram')),
            subtitle: Text(MetalPrices.of(t) > 0
                ? tr('كل قطعك بتتحسب منه', 'All your pieces use it')
                : tr('مااتحطّش لسه — كل قطعة بسعرها',
                    'Not set — each piece uses its own')),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  MetalPrices.of(t) > 0
                      ? arMoney(MetalPrices.of(t).round())
                      : '—',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: walletTypeColor(t))),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 17, color: scheme.outline),
            ]),
            onTap: () => _editMetalPrice(t),
          ),
        ),
    ];
  }

  Future<void> _editMetalPrice(String type) async {
    final c = TextEditingController(
        text: MetalPrices.of(type) > 0
            ? MetalPrices.of(type).toStringAsFixed(0)
            : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(
            'سعر جرام ${walletTypeLabel(type)} ${metalKaratLabel(type, metalBaseKarat(type))}',
            '${walletTypeLabel(type)} price per gram')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: tr('سعر السوق النهاردة', "Today's market price"),
            helperText: tr('كل قطع ${walletTypeLabel(type)} هتتحسب منه',
                'All your pieces will use it'),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
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
    if (ok == true) {
      await MetalPrices.set(type, parseNumber(c.text) ?? 0);
      if (mounted) await _load();
    }
    c.dispose();
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
    final result = await showDialog<Wallet>(
      context: context,
      builder: (_) => _WalletDialog(initial: w),
    );
    if (result == null) return;
    await _repo.save(result);
    if (mounted) await _load();
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
          const PrivacyAction(),
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
                    ..._metalPriceCards(context),
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


/// **حوار المحفظة** — ودجت بحالها عشان تملك خاناتها وتتخلّص منها بنفسها.
///
/// 🔴 قبل كده الخانات كانت بتتعمل جوّه `_walletForm` وتتمسح أول ما
/// `showDialog` ترجع — والحوار وقتها لسه بيترسم وهو بيقفل (أنيميشن
/// الخروج)، فبيستعمل خانة اتمسحت. الودجت هنا بتتخلّص منها فى `dispose`
/// بتاعها، يعنى بعد ما الحوار يختفى فعلاً.
///
/// بترجّع [Wallet] جاهزة للحفظ، أو null لو اتلغى.
class _WalletDialog extends StatefulWidget {
  final Wallet? initial;
  const _WalletDialog({this.initial});

  @override
  State<_WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<_WalletDialog> {
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late final TextEditingController _grams;
  late final TextEditingController _gramPrice;
  late final TextEditingController _interest;

  late String _type;
  late double _karat;
  late String _bankKind;
  DateTime? _maturity;

  /// الحفظ كان بيتجاهل المحفظة **بصمت** لو الاسم فاضى: الحوار يقفل وكأن
  /// الحفظ تمّ، والمحفظة ماتتضافش ومحدش يقولك ليه.
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final w = widget.initial;
    _name = TextEditingController(text: w?.name ?? '');
    _opening = TextEditingController(
        text: w == null || w.openingBalance == 0
            ? ''
            : w.openingBalance.toStringAsFixed(0));
    _grams = TextEditingController(
        text: w == null || w.grams == 0 ? '' : w.grams.toStringAsFixed(0));
    _gramPrice = TextEditingController(
        text: w == null || w.gramPrice == 0
            ? ''
            : w.gramPrice.toStringAsFixed(0));
    _interest = TextEditingController(
        text: w == null || w.monthlyInterest == 0
            ? ''
            : w.monthlyInterest.toStringAsFixed(0));
    _type = w?.type ?? kWalletTypes.first;
    _karat = w != null && w.karat > 0 ? w.karat : metalKarats(_type).first;
    _bankKind = w?.bankKind ?? kBankKinds.first;
    _maturity =
        w == null || w.maturity.isEmpty ? null : DateTime.tryParse(w.maturity);
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _grams.dispose();
    _gramPrice.dispose();
    _interest.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      // الحوار بيفضل مفتوح والسبب مكتوب تحت الخانة.
      setState(() => _nameError = tr('اكتب اسم للمحفظة', 'Give it a name'));
      return;
    }
    final metal = isMetalWallet(_type);
    Navigator.pop(
      context,
      Wallet(
        id: widget.initial?.id,
        name: _name.text.trim(),
        type: _type,
        openingBalance: metal ? 0 : (parseNumber(_opening.text) ?? 0),
        grams: metal ? (parseNumber(_grams.text) ?? 0) : 0,
        karat: metal ? _karat : 0,
        gramPrice: metal && MetalPrices.of(_type) <= 0
            ? (parseNumber(_gramPrice.text) ?? 0)
            : 0,
        bankKind: _type == 'bank' ? _bankKind : 'available',
        monthlyInterest: _type == 'bank' && _bankKind == 'certificate'
            ? (parseNumber(_interest.text) ?? 0)
            : 0,
        maturity:
            _type == 'bank' && _bankKind == 'certificate' && _maturity != null
                ? dayKey(_maturity!)
                : '',
        sortOrder: widget.initial?.sortOrder ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.initial;
    final metal = isMetalWallet(_type);
    final shared = MetalPrices.of(_type);
    // القيمة بتتحدّث وأنت بتكتب — عشان تشوف الحساب قبل ما تحفظ.
    final live = metalValue(
        type: _type,
        grams: parseNumber(_grams.text) ?? 0,
        karat: _karat,
        gramPrice: shared > 0 ? shared : (parseNumber(_gramPrice.text) ?? 0));

    return AlertDialog(
      scrollable: true,
      title: Text(
          w == null ? tr('محفظة جديدة', 'New wallet') : tr('تعديل', 'Edit')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _name,
          autofocus: w == null,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          decoration: InputDecoration(
            labelText: tr('الاسم (كاش · بنك مصر · ذهب الفرح…)',
                'Name (cash, bank, gold…)'),
            errorText: _nameError,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final t in kWalletTypes)
            ChoiceChip(
              label: Text(walletTypeLabel(t)),
              selected: _type == t,
              onSelected: (_) => setState(() {
                _type = t;
                if (isMetalWallet(t)) _karat = metalKarats(t).first;
              }),
            ),
        ]),
        const SizedBox(height: 10),

        // ——— ذهب / فضة: الوزن والعيار وسعر الجرام ———
        if (metal) ...[
          TextField(
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
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
            for (final k in metalKarats(_type))
              ChoiceChip(
                label: Text(metalKaratLabel(_type, k)),
                selected: _karat == k,
                onSelected: (_) => setState(() => _karat = k),
              ),
          ]),
          const SizedBox(height: 10),
          // السعر واحد لكل معدن فوق فى القايمة — هنا بنقول بس بيتحسب
          // بكام، عشان مايبقاش رقمين متعارضين.
          if (shared > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                  tr('بيتحسب بسعر ${arMoney(shared.round())} للجرام — تعدّله من فوق',
                      'Uses ${arMoney(shared.round())}/g — edit it above'),
                  style: const TextStyle(fontSize: 11.5)),
            )
          else
            TextField(
              controller: _gramPrice,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('سعر جرام السوق', 'Market price per gram'),
                helperText: tr('هيبقى سعر كل قطعك من النوع ده',
                    'Will apply to all your pieces'),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: walletTypeColor(_type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('قيمتها', 'Its value'),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(live > 0 ? arMoney(live.round()) : '—',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: walletTypeColor(_type))),
              Text(tr('الوزن × سعر الجرام × نقاوة العيار',
                  'grams × price × purity'),
                  style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ]

        // ——— بنك: متاح ولا شهادة ———
        else ...[
          if (_type == 'bank') ...[
            Wrap(spacing: 6, children: [
              for (final b in kBankKinds)
                ChoiceChip(
                  label: Text(bankKindLabel(b)),
                  selected: _bankKind == b,
                  onSelected: (_) => setState(() => _bankKind = b),
                ),
            ]),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _opening,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: _type == 'bank' && _bankKind == 'certificate'
                    ? tr('قيمة الشهادة', 'Certificate amount')
                    : isValueOnlyWallet(_type)
                        ? tr('قيمتها التقديرية', 'Estimated value')
                        : tr('الرصيد الحالى', 'Current balance')),
          ),
          if (_type == 'bank' && _bankKind == 'certificate') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _interest,
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
                  context: context,
                  initialDate:
                      _maturity ?? DateTime(now.year + 1, now.month, now.day),
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 30),
                );
                if (d != null) setState(() => _maturity = d);
              },
              icon: const Icon(Icons.event, size: 18),
              label: Text(_maturity == null
                  ? tr('تاريخ انتهاء الشهادة', 'Maturity date')
                  : tr('تنتهى ${arShortDate(_maturity!)}',
                      'Matures ${arShortDate(_maturity!)}')),
            ),
          ],
        ],
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('إلغاء', 'Cancel'))),
        FilledButton(onPressed: _save, child: Text(tr('حفظ', 'Save'))),
      ],
    );
  }
}
