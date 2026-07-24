import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/gold_price.dart';
import '../../core/l10n.dart';
import '../../core/zakat.dart';
import '../../data/settings_repo.dart';
import 'zakat_guide_screen.dart';

/// حاسبة زكاة المال — أعمق وأشمل: نقود، ذهب (عدّة قطع بعيارات مختلفة)،
/// فضة، عروض تجارة، استثمارات، وديون مرجوّة لك، ناقص الديون المستحقة عليك.
/// المنطق فى `core/zakat.dart` (قابل للاختبار).
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

/// قطعة ذهب فى الواجهة: وزن (متحكّم) + عيار.
class _GoldRow {
  final TextEditingController grams;
  int karat;
  _GoldRow(this.karat) : grams = TextEditingController();
}

class _ZakatScreenState extends State<ZakatScreen> {
  static const _kGoldPriceKey = 'zakat_gold24_price';
  static const _kSilverPriceKey = 'zakat_silver_price';
  static const _kPriceDateKey = 'zakat_price_date';

  final _settings = SettingsRepo();

  String? _priceDate; // dayKey لآخر مرة اتحدّد فيها سعر الجرام
  bool _fetching = false;

  final _cash = TextEditingController();
  final _trade = TextEditingController();
  final _investments = TextEditingController();
  final _receivables = TextEditingController();
  final _debts = TextEditingController();
  final _gold24 = TextEditingController();
  final _silverGrams = TextEditingController();
  final _silverPrice = TextEditingController();

  final List<_GoldRow> _gold = [_GoldRow(21)];
  NisabBasis _basis = NisabBasis.gold;

  double _n(TextEditingController c) => parseNumber(c.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _restorePrices();
  }

  Future<void> _restorePrices() async {
    final g = await _settings.get(_kGoldPriceKey);
    final s = await _settings.get(_kSilverPriceKey);
    final d = await _settings.get(_kPriceDateKey);
    if (!mounted) return;
    setState(() {
      if (g != null && g.isNotEmpty) _gold24.text = g;
      if (s != null && s.isNotEmpty) _silverPrice.text = s;
      if (d != null && d.isNotEmpty) _priceDate = d;
    });
  }

  /// يسجّل إن سعر الجرام اتحدّد النهارده (بجلب أو بإدخال يدوى).
  void _stampPriceDate() {
    _priceDate = dayKey(DateTime.now());
    _settings.set(_kPriceDateKey, _priceDate!);
  }

