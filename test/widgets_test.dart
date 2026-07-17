// اختبارات ودجت لشاشات مرحلة «قوس اليوم» — بترسم الشاشة فعلًا وبتتأكد إن
// العناصر الأساسية ظاهرة وبتتفاعل، مش بس إن الداتا مظبوطة.
//
// مهم: بنستخدم databaseFactoryFfiNoIsolate مش databaseFactoryFfi — الأخير
// بيشتغل فى isolate منفصل، والـfuture بتاعه عمره ما بيخلص جوه الزمن الوهمى
// بتاع testWidgets، فالشاشة بتفضل على لودينج وpumpAndSettle بيقعد ١٠ دقايق
// لحد ما يعمل timeout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/habits_repo.dart';
import 'package:my_assistant/screens/day_close_screen.dart';
import 'package:my_assistant/screens/habits/habits_screen.dart';
import 'package:my_assistant/screens/tasks/focus_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _app(Widget child) => MaterialApp(
      home: Directionality(
          textDirection: TextDirection.rtl, child: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  testWidgets('شاشة جلسة التركيز: العدّاد والمدد وزرار البدء ظاهرين',
      (tester) async {
    await tester.pumpWidget(_app(const FocusScreen(taskTitle: 'مذاكرة')));
    await tester.pumpAndSettle();
    expect(find.text('مذاكرة'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
    // المدد الـ٣ (١٥/٢٥/٤٥) موجودة كشيبس.
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    // البدء بيقلب الزرار لإيقاف مؤقت والعدّاد بيعدّ.
    await tester.tap(find.text('ابدأ'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('إيقاف مؤقت'), findsOneWidget);
    // إيقاف قبل نهاية التست عشان مايفضلش Timer شغال.
    await tester.tap(find.text('إيقاف مؤقت'));
    await tester.pump();
    expect(find.text('ابدأ'), findsOneWidget);
  });

  testWidgets('شاشة قفل اليوم: البنود الناقصة بتظهر وبتتسجّل بضغطة',
      (tester) async {
    // عادة واحدة ناقصة → لازم تظهر كشيبس.
    final habits = HabitsRepo();
    final id = await habits.add('قراءة');
    await tester.pumpWidget(_app(const DayCloseScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('قراءة'), findsWidgets);
    // الضغط على الشيبس بيسجّلها.
    await tester.tap(find.widgetWithText(ActionChip, 'قراءة'));
    await tester.pumpAndSettle();
    final done = await habits.doneOn(dayKey(DateTime.now()));
    expect(done.contains(id), true);
  });

  testWidgets('شاشة العادات: العادة المعدودة ليها عدّاد −/+ بيشتغل',
      (tester) async {
    await HabitsRepo().add('مياه دوا', targetPerDay: 3);
    await tester.pumpWidget(_app(const HabitsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('مياه دوا'), findsOneWidget);
    // العدّاد بيبدأ 0/3 (أرقام العرض لاتينية — قرار arNum فى core/ar.dart).
    expect(find.text('0/3'), findsOneWidget);
    // زرار + بيزوّد.
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    // زرار − بينقص.
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('0/3'), findsOneWidget);
  });
}
