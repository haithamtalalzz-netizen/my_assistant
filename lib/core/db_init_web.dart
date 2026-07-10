import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// على الويب: نخلّي sqflite يشتغل عن طريق IndexedDB + sqlite3.wasm.
void initDbFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
