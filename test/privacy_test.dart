// وضع الخصوصية — «محدش يشوف بياناتى».
//
// الاختبار المهم هنا مش إن الضبابة بتترسم، ده الصورة بتقوله. المهم إن
// المضبّب **مابيتداسش**: ضبابة بتتداس مش ضبابة — دوسة واحدة بتفتح صفحة
// جوّه فيها نفس الرقم واضح.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/privacy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
    Privacy.hidden.value = false;
  });

  tearDown(() async {
    Privacy.hidden.value = false;
    AppDb.reset();
    await db.close();
  });

  test('القفل بيتحفظ ويرجع بعد إعادة التشغيل', () async {
    expect(Privacy.hidden.value, isFalse);

    await Privacy.toggle();
    expect(Privacy.hidden.value, isTrue);

    // بنحاكى قفلة التطبيق وفتحه: الحالة بترجع من الإعدادات.
    // لو مكانتش بتتحفظ، قفلة وفتحة بتكشف كل حاجة — وده بالظبط اللى
    // بيحصل لما حد ياخد الموبايل ويقفل التطبيق ويفتحه.
    Privacy.hidden.value = false;
    await Privacy.load();
    expect(Privacy.hidden.value, isTrue);

    await Privacy.toggle();
    Privacy.hidden.value = true;
    await Privacy.load();
    expect(Privacy.hidden.value, isFalse);
  });

  testWidgets('مقفول: المحتوى بيتضبّب و**مابيتداسش**', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PrivacyBlur(
            ElevatedButton(
                onPressed: () => taps++, child: const Text('الرصيد')),
          ),
        ),
      ),
    ));

    // مفتوح: الدوسة بتوصل.
    await tester.tap(find.text('الرصيد'));
    expect(taps, 1);
    expect(find.byType(ImageFiltered), findsNothing,
        reason: 'مفيش ضبابة وهو مفتوح');

    // مقفول: الضبابة بتترسم **والدوسة مابتوصلش**.
    Privacy.hidden.value = true;
    await tester.pump();
    expect(find.byType(ImageFiltered), findsOneWidget);

    await tester.tap(find.text('الرصيد'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 1,
        reason: 'المضبّب لازم يبقى ميّت — ولا الضبابة بتبقى ستارة على '
            'باب مفتوح: دوسة بتفتح صفحة فيها نفس الرقم واضح');

    // وبيرجع يشتغل لما يتفتح.
    Privacy.hidden.value = false;
    await tester.pump();
    await tester.tap(find.text('الرصيد'));
    expect(taps, 2);
  });

  testWidgets('الزرار بيقلب الحالة وبيغيّر أيقونته', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(appBar: null, body: PrivacyAction()),
    ));

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(Privacy.hidden.value, isTrue);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget,
        reason: 'الأيقونة لازم تقول إنها مقفولة — من غير كده هتفتكرها '
            'مقفولة وهى مفتوحة');
  });
}
