import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/zakat_livestock.dart';

/// حاسبة زكاة الزروع والثمار + الأنعام (الغنم/البقر/الإبل).
class ZakatLivestockScreen extends StatefulWidget {
  const ZakatLivestockScreen({super.key});

  @override
  State<ZakatLivestockScreen> createState() => _ZakatLivestockScreenState();
}

class _ZakatLivestockScreenState extends State<ZakatLivestockScreen> {
  final _cropKg = TextEditingController();
  bool _withCost = false;

  final _count = TextEditingController();
  Livestock _kind = Livestock.sheep;

  @override
  void dispose() {
    _cropKg.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('زكاة الأنعام والزروع', 'Livestock & crops zakat'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _cropCard(scheme),
          _livestockCard(scheme),
          const SizedBox(height: 10),
          Text(
            tr('* الأنعام تُشترط فيها السَّوم (الرعى) وحولان الحول، والواجب '
                'يُخرَج عينًا ويجوز إخراج قيمته. حاسبة تقديرية — للتفصيل استفتِ '
                'أهل العلم.',
                '* Livestock must be grazing with a full lunar year; the due is '
                'paid in kind (its value is also allowed). An estimate — consult '
                'a scholar.'),
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── الزروع والثمار ───────────────────────────────────────────────────
  Widget _cropCard(ColorScheme scheme) {
    final kg = parseNumber(_cropKg.text) ?? 0;
    final r = cropZakat(kg, irrigatedWithCost: _withCost);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(scheme, Icons.grass_outlined,
                tr('الزروع والثمار', 'Crops & fruits')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _cropKg,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: tr('وزن المحصول (كجم)', 'Harvest weight (kg)'),
                    filled: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    label: Text(tr('سُقى بلا كلفة (١٠٪)', 'Rain-fed (10%)'))),
                ButtonSegment(
                    value: true,
                    label: Text(tr('سُقى بكلفة (٥٪)', 'Irrigated (5%)'))),
              ],
              selected: {_withCost},
              onSelectionChanged: (s) => setState(() => _withCost = s.first),
            ),
            const SizedBox(height: 12),
            _resultBox(
              scheme,
              due: r.isDue,
              title: r.isDue
                  ? tr('الزكاة المستحقة', 'Zakat due')
                  : tr('لم يبلغ النصاب — لا زكاة', 'Below nisab — no zakat'),
              value: r.isDue
                  ? tr('${arNum(r.zakatKg.toStringAsFixed(1))} كجم '
                      '(${arNum((r.rate * 100).toStringAsFixed(0))}٪)',
                      '${arNum(r.zakatKg.toStringAsFixed(1))} kg '
                      '(${arNum((r.rate * 100).toStringAsFixed(0))}%)')
                  : null,
              hint: tr('النصاب: ${arNum(kCropNisabKg.toStringAsFixed(0))} كجم '
                  '(٥ أوسق)',
                  'Nisab: ${arNum(kCropNisabKg.toStringAsFixed(0))} kg (5 wasq)'),
            ),
          ],
        ),
      ),
    );
  }

  // ── الأنعام ──────────────────────────────────────────────────────────
  Widget _livestockCard(ColorScheme scheme) {
    final n = (parseNumber(_count.text) ?? 0).toInt();
    final due = livestockZakat(_kind, n);
    final nisab = livestockNisab(_kind);
    final entered = _count.text.trim().isNotEmpty && n > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(scheme, Icons.pets_outlined, tr('الأنعام', 'Livestock')),
            const SizedBox(height: 6),
            SegmentedButton<Livestock>(
              segments: [
                ButtonSegment(
                    value: Livestock.sheep,
                    label: Text(tr('غنم', 'Sheep'))),
                ButtonSegment(
                    value: Livestock.cattle,
                    label: Text(tr('بقر', 'Cattle'))),
                ButtonSegment(
                    value: Livestock.camel,
                    label: Text(tr('إبل', 'Camels'))),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _count,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: InputDecoration(
                    labelText: tr('عدد الرؤوس', 'Number of animals'),
                    filled: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            _resultBox(
              scheme,
              due: due.isNotEmpty,
              title: due.isNotEmpty
                  ? tr('الزكاة المستحقة', 'Zakat due')
                  : (entered
                      ? tr('لم يبلغ النصاب — لا زكاة', 'Below nisab — no zakat')
                      : tr('أدخِل عدد الرؤوس', 'Enter the count')),
              value: due.isNotEmpty ? _formatDue(due) : null,
              hint: tr('النصاب: ${arNum(nisab)} رأس', 'Nisab: ${arNum(nisab)}'),
            ),
            const SizedBox(height: 10),
            Text(_kindNote(), style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant, height: 1.6)),
          ],
        ),
      ),
    );
  }

  String _formatDue(List<ZakatDueItem> due) => due
      .map((it) => it.count > 1 ? '${arNum(it.count)} ${it.label}' : it.label)
      .join(tr(' + ', ' + '));

  String _kindNote() => switch (_kind) {
        Livestock.sheep => tr(
            'من ٤٠: شاة · من ١٢١: شاتان · من ٢٠١: ٣ · ثم شاة لكل مائة.',
            'From 40: 1 · from 121: 2 · from 201: 3 · then 1 per 100.'),
        Livestock.cattle => tr(
            'تبيع = عجل عمره سنة · مسنّة = بقرة عمرها سنتان.',
            'Tabee = 1-yr calf · Musinna = 2-yr cow.'),
        Livestock.camel => tr(
            'بنت مخاض (سنة) · بنت لبون (سنتان) · حِقّة (٣ سنوات) · جَذَعة (٤).',
            'Bint makhad (1y) · bint labun (2y) · hiqqa (3y) · jadhaa (4y).'),
      };

  // ── مشترك ────────────────────────────────────────────────────────────
  Widget _header(ColorScheme scheme, IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _resultBox(ColorScheme scheme,
      {required bool due,
      required String title,
      String? value,
      String? hint}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: due
            ? scheme.primary
            : scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: due
                      ? scheme.onPrimary.withValues(alpha: .9)
                      : scheme.onSurfaceVariant)),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: due ? scheme.onPrimary : scheme.onSurface)),
            ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(hint,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: due
                          ? scheme.onPrimary.withValues(alpha: .85)
                          : scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
