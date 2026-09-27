// لقطات للشاشات **الحقيقية** بعد التحويل — مش موك.
// بتشتغل على قاعدة فى الذاكرة ببيانات مزروعة، وبترندر الشاشة نفسها من
// `lib/screens/`، فاللى تشوفه هو اللى هيطلع على الموبايل.
//
//   flutter test tool/screen_shots_test.dart
//   → build/design_shots/real_<الشاشة>.png
//
// ⚠️ databaseFactoryFfiNoIsolate مش databaseFactoryFfi — التانى بيشتغل فى
// isolate والـfuture بتاعه عمره ما بيخلص جوّه الزمن الوهمى بتاع testWidgets،
// فالشاشة تفضل لودينج وpumpAndSettle يقعد ١٠ دقايق لحد ما يعمل timeout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:my_assistant/data/notes_repo.dart';
import 'package:my_assistant/screens/notes_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';

void main() {
  sqfliteFfiInit();
  late Database db;

  setUpAll(() async {
    await initializeDateFormatting('ar');
    await loadShotFonts();
  });

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

  testWidgets('تذكيراتى — الشكل الجديد', (tester) async {
    final repo = NotesRepo();
    final pinnedId = await repo.add('عندى بكره شغل الساعه 7:00 الصبح');
    await repo.setPinned(pinnedId, true);
    await repo.add('قائمة السوبر ماركت: زيت · رز · جبنة');
    await repo.add('رقم الفنى: 01223456789');
    await repo.add('فكرة: أعمل جدول مذاكرة للأولاد');

    final f = await shot(
      tester,
      'real_notes',
      shotApp(buildTheme(), const NotesScreen()),
      size: const Size(390, 860),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });

  testWidgets('تذكيراتى — فاضية', (tester) async {
    final f = await shot(
      tester,
      'real_notes_empty',
      shotApp(buildTheme(), const NotesScreen()),
      size: const Size(390, 760),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(10000));
  });
}
