// الشاشات والحوارات اللى المسح المولَّد (tool/sizes_test.dart) مايقدرش
// يبنيها لوحده: بتاخد معاملات إجبارية، أو بتتفتح كـ dialog / bottom sheet.
// نفس الغرض: **مفيش حاجة مقصوصة** من ٣٢٠px لحد تابلت ١٠٢٤.
//   flutter test tool/sizes_extra_test.dart
import 'package:flutter/material.dart';
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

const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'موبايل عادى 360': Size(360, 800),
  'موبايل كبير 414': Size(414, 896),
  'فولد مفتوح 673': Size(673, 841),
  'تابلت 800': Size(800, 1280),
  'تابلت كبير 1024': Size(1024, 1366),
};

bool _ignorable(Object ex) {
  final s = ex.toString();
  return s.contains('MissingPluginException') ||
      s.contains('Looking up a deactivated') ||
      s.contains('HttpException') ||
      s.contains('Invalid image data');
}

String _brief(FlutterErrorDetails d) {
  final s = d.toString();
  final of =
      RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(s);
  final loc =
      RegExp(r'file:///[^\s]*/lib/([^\s:]+\.dart):(\d+)').firstMatch(s);
  final where = loc == null ? '?' : 'lib/${loc.group(1)}:${loc.group(2)}';
  if (of != null) return 'قصّ ${of.group(1)}px ${of.group(2)} @ $where';
  return '${d.exception.toString().split("\n").first} @ $where';
}

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
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
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        if (!_ignorable(d.exception)) errs.add(_brief(d));
      };
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
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 150));
      } finally {
        FlutterError.onError = prev;
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
}
