// اسم التطبيق — **Vida** فى كل مكان ظاهر، و**ثابت** فى كل مكان مخفى.
//
// الاسم كان متناقض قبل كده: إنجليزى `My Assistant` تحت الأيقونة
// و«مساعدي» على الويب. الاختبار ده بيمنع التناقض يرجع، وبيحرس كمان
// الحاجات اللى **ماينفعش** تتغيّر.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('اسم التطبيق', () {
    test('Vida فى كل مكان المستخدم بيشوفه', () {
      expect(_read('android/app/src/main/AndroidManifest.xml'),
          contains('android:label="Vida"'),
          reason: 'الاسم تحت الأيقونة على الموبايل');
      expect(_read('lib/app.dart'), contains("title: 'Vida'"));
      expect(_read('web/manifest.json'), contains('"name": "Vida"'));
      expect(_read('web/manifest.json'), contains('"short_name": "Vida"'));
      expect(_read('web/index.html'), contains('<title>Vida</title>'));
    });

    test('مفيش أثر للاسم القديم فى أى نصّ ظاهر', () {
      // بنستثنى المسارات والمعرّفات — دى **لازم** تفضل `my_assistant`.
      final files = [
        'lib/app.dart',
        'web/index.html',
        'web/manifest.json',
        'android/app/src/main/AndroidManifest.xml',
      ];
      for (final f in files) {
        expect(_read(f), isNot(contains('My Assistant')), reason: f);
        expect(_read(f), isNot(contains('مساعدي')), reason: f);
      }
    });

    test('🔴 فحص شاشة التحميل بيطابق اسم التطبيق', () {
      // Flutter بيكتب `MaterialApp.title` فى عنوان صفحة الويب،
      // والسكريبت بيستنى التغيير ده عشان يشيل شاشة التحميل. لو الاتنين
      // اتفرقوا، شاشة التحميل بتفضل واقفة لحد ما يلاقى canvas — عطب
      // صامت مافيش اختبار تانى بيشوفه.
      final html = _read('web/index.html');
      final app = _read('lib/app.dart');
      final title =
          RegExp(r"title: '([^']+)'").firstMatch(app)?.group(1);
      expect(title, isNotNull);
      expect(html, contains("document.title === '$title'"),
          reason: 'فحص شاشة التحميل لازم يطابق MaterialApp.title');
    });

    test('هوية التطبيق وملفات البيانات **ماتغيّرتش**', () {
      // تغيير `applicationId` بيخلّى أندرويد يعتبره تطبيق تانى: تثبيت
      // جديد والبيانات القديمة ماتنتقلش. وتغيير اسم ملف القاعدة بيخلّى
      // التطبيق يفتح قاعدة فاضية.
      expect(_read('android/app/build.gradle.kts'),
          contains('applicationId = "com.hhub.my_assistant"'));
      expect(_read('pubspec.yaml'), contains('name: my_assistant'));
      expect(_read('lib/core/db.dart'), contains("'my_assistant.db'"));
      expect(_read('lib/core/json_backup.dart'),
          contains("'my_assistant_full_backup'"));
    });
  });
}
