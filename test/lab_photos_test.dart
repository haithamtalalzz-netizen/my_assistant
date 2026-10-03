// صور ورقة التحليل — بتتحفظ، بتترجع، وبتتمسح لما تتشال.
//
// الجزء اللى بيبوظ فى صمت هو **التنظيف**: على الويب الصورة بتتخزّن جوّه
// القاعدة نفسها (`app_images`)، فصورة اتشالت من الورقة وفضلت فى المخزن
// بتتحمل فى كل نسخة احتياطية وهى مالهاش صاحب. مفيش شاشة هتوريك ده.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/app_images.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/data/lab_results_repo.dart';
import 'package:my_assistant/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  final repo = LabResultsRepo();

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  /// صورة وهمية متخزّنة جوّه القاعدة — بترجّع مفتاحها `img:<key>`.
  Future<String> fakePhoto() =>
      AppImages.storeBytes(Uint8List.fromList(const [1, 2, 3, 4]));

  Future<int> imagesCount() async =>
      (await db.query(AppImages.table)).length;

  LabResult sugar({int? id, List<String> photos = const []}) => LabResult(
        id: id,
        name: 'سكر صائم',
        value: 95,
        unit: 'mg/dL',
        date: '2026-10-01',
        refLow: '70',
        refHigh: '100',
        photos: photos,
        createdAt: DateTime.now().toIso8601String(),
      );

  test('الصور بتتحفظ مع النتيجة وبترجع معاها', () async {
    final a = await fakePhoto();
    final b = await fakePhoto();
    await repo.save(sugar(photos: [a, b]));

    final back = (await repo.all()).single;
    expect(back.photos, [a, b]);
  });

  test('نتيجة من غير صور بترجّع لستة فاضية مش سطر فاضى', () async {
    // `''.split('\n')` بيرجّع `['']` — ودى بتبقى «صورة» مسارها فاضى،
    // فبيطلع مربّع مكسور فى الشاشة.
    await repo.save(sugar());
    expect((await repo.all()).single.photos, isEmpty);
  });

  test('نتيجة قديمة (قبل عمود الصور) بتفضل شغّالة', () async {
    // ١٢ عمود قديم من غير `photos` — الصف ده شكل بيانات المستخدمين
    // اللى على الويب قبل الهجرة.
    await db.insert('lab_results', {
      'name': 'هيموجلوبين',
      'value': 13.5,
      'unit': 'g/dL',
      'date': '2026-09-01',
      'created_at': DateTime.now().toIso8601String(),
    });
    final back = (await repo.all()).single;
    expect(back.photos, isEmpty);
    expect(back.value, 13.5);
  });

  test('شيل صورة من ورقة ← بتتمسح من المخزن', () async {
    final a = await fakePhoto();
    final b = await fakePhoto();
    final id = await repo.save(sugar(photos: [a, b]));
    expect(await imagesCount(), 2);

    // شال الصورة التانية بس.
    await repo.save(sugar(id: id, photos: [a]));

    expect((await repo.all()).single.photos, [a]);
    expect(await imagesCount(), 1, reason: 'الصورة المشالة مالهاش صاحب');
    expect(await AppImages.bytesOf(a), isNotNull, reason: 'الباقية ماتتلمسش');
  });

  test('امسح النتيجة ← صورها بتروح معاها', () async {
    final a = await fakePhoto();
    final id = await repo.save(sugar(photos: [a]));
    expect(await imagesCount(), 1);

    await repo.delete(id);

    expect(await repo.all(), isEmpty);
    expect(await imagesCount(), 0);
  });

  test('تعديل من غير ما تلمس الصور مابيمسحش حاجة', () async {
    final a = await fakePhoto();
    final id = await repo.save(sugar(photos: [a]));
    await repo.save(LabResult(
      id: id,
      name: 'سكر صائم',
      value: 88, // القيمة بس اللى اتغيّرت
      unit: 'mg/dL',
      date: '2026-10-01',
      photos: [a],
      createdAt: DateTime.now().toIso8601String(),
    ));
    expect(await imagesCount(), 1);
    expect((await repo.all()).single.value, 88);
  });

  test('صورتين فى نفس اللحظة = مفتاحين مختلفين', () async {
    // على الويب `DateTime.now()` دقّته ملّى ثانية، و«اختار كذا صورة»
    // بيحفظهم فى لوب. لما المفتاح كان الوقت لوحده، التانية كانت
    // بتضرب فى `UNIQUE` وتضيع.
    final keys = <String>{};
    for (var i = 0; i < 20; i++) {
      keys.add(await AppImages.storeBytes(Uint8List.fromList([i])));
    }
    expect(keys.length, 20);
    expect(await imagesCount(), 20);
  });
}
