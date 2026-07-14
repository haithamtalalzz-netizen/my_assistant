import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';

/// حاسبات مفيدة — كتلة الجسم، القسط، البقشيش، الخصم، محوّل الوحدات.
class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  // BMI
  final _weight = TextEditingController();
  final _height = TextEditingController();
  // قرض
  final _loanAmount = TextEditingController();
  final _loanRate = TextEditingController();
  final _loanYears = TextEditingController();
  // بقشيش
  final _bill = TextEditingController();
  double _tipPct = 10;
  // خصم
  final _price = TextEditingController();
  final _discount = TextEditingController();
  // محوّل
  final _conv = TextEditingController();
  String _convType = 'kg_lb';

  @override
  void dispose() {
    for (final c in [
      _weight, _height, _loanAmount, _loanRate, _loanYears,
      _bill, _price, _discount, _conv
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(toEnglishDigits(c.text.trim())) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('حاسبات', 'Calculators'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _bmiCard(),
          _loanCard(),
          _tipCard(),
          _discountCard(),
          _convertCard(),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );

  Widget _result(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color ?? Theme.of(context).colorScheme.primary)),
      );

  Widget _bmiCard() {
    final w = _n(_weight), h = _n(_height) / 100;
    final bmi = (h > 0) ? w / (h * h) : 0.0;
    String cat = '';
    if (bmi > 0) {
      cat = bmi < 18.5
          ? tr('نحافة', 'Underweight')
          : bmi < 25
              ? tr('وزن مثالي', 'Normal')
              : bmi < 30
                  ? tr('زيادة وزن', 'Overweight')
                  : tr('سمنة', 'Obese');
    }
    return _card(tr('كتلة الجسم (BMI)', 'Body mass (BMI)'),
        Icons.monitor_weight_outlined, [
      _num(_weight, tr('الوزن (كجم)', 'Weight (kg)')),
      _num(_height, tr('الطول (سم)', 'Height (cm)')),
      if (bmi > 0)
        _result('BMI = ${bmi.toStringAsFixed(1)} · $cat'),
    ]);
  }

  Widget _loanCard() {
    final p = _n(_loanAmount);
    final annual = _n(_loanRate) / 100;
    final months = (_n(_loanYears) * 12).round();
    double monthly = 0;
    if (p > 0 && months > 0) {
      final r = annual / 12;
      monthly = r == 0
          ? p / months
          : p * r * math.pow(1 + r, months) / (math.pow(1 + r, months) - 1);
    }
    return _card(tr('حاسبة القسط', 'Loan / installment'),
        Icons.request_quote_outlined, [
      _num(_loanAmount, tr('المبلغ (ج.م)', 'Amount (EGP)')),
      _num(_loanRate, tr('الفائدة السنوية %', 'Annual rate %')),
      _num(_loanYears, tr('عدد السنين', 'Years')),
      if (monthly > 0) ...[
        _result(tr('القسط الشهري ≈ ${egp(monthly)}',
            'Monthly ≈ ${egp(monthly)}')),
        Text(
            tr('الإجمالي ≈ ${egp(monthly * months)}',
                'Total ≈ ${egp(monthly * months)}'),
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.outline)),
      ],
    ]);
  }

  Widget _tipCard() {
    final b = _n(_bill);
    final tip = b * _tipPct / 100;
    return _card(tr('البقشيش', 'Tip'), Icons.payments_outlined, [
      _num(_bill, tr('الفاتورة (ج.م)', 'Bill (EGP)')),
      Row(children: [
        Text(tr('النسبة: ٪${arNum(_tipPct.round())}',
            'Tip: ${arNum(_tipPct.round())}%')),
        Expanded(
          child: Slider(
            value: _tipPct,
            min: 0,
            max: 25,
            divisions: 25,
            label: '${_tipPct.round()}%',
            onChanged: (v) => setState(() => _tipPct = v),
          ),
        ),
      ]),
      if (b > 0)
        _result(tr('بقشيش ${egp(tip)} · الإجمالي ${egp(b + tip)}',
            'Tip ${egp(tip)} · Total ${egp(b + tip)}')),
    ]);
  }

  Widget _discountCard() {
    final p = _n(_price), d = _n(_discount);
    final off = p * d / 100;
    return _card(tr('الخصم', 'Discount'), Icons.sell_outlined, [
      _num(_price, tr('السعر (ج.م)', 'Price (EGP)')),
      _num(_discount, tr('نسبة الخصم %', 'Discount %')),
      if (p > 0 && d > 0)
        _result(tr('بعد الخصم ${egp(p - off)} (وفّرت ${egp(off)})',
            'After ${egp(p - off)} (saved ${egp(off)})')),
    ]);
  }

  Widget _convertCard() {
    final v = _n(_conv);
    final (label, result) = switch (_convType) {
      'lb_kg' => (tr('رطل → كجم', 'lb → kg'), v * 0.453592),
      'c_f' => (tr('°م → °ف', '°C → °F'), v * 9 / 5 + 32),
      'f_c' => (tr('°ف → °م', '°F → °C'), (v - 32) * 5 / 9),
      'km_mi' => (tr('كم → ميل', 'km → mile'), v * 0.621371),
      'mi_km' => (tr('ميل → كم', 'mile → km'), v * 1.60934),
      _ => (tr('كجم → رطل', 'kg → lb'), v * 2.20462),
    };
    return _card(tr('محوّل الوحدات', 'Unit converter'),
        Icons.swap_horiz, [
      DropdownButton<String>(
        value: _convType,
        isExpanded: true,
        items: [
          DropdownMenuItem(value: 'kg_lb', child: Text(tr('كجم → رطل', 'kg → lb'))),
          DropdownMenuItem(value: 'lb_kg', child: Text(tr('رطل → كجم', 'lb → kg'))),
          DropdownMenuItem(value: 'km_mi', child: Text(tr('كم → ميل', 'km → mile'))),
          DropdownMenuItem(value: 'mi_km', child: Text(tr('ميل → كم', 'mile → km'))),
          DropdownMenuItem(value: 'c_f', child: Text(tr('°م → °ف', '°C → °F'))),
          DropdownMenuItem(value: 'f_c', child: Text(tr('°ف → °م', '°F → °C'))),
        ],
        onChanged: (x) => setState(() => _convType = x ?? _convType),
      ),
      _num(_conv, label),
      if (v != 0) _result('= ${result.toStringAsFixed(2)}'),
    ]);
  }
}