  /// يجلب سعر الذهب/الفضة من البورصة العالمية ويملأ الحقول.
  Future<void> _fetchPrice() async {
    setState(() => _fetching = true);
    final res = await GoldPriceService.fetch();
    if (!mounted) return;
    setState(() => _fetching = false);
    final p = res.prices;
    if (p == null) {
      final why = res.diag == null ? '' : ' (${res.diag})';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(
              'تعذّر جلب السعر — تأكد من الإنترنت أو أدخله يدويًا.$why',
              'Couldn’t fetch the price — check your connection or enter it manually.$why'))));
      return;
    }
    _gold24.text = p.gold24EgpPerGram.toStringAsFixed(2);
    _silverPrice.text = p.silverEgpPerGram.toStringAsFixed(2);
    _settings.set(_kGoldPriceKey, _gold24.text);
    _settings.set(_kSilverPriceKey, _silverPrice.text);
    _stampPriceDate();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(
            'عيار 24 ≈ ${egp(p.gold24EgpPerGram)}/جم · الفضة ≈ ${egp(p.silverEgpPerGram)}/جم',
            '24k ≈ ${egp(p.gold24EgpPerGram)}/g · silver ≈ ${egp(p.silverEgpPerGram)}/g'))));
  }

  @override
  void dispose() {
    for (final c in [
      _cash,
      _trade,
      _investments,
      _receivables,
      _debts,
      _gold24,
      _silverGrams,
      _silverPrice,
    ]) {
      c.dispose();
    }
    for (final r in _gold) {
      r.grams.dispose();
    }
    super.dispose();
  }

  ZakatInput _buildInput() => ZakatInput(
        cash: _n(_cash),
        gold: [
          for (final r in _gold)
            GoldHolding(grams: parseNumber(r.grams.text) ?? 0, karat: r.karat),
        ],
        gold24Price: _n(_gold24),
        silverGrams: _n(_silverGrams),
        silverPricePerGram: _n(_silverPrice),
        trade: _n(_trade),
        investments: _n(_investments),
        receivables: _n(_receivables),
        debts: _n(_debts),
        nisabBasis: _basis,
      );

  void _addGold() => setState(() => _gold.add(_GoldRow(21)));

  void _removeGold(int i) => setState(() {
        _gold.removeAt(i).grams.dispose();
      });

  void _openGuide() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ZakatGuideScreen()));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = computeZakat(_buildInput());

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('حاسبة الزكاة', 'Zakat calculator')),
        actions: [
          IconButton(
            tooltip: tr('دليل الزكاة', 'Zakat guide'),
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: _openGuide,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _resultCard(scheme, r),
          const SizedBox(height: 14),

          // النقود
          _sectionCard(scheme, Icons.payments_outlined, tr('النقود', 'Cash'), [
            _field(_cash, tr('كاش + أرصدة بنكية + مدّخرات',
                'Cash + bank + savings')),
          ]),

          // الذهب
          _goldCard(scheme, r),

          // الفضة
          _sectionCard(
              scheme, Icons.brightness_low_outlined, tr('الفضة', 'Silver'), [
            _field(_silverGrams, tr('وزن الفضة (جرام)', 'Silver weight (g)')),
            _field(
              _silverPrice,
              tr('سعر جرام الفضة', 'Silver gram price'),
              onChanged: (v) => _settings.set(_kSilverPriceKey, v),
            ),
          ]),

          // أصول أخرى
          _sectionCard(scheme, Icons.storefront_outlined,
              tr('أصول أخرى', 'Other assets'), [
            _field(_trade,
                tr('عروض التجارة (قيمة البضاعة)', 'Trade goods (stock value)')),
            _field(_investments,
                tr('أسهم واستثمارات للمتاجرة', 'Shares & trading investments')),
            _field(_receivables,
                tr('ديون مرجوّة لك (يغلب رجوعها)', 'Debts owed to you')),
          ]),

          // المخصوم
          _sectionCard(scheme, Icons.remove_circle_outline,
              tr('يُطرح', 'Deductions'), [
            _field(_debts,
                tr('ديون ومصروفات مستحقة عليك الآن', 'Debts due on you now')),
          ]),

          // أساس النصاب
          _basisCard(scheme),

          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openGuide,
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(tr('دليل الزكاة ومصارفها وبنودها',
                'Guide: recipients & rulings')),
          ),
          const SizedBox(height: 10),
          Text(
            tr('* الزكاة تجب بعد بلوغ النصاب وحولان الحول (مرور سنة هجرية). '
                'هذه حاسبة تقديرية، ولمسائل حالتك استفتِ أهل العلم.',
                '* Zakat is due after reaching nisab and a full lunar year. '
                'This is an estimate — consult a scholar for your case.'),
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── النتيجة ──────────────────────────────────────────────────────────
  Widget _resultCard(ColorScheme scheme, ZakatResult r) {
    final due = r.isDue;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: due
            ? LinearGradient(
                colors: [scheme.primary, scheme.primary.withValues(alpha: .78)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft)
            : null,
        color: due ? null : scheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('صافى المال الزكوى', 'Net zakatable wealth'),
              style: TextStyle(
                  color: due
                      ? scheme.onPrimary.withValues(alpha: .9)
                      : scheme.onSurfaceVariant)),
          Text(egp(r.zakatable),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: due ? scheme.onPrimary : scheme.onSurface)),
          if (r.nisabValue > 0) ...[
            const SizedBox(height: 8),
            Text(
              tr('النصاب: ${egp(r.nisabValue)}', 'Nisab: ${egp(r.nisabValue)}'),
              style: TextStyle(
                  fontSize: 12,
                  color: due
                      ? scheme.onPrimary.withValues(alpha: .9)
                      : scheme.onSurfaceVariant),
            ),
          ],
          const Divider(height: 22),
          Text(
            due
                ? tr('الزكاة المستحقة (2.5%)', 'Zakat due (2.5%)')
                : (r.nisabValue == 0
                    ? tr('أدخِل سعر جرام الذهب لحساب النصاب',
                        'Enter gold gram price for nisab')
                    : tr('لم يبلغ النصاب — لا زكاة', 'Below nisab — no zakat')),
            style: TextStyle(
                color: due
                    ? scheme.onPrimary.withValues(alpha: .9)
                    : scheme.onSurfaceVariant),
          ),
          if (due)
            Text(egp(r.zakatDue),
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: scheme.onPrimary)),
        ],
      ),
    );
  }

  // ── قسم عام ─────────────────────────────────────────────────────────
  Widget _sectionCard(ColorScheme scheme, IconData icon, String title,
          List<Widget> children) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      );

  // ── الذهب ───────────────────────────────────────────────────────────
  Widget _goldCard(ColorScheme scheme, ZakatResult r) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.diamond_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('الذهب', 'Gold'),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ]),
              _goldPriceBlock(scheme),
              const SizedBox(height: 4),
              for (int i = 0; i < _gold.length; i++) _goldRow(scheme, i),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _addGold,
                  icon: const Icon(Icons.add),
                  label: Text(tr('إضافة قطعة ذهب', 'Add gold item')),
                ),
              ),
              if (r.goldValue > 0)
                Text(
                  tr('إجمالى الذهب: ${egp(r.goldValue)} · خالص مكافئ: '
                      '${arNum(r.pureGoldGrams.toStringAsFixed(1))} جم',
                      'Gold total: ${egp(r.goldValue)} · pure eq.: '
                      '${arNum(r.pureGoldGrams.toStringAsFixed(1))} g'),
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      );

  /// حقل سعر جرام الذهب + زر جلب السعر العالمى + آخر تحديث.
  Widget _goldPriceBlock(ColorScheme scheme) {
    final stale = _priceDate != null && _priceDate != dayKey(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          _gold24,
          tr('سعر جرام الذهب اليوم (عيار 24)', 'Today’s gold gram price (24k)'),
          onChanged: (v) {
            _settings.set(_kGoldPriceKey, v);
            _stampPriceDate();
          },
        ),
        Row(children: [
          if (_fetching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _fetchPrice,
              icon: const Icon(Icons.public, size: 18),
              label: Text(tr('جلب سعر السوق العالمى', 'Fetch world price')),
            ),
          const Spacer(),
          if (_priceDate != null)
            Text(
              tr('آخر تحديث: ${_priceDateDisplay()}',
                  'Updated: ${_priceDateDisplay()}'),
              style: TextStyle(
                  fontSize: 11,
                  color: stale ? scheme.error : scheme.onSurfaceVariant),
            ),
        ]),
        Text(
          tr('السعر العالمى استرشادى — عدّله لسعر السوق المحلى لو لزم.',
              'The world price is a reference — adjust to your local market.'),
          style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _priceDateDisplay() {
    try {
      return arShortDate(DateTime.parse(_priceDate!));
    } on FormatException {
      return _priceDate ?? '';
    }
  }

  Widget _goldRow(ColorScheme scheme, int i) {
    final row = _gold[i];
    final price = _n(_gold24);
    final grams = parseNumber(row.grams.text) ?? 0;
    final value = price > 0
        ? grams * price * karatPurity(row.karat)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.grams,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tr('الوزن (جرام)', 'Weight (g)'),
                    isDense: true,
                    filled: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: row.karat,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final k in kGoldKarats)
                      DropdownMenuItem(
                          value: k,
                          child: Text(tr('عيار $k', '${k}k'))),
                  ],
                  onChanged: (v) =>
                      setState(() => row.karat = v ?? row.karat),
                ),
              ),
              IconButton(
                tooltip: tr('حذف', 'Remove'),
                icon: Icon(Icons.close, size: 20, color: scheme.error),
                onPressed: _gold.length == 1 ? null : () => _removeGold(i),
              ),
            ],
          ),
          if (value > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                tr('≈ ${egp(value)}', '≈ ${egp(value)}'),
                style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  // ── أساس النصاب ─────────────────────────────────────────────────────
  Widget _basisCard(ColorScheme scheme) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.straighten_outlined,
                    size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('أساس النصاب', 'Nisab basis'),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              SegmentedButton<NisabBasis>(
                segments: [
                  ButtonSegment(
                      value: NisabBasis.gold,
                      label: Text(tr('ذهب (85جم)', 'Gold (85g)'))),
                  ButtonSegment(
                      value: NisabBasis.silver,
                      label: Text(tr('فضة (595جم)', 'Silver (595g)'))),
                ],
                selected: {_basis},
                onSelectionChanged: (s) => setState(() => _basis = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                tr('نصاب الفضة أقل قيمةً، فاختياره أنفع للفقير وأحوط.',
                    'The silver nisab is lower — choosing it is safer and more '
                    'beneficial to the poor.'),
                style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );

  Widget _field(TextEditingController c, String label,
          {void Function(String)? onChanged}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, filled: true),
          onChanged: (v) {
            onChanged?.call(v);
            setState(() {});
          },
        ),
      );
}
