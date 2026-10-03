// الشاشات والحوارات اللى المسح المولَّد (tool/sizes_test.dart) مايقدرش
// يبنيها لوحده: بتاخد معاملات إجبارية، أو بتتفتح كـ dialog / bottom sheet.
// نفس الغرض: **مفيش حاجة مقصوصة** من ٣٢٠px لحد تابلت ١٠٢٤.
//   flutter test tool/sizes_extra_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/quran_topics.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/screens/app_drawer.dart';
import 'package:my_assistant/screens/group_hub_screen.dart';
import 'package:my_assistant/screens/home/pharmacy_form.dart';
import 'package:my_assistant/screens/home/pharmacy_screen.dart';
import 'package:my_assistant/screens/lock_gate.dart';
import 'package:my_assistant/screens/money/fixed_bills_screen.dart';
import 'package:my_assistant/screens/money/fixed_monthly_screen.dart';
import 'package:my_assistant/screens/money/money_log_screen.dart';
import 'package:my_assistant/screens/money/recurring_income_screen.dart';
import 'package:my_assistant/screens/onboarding_gate.dart';
import 'package:my_assistant/screens/onboarding_screen.dart';
import 'package:my_assistant/screens/quick_actions_settings_screen.dart';
import 'package:my_assistant/screens/tour_screen.dart';
import 'package:my_assistant/core/day_timeline.dart';
import 'package:my_assistant/models/models.dart';
import 'package:my_assistant/screens/day_full_screen.dart';
import 'package:my_assistant/screens/worship/adhkar_screen.dart';
import 'package:my_assistant/screens/worship/quran_topics_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';

const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'موبايل عادى 360': Size(360, 800),
  'موبايل كبير 414': Size(414, 896),
  'فولد مفتوح 673': Size(673, 841),
  'تابلت 800': Size(800, 1280),
  'تابلت كبير 1024': Size(1024, 1366),
};

/// المحور مقابل الطول المتاح.
List<String> _ovf(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderFlex>()) {
    if (!ro.hasSize) continue;
    var sum = 0.0;
    ro.visitChildren((c) {
      if (c is RenderBox && c.hasSize) {
        sum += ro.direction == Axis.horizontal ? c.size.width : c.size.height;
      }
    });
    final avail =
        ro.direction == Axis.horizontal ? ro.size.width : ro.size.height;
    final over = sum - avail;
    if (over <= 0.5) continue;
    final where = _creatorLine(ro);
    final dir = ro.direction == Axis.horizontal ? 'عرضاً' : 'طولاً';
    out.add('قصّ ${over.round()}px $dir @ $where');
  }
  return out.toList();
}

/// بيطلّع «lib/…:سطر» من سلسلة إنشاء الودجت، ولو مالقاش مسار بيرجّع
/// **أسماء الودجتات** بتاعة التطبيق فى السلسلة — «@ ?» لوحدها مابتفيدش.
String _creatorLine(RenderObject ro) {
  final chain = ro.debugCreator?.toString() ?? '';
  final m = RegExp(r'([\w/]+\.dart):(\d+):\d+').firstMatch(chain);
  if (m != null) return '${m.group(1)}:${m.group(2)}';
  final names = RegExp(r'([A-Z][A-Za-z0-9_]{3,})')
      .allMatches(chain)
      .map((x) => x.group(1)!)
      .where((x) => !x.startsWith('Render'))
      .toSet()
      .take(3)
      .join(' ← ');
  return names.isEmpty ? '?' : names;
}

/// القاعدة الوحيدة اللى صمدت قدام الصور هى «العرض ≈ صفر».
List<String> _hidden(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize) continue;
    final needed = ro.getMaxIntrinsicWidth(double.infinity);
    if (needed < 4 || ro.size.width >= 4) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    // 🔴 Flutter بيرسم Icon كـRichText بحرف من منطقة الاستعمال الخاص،
    // وخط الأيقونات ارتفاع سطره أكبر من مقاس الأيقونة — فأى أيقونة جوّه
    // صندوق ضيّق كانت بتتبلّغ كأنها «نصّ متقصوص»، والرسالة تطلع «» لإن
    // الحرف مالوش شكل. الأيقونة مش نصّ، فبتتعدّى.
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    out.add('نصّ مخفى (عرضه صفر): «$txt»');
  }
  return out.toList();
}

