import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/zakat.dart';
import '../../core/zakat_guide.dart';

/// دليل الزكاة — بند مستقل يشرح بنودها ومصارفها الثمانية والملزمين بها.
class ZakatGuideScreen extends StatelessWidget {
  const ZakatGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('دليل الزكاة', 'Zakat guide'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _intro(scheme),
          const SizedBox(height: 16),
          _recipientsHeader(scheme),
          const SizedBox(height: 8),
          for (final r in kZakatRecipients) _recipientTile(scheme, r),
          const SizedBox(height: 20),
          Text(
            tr('تفاصيل أكثر', 'More detail'),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          for (final s in kZakatGuideSections) _sectionTile(scheme, s),
          const SizedBox(height: 18),
          _nisabFacts(scheme),
        ],
      ),
    );
  }

  Widget _intro(ColorScheme scheme) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🕌', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('الزكاة: طُهرةٌ للمال ونماء',
                      'Zakat: purifying and growing wealth'),
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              tr('ثالث أركان الإسلام: 2.5% من صافى مالك إذا بلغ النصاب وحال '
                  'عليه الحول، تُصرف لمستحقّيها الثمانية.',
                  'The third pillar: 2.5% of your net wealth once it reaches '
                  'nisab and a lunar year passes — given to the 8 categories.'),
              style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.92),
                  height: 1.7,
                  fontSize: 13.5),
            ),
          ],
        ),
      );

  Widget _recipientsHeader(ColorScheme scheme) => Row(children: [
        Icon(Icons.groups_2_outlined, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          tr('مصارف الزكاة الثمانية (مستحقّوها)', 'The 8 recipients'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ]);

  Widget _recipientTile(ColorScheme scheme, ZakatRecipient r) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryContainer,
                child: Text(arNum(r.number),
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(r.titleAr, r.titleEn),
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(tr(r.descAr, r.descEn),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionTile(ColorScheme scheme, ZakatGuideSection s) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Text(s.emoji, style: const TextStyle(fontSize: 22)),
          title: Text(tr(s.titleAr, s.titleEn),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(tr(s.bodyAr, s.bodyEn),
                  style: const TextStyle(height: 1.9, fontSize: 14)),
            ),
          ],
        ),
      );

  Widget _nisabFacts(ColorScheme scheme) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(tr('أرقام سريعة', 'Quick figures'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            _fact(scheme, tr('نصاب الذهب', 'Gold nisab'),
                tr('${arNum(kGoldNisabGrams.toInt())} جم (عيار 24)',
                    '${arNum(kGoldNisabGrams.toInt())} g (24k)')),
            _fact(scheme, tr('نصاب الفضة', 'Silver nisab'),
                tr('${arNum(kSilverNisabGrams.toInt())} جم',
                    '${arNum(kSilverNisabGrams.toInt())} g')),
            _fact(scheme, tr('مقدار الزكاة', 'Zakat rate'),
                tr('2.5% (ربع العُشر)', '2.5% (a quarter-tenth)')),
          ],
        ),
      );

  Widget _fact(ColorScheme scheme, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: scheme.onSurfaceVariant)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
