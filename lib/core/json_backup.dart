import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'log.dart';

/// نسخة احتياطية بصيغة JSON — **بتشتغل على الويب والموبايل** لإنها SQL خالص
/// من غير أى ملفات أو مجلدات نظام.
///
/// نسخة الـzip العادية (`BackupService`) بتاخد ملف قاعدة البيانات + الصور، بس
/// دى بتحتاج نظام ملفات فمابتشتغلش فى المتصفح. الوحدة دى بتغطّى الحالة دى:
/// بتقرا كل الجداول وتحوّلها JSON، وبترجّعها تانى.
///
/// ملحوظة: الصور مش جواها (مسارات بس) — للصور استخدم نسخة الـzip على الموبايل.
class JsonBackup {
  static const int formatVersion = 1;
  static const String kind = 'my_assistant_full_backup';

  /// جداول مابتتنسخش (داخلية أو مؤقتة).
  static bool _skip(String name) =>
      name.startsWith('sqlite_') || name == 'android_metadata';

  static Future<List<String>> _tables(Database db) async {
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    return [
      for (final r in rows)
        if (!_skip(r['name'] as String)) r['name'] as String
    ];
  }

  /// كل بيانات التطبيق كـJSON.
  static Future<String> exportAll() async {
    final db = await AppDb.instance;
    final tables = await _tables(db);
    final data = <String, dynamic>{};
    var rowCount = 0;
    for (final t in tables) {
      final rows = await db.query(t);
      if (rows.isEmpty) continue; // مافيش داعى نكبّر الملف بجداول فاضية
      data[t] = rows;
      rowCount += rows.length;
    }
    return const JsonEncoder.withIndent('  ').convert({
      'kind': kind,
      'format': formatVersion,
      'db_version': await db.getVersion(),
      'exported_at': DateTime.now().toIso8601String(),
      'row_count': rowCount,
      'tables': data,
    });
  }

  /// عدد السجلات جوه نسخة (من غير ما نستعيدها) — للعرض قبل التأكيد.
  static int rowCountOf(String json) {
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final n = m['row_count'];
      if (n is int) return n;
      final tables = m['tables'] as Map<String, dynamic>? ?? {};
      return tables.values
          .fold<int>(0, (a, b) => a + (b is List ? b.length : 0));
    } on Exception {
      return 0;
    }
  }

  /// بيستعيد نسخة JSON — **بيستبدل محتوى الجداول اللى فى النسخة بس**،
  /// والباقى بيفضل زى ما هو. كله فى معاملة واحدة: يا يتم كامل يا مايتمش.
  ///
  /// بيتخطّى بأمان أى جدول أو عمود مش موجود فى الإصدار الحالى (نسخة قديمة).
  /// بيرمى [FormatException] لو الملف مش نسخة صحيحة.
  /// بيرجّع عدد السجلات اللى اترجّعت.
  static Future<int> importAll(String json) async {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(json) as Map<String, dynamic>;
    } on Exception {
      throw const FormatException('الملف ده مش نسخة احتياطية صحيحة');
    }
    if (root['kind'] != kind) {
      throw const FormatException('الملف ده مش نسخة احتياطية من التطبيق');
    }
    final tables = root['tables'];
    if (tables is! Map) {
      throw const FormatException('النسخة تالفة — مافيش بيانات جواها');
    }

    final db = await AppDb.instance;
    final existing = (await _tables(db)).toSet();
    var restored = 0;

    await db.transaction((txn) async {
      for (final entry in tables.entries) {
        final table = entry.key as String;
        final rows = entry.value;
        if (rows is! List || !existing.contains(table)) continue;

        // أعمدة الجدول الحالى — أى عمود زيادة فى النسخة بيتتجاهل.
        final info = await txn.rawQuery('PRAGMA table_info($table)');
        final cols = {for (final c in info) c['name'] as String};
        if (cols.isEmpty) continue;

        await txn.delete(table);
        for (final r in rows) {
          if (r is! Map) continue;
          final row = <String, Object?>{};
          for (final e in r.entries) {
            if (cols.contains(e.key)) row['${e.key}'] = e.value;
          }
          if (row.isEmpty) continue;
          await txn.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          restored++;
        }
      }
    });
    logInfo('استعادة JSON: $restored سجل');
    return restored;
  }
}
