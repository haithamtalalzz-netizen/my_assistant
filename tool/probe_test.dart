// فحص مركّز لشاشتين طلعوا مكسورين فى المشى العام — بيطبع الاستثناء كامل.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/screens/health/health_hub_screen.dart';
import 'package:my_assistant/screens/shell.dart';
import 'package:my_assistant/screens/worship/spiritual_stats_screen.dart';
import 'package:my_assistant/screens/worship/quran_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async => initializeDateFormatting('ar'));

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  Future<void> open(WidgetTester tester, Widget w) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(textDirection: TextDirection.rtl, child: w),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('لوحة الصحة', (tester) async {
    await seedDemoData();
    await open(tester, const HealthHubScreen());
    final ex = tester.takeException();
    expect(ex, isNull, reason: ex.toString());
  });

  testWidgets('الهيكل', (tester) async {
    await seedDemoData();
    await open(tester, const Shell());
    final ex = tester.takeException();
    expect(ex, isNull, reason: ex.toString());
  });

  testWidgets('إحصائيات روحية', (tester) async {
    await seedDemoData();
    await open(tester, const SpiritualStatsScreen());
    final ex = tester.takeException();
    expect(ex, isNull, reason: ex.toString());
  });

  testWidgets('المصحف', (tester) async {
    await seedDemoData();
    await open(tester, const MushafScreen());
    final ex = tester.takeException();
    expect(ex, isNull, reason: ex.toString());
  });
}
