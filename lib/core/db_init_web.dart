import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// على الويب: نخلّي sqflite يشتغل عن طريق sqlite3.wasm.
///
/// نستخدم النسخة اللي بتشتغل على الـmain thread (بدون Web Worker) عشان
/// `databaseFactoryFfiWeb` (الافتراضي) بيعتمد على `sqflite_sw.js` كـ worker،
/// واللي بيعلّق أحيانًا على الاستضافة الثابتة زي GitHub Pages (بيمنع فتح
/// قاعدة البيانات فالتطبيق يقف على شاشة بيضا). النسخة دي محتاجة sqlite3.wasm بس.
void initDbFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