/// المسح بيحمّل Cairo فى `setUpAll` (`loadShotFonts`).
List<String> _vclip(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1) continue;
    // 🔴 القاعدة الوحيدة اللى مافيهاش لبس: **الصندوق أقصر من سطر واحد**،
    // يعنى النصّ مستحيل يبان كامل مهما كان.
    //
    // جرّبت الأوسع منها مرّتين وكانت بتكذب: `getMaxIntrinsicHeight`
    // بترجّع ارتفاع أقصى عدد سطور مسموح، و`TextPainter` بعرض الصندوق
    // بيحسب اللفّ — والاتنين بلّغوا عن كروت اللوحة وعناوين الشاشات وهى
    // ظاهرة تمام (الصور أثبتت). ده كان بيطلّع ١٣ بلاغ أغلبها كاذب.
    final line = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: 1,
      textScaler: ro.textScaler,
    )..layout();
    if (ro.size.height >= line.height - 0.5) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    // 🔴 Flutter بيرسم Icon كـRichText بحرف من منطقة الاستعمال الخاص،
    // وخط الأيقونات ارتفاع سطره أكبر من مقاس الأيقونة — فأى أيقونة جوّه
    // صندوق ضيّق كانت بتتبلّغ كأنها «نصّ متقصوص»، والرسالة تطلع «» لإن
    // الحرف مالوش شكل. الأيقونة مش نصّ، فبتتعدّى.
    if (txt.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    out.add('نصّ متقصوص طولاً (${ro.size.height.round()} من '
        '${line.height.round()}): «$txt»');
  }
  return out.toList();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  Directory('.dart_tool/sqflite_common_ffi/databases')
      .createSync(recursive: true);
  late Database db;

  setUpAll(() async {
    // من غير خطّ التطبيق، قياس العربى بيكذب.
    await loadShotFonts();
    await initializeDateFormatting('ar');
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
    await seedDemoData();
  });

  tearDownAll(() async {
    AppDb.reset();
    await db.close();
  });

  /// بيرسم الويدجت على كل المقاسات ويجمع كل قصّ بمكانه.
  /// `opener` بيتنادى بعد الرسم للحوارات والشيتات.
  Future<void> sweep(
    WidgetTester tester,
    Widget Function() build, {
    Future<void> Function(BuildContext context)? open,
  }) async {
    final found = <String, List<String>>{};
    for (final e in _sizes.entries) {
      final errs = <String>[];
      tester.takeException();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      try {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          locale: const Locale('ar'),
          home: Directionality(
              textDirection: TextDirection.rtl, child: build()),
        ));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        if (open != null) {
          final ctx = tester.element(find.byType(Scaffold).first);
          // مش await: الحوار مايرجعش لحد ما يتقفل.
          open(ctx);
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
        }
        errs
          ..addAll(_ovf(tester))
          ..addAll(_hidden(tester))
          ..addAll(_vclip(tester));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 150));
      } finally {
        tester.takeException();
      }
      for (final m in errs.toSet()) {
        found.putIfAbsent(m, () => <String>[]).add(e.key);
      }
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    if (found.isNotEmpty) {
      fail(found.entries
          .map((x) => '${x.key}   [${x.value.join(" · ")}]')
          .join('\n'));
    }
  }

  // ————— شاشات بمعاملات إجبارية —————

  testWidgets('AppDrawer (السايدبار) مفتوح', (t) async {
    final key = GlobalKey<ScaffoldState>();
    await sweep(t, () {
      return Scaffold(
        key: key,
        drawer: AppDrawer(current: 0, onSelect: (_) {}),
        body: const SizedBox.expand(),
      );
    }, open: (_) async => key.currentState?.openDrawer());
  });

  testWidgets('GroupHubScreen (هَبّة مجموعة)', (t) async {
    await sweep(
        t,
        () => GroupHubScreen(
              title: 'الصحة والرياضة والنظام الغذائى',
              accent: Colors.pink,
              onSelectTab: (_) {},
              items: [
                GroupHubItem(Icons.favorite_outline, 'الدورة الشهرية',
                    tabIndex: 1, color: Colors.pink, badge: () async => 3),
                GroupHubItem(Icons.task_alt, 'العادات اليومية المتكررة',
                    tabIndex: 3),
                GroupHubItem(Icons.medication_outlined, 'صيدلية البيت',
                    tabIndex: 2),
                GroupHubItem(Icons.fitness_center, 'مكتبة التمارين',
                    tabIndex: 0),
              ],
            ));
  });

  // نفس الهَبّة بس **بأرقامها**: السطر ساعتها بيشيل أيقونة + اسم + وصف
  // + رقم + كلمة تحت الرقم + شارة حمرا + سهم. ده أضيق صف فى التطبيق،
  // فلازم يتمسح على ٣٢٠px زى أى شاشة.
  testWidgets('GroupHubScreen (بأرقامها + شارة)', (t) async {
    await sweep(
        t,
        () => GroupHubScreen(
              title: 'المتابعة والأدوات',
              accent: Colors.blue,
              onSelectTab: (_) {},
              items: [
                // أطول تركيبة ممكنة: اسم طويل + وصف طويل + رقم + كلمة
                // تحته + شارة — كلهم فى صف واحد.
                GroupHubItem(Icons.folder_outlined, 'المستندات والأوراق الرسمية',
                    badge: () async => 2,
                    stat: () async => const HubStat(
                        sub: 'بطاقة · رخصة · عقود · شهادات',
                        big: '12',
                        bigSub: 'ورقة')),
                GroupHubItem(Icons.rule, 'قواعدى',
                    stat: () async => const HubStat(
                        sub: 'لو حصل كذا نبّهنى',
                        big: '1',
                        bigSub: 'بتتحقق',
                        bigColor: Color(0xFFEF4444))),
                GroupHubItem(Icons.event_repeat, 'التخطيط الأسبوعى',
                    stat: () async =>
                        const HubStat(sub: 'طقس 10 دقايق آخر الأسبوع')),
                const GroupHubItem(
                    Icons.emoji_events_outlined, 'المراجعة السنوية'),
              ],
            ));
  });

  testWidgets('AdhkarScreen (أذكار الصباح)',
      (t) => sweep(t, () => const AdhkarScreen(morning: true)));

  testWidgets('VersesScreen (آيات موضوع)', (t) async {
    // أطول موضوع: أكتر احتمالًا يكشف قصّ.
    final topic = kQuranTopics
        .reduce((a, b) => b.passages.length > a.passages.length ? b : a);
    await sweep(t,
        () => VersesScreen(title: topic.name, passages: topic.passages));
  });

  testWidgets('QuickActionsSettingsScreen', (t) async {
    await sweep(
        t,
        () => QuickActionsSettingsScreen(
              all: [
                for (final e in quickActionCatalog())
                  (key: e.key, icon: e.icon, label: e.label)
              ],
              enabledOrder: [
                for (final e in quickActionCatalog().take(4)) e.key
              ],
            ));
  });

  testWidgets('OnboardingScreen',
      (t) => sweep(t, () => OnboardingScreen(onDone: () {})));

  testWidgets('TourScreen', (t) => sweep(t, () => TourScreen(onDone: () {})));

  testWidgets(
      'LockGate',
      (t) => sweep(
          t, () => const LockGate(child: Scaffold(body: SizedBox.expand()))));

  // ————— حوارات (المسح المولَّد مابيفتحش حوارات) —————

  /// دوا بكل التفاصيل: أطول نصوص ممكنة = أقصى احتمال قصّ.
  const full = PharmacyItem(
    name: 'زاريلتو أقراص مضادة للتجلّط',
    strength: '20mg',
    quantity: 3,
    expiry: '2030-01-01',
    notes: 'بعد الأكل بساعة — مايتاخدش مع الأسبرين',
    form: 'أقراص',
    ingredient: 'rivaroxaban',
    place: 'دولاب الأدوية فى الأوضة',
    cold: true,
    lowAt: 5,
    person: 'بابا',
    brand: 'باير الشرق الأوسط',
    price: 250.5,
  );

  testWidgets('فورم الصيدلية — صفحة كاملة (موبايل)', (t) async {
    await sweep(t, () => const PharmacyForm(item: full));
  });

  testWidgets('فورم الصيدلية — جوّه حوار (تابلت)', (t) async {
    await sweep(
        t,
        () => Scaffold(
              body: Center(
                child: Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: const PharmacyForm(item: full, inDialog: true),
                  ),
                ),
              ),
            ));
  });

  testWidgets('فورم الصيدلية — حوار حقيقى فوق الشاشة', (t) async {
    await sweep(t, () => const PharmacyScreen(),
        open: (ctx) => showPharmacyForm(ctx, item: full));
  });

  testWidgets('DayFullScreen (يومك بالكامل)', (t) async {
    final now = DateTime.now();
    DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
    final events = [
      TimelineEvent(
          at: at(5, 10),
          title: 'الفجر',
          sub: '',
          kind: TimelineKind.prayer,
          done: true,
          id: 0),
      TimelineEvent(
          at: at(12, 48),
          title: 'الضهر',
          sub: '',
          kind: TimelineKind.prayer,
          id: 2),
      TimelineEvent(
          at: at(19, 30),
          title: 'دكتور أسنان — عيادة النصر بشارع الجمهورية',
          sub: 'موعد مهم',
          kind: TimelineKind.appointment,
          id: 5),
      TimelineEvent(
          at: at(21, 0),
          title: 'دفع فاتورة الغاز',
          sub: '',
          kind: TimelineKind.task,
          id: 7),
    ];
    await sweep(
        t,
        () => DayFullScreen(
            events: events, onOpen: (_) {}, onToggle: (e, d) async => events));
  });

  testWidgets(
      'OnboardingGate',
      (t) => sweep(t,
          () => const OnboardingGate(child: Scaffold(body: SizedBox.expand()))));

  testWidgets('RecurringIncomeScreen (دخلك الثابت)',
      (t) => sweep(t, () => const RecurringIncomeScreen()));

  testWidgets('FixedBillsScreen (فواتير ثابتة)',
      (t) => sweep(t, () => const FixedBillsScreen()));

  testWidgets('MoneyLogScreen (صرفت إيه)',
      (t) => sweep(t, () => const MoneyLogScreen(kind: MoneyLogKind.spent)));

  testWidgets('MoneyLogScreen (قبضت إيه)',
      (t) => sweep(t, () => const MoneyLogScreen(kind: MoneyLogKind.received)));

  testWidgets('FixedMonthlyScreen (اللى ثابت كل شهر)',
      (t) => sweep(t, () => const FixedMonthlyScreen()));
}
