// معاينة طقم الشكل الجديد بالثيم **الحقيقى** للتطبيق (فاتح وداكن).
// الغرض: نتأكد إن القطع شغّالة على الاتنين قبل ما نحوّل أى شاشة.
//   flutter test tool/kit_preview_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/widgets/a_kit.dart';

import 'shot_harness.dart';

const _blue = Color(0xFF3B82F6);
const _pink = Color(0xFFFF6B8A);
const _amber = Color(0xFFF2A93B);

Widget _demo() => Scaffold(
      body: SafeArea(
        child: ListView(padding: EdgeInsets.zero, children: [
          AppPad(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),
              const AppHero(
                icon: Icons.mosque,
                kicker: 'الجاية دلوقتى',
                title: 'صلاة العصر',
                trailingBig: '3:48',
                trailingSmall: 'فاضل 52 دقيقة',
                primaryLabel: 'صلّيت',
                primaryIcon: Icons.check,
                secondaryLabel: 'كل المواقيت',
                extra: AppHeroBar(0.4, '2 من 5 خلصوا النهارده'),
              ),
              const SizedBox(height: 20),
              const AppSectionTitle('خط زمنى', trailing: '2 من 4'),
              AppCard(Column(children: const [
                AppTimelineRow(
                    time: '5:12',
                    title: 'الفجر',
                    sub: 'اتصلّت',
                    tint: _blue,
                    done: true),
                AppTimelineRow(
                    time: '3:48', title: 'العصر', sub: 'الجاية', tint: _blue),
                AppTimelineRow(
                    time: '6:00',
                    title: 'د. أحمد — أسنان',
                    sub: 'عيادة المهندسين',
                    tint: _pink),
                AppTimelineRow(
                    time: '9:00',
                    title: 'جرعة الدوا',
                    sub: 'كونكور 5',
                    tint: _amber,
                    last: true),
              ])),
              const SizedBox(height: 20),
              const AppSectionTitle('قايمة', trailing: 'عرض الكل'),
              AppCard(Column(children: [
                const AppListRow(
                    check: true,
                    checked: true,
                    title: 'دفع فاتورة الغاز',
                    sub: 'خلصت 11:20 ص'),
                const AppListRow(
                    check: true,
                    title: 'دهان الأوضة',
                    sub: 'مشروع تجهيز الشقة'),
                AppListRow(
                    icon: Icons.receipt_long,
                    tint: _pink,
                    title: 'فاتورة الكهربا',
                    sub: 'مستحقة النهارده',
                    divider: false,
                    trailing: Text('320 ج.م',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _pink))),
              ])),
              const SizedBox(height: 20),
              const AppSectionTitle('مربّعات'),
            ]),
          ),
          AppPad(
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
              children: const [
                AppHubTile(
                    icon: Icons.account_balance_wallet,
                    label: 'المحفظة',
                    tint: _blue,
                    sub: '25895 ج.م'),
                AppHubTile(
                    icon: Icons.sell_outlined,
                    label: 'الديون والسلف',
                    tint: _pink,
                    sub: '3000 ليك',
                    badge: 2),
                AppHubTile(
                    icon: Icons.savings_outlined,
                    label: 'الادخار',
                    tint: _amber,
                    sub: '3 أهداف'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: const [
                AppStatChip(
                    icon: Icons.mosque, value: '0/5', label: 'الصلاة', tint: _blue),
                AppStatChip(
                    icon: Icons.favorite,
                    value: '0/2000',
                    label: 'الصحة',
                    tint: _pink),
                AppStatChip(
                    icon: Icons.account_balance_wallet,
                    value: '0 ج.م',
                    label: 'الفلوس',
                    tint: _amber),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );

void main() {
  testWidgets('طقم الشكل الجديد بالثيم الحقيقى — فاتح وداكن', (tester) async {
    await loadShotFonts();
    for (final e in {'light': buildTheme(), 'dark': buildDarkTheme()}.entries) {
      final f = await shot(tester, 'kit_${e.key}', shotApp(e.value, _demo()),
          size: const Size(390, 1010), pixelRatio: 2);
      expect(f.lengthSync(), greaterThan(10000), reason: e.key);
    }
  });
}
