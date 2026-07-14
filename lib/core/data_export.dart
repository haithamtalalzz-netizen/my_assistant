import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';

/// تصدير كل بيانات التطبيق كملف zip فيه CSV لكل جدول — يفتح فى Excel،
/// محلى ومجانى بالكامل (مفيش سحابة). للأرشفة والقراءة البشرية، مش للاستعادة
/// (للاستعادة استخدم النسخة الاحتياطية BackupService).
class DataExport {
  /// جداول داخلية منستبعدهاش من التصدير (خاصة بـ sqlite أو حساسة).
  static const _skip = {
    'android_metadata',
    'sqlite_sequence',
    'passwords', // خزنة كلمات السر — ما تتصدّرش نص صريح
  };

  /// بيبني قائمة (اسم الملف، محتوى CSV) لكل جدول فيه بيانات.
  static Future<List<({String name, String csv})>> buildCsvs() async {
    final db = await AppDb.instance;
    final tables = await db.query('sqlite_master',
        columns: ['name'],
        where: "type = 'table' AND name NOT LIKE 'sqlite_%'",
        orderBy: 'name');
    final out = <({String name, String csv})>[];
    for (final t in tables) {
      final name = t['name'] as String;
      if (_skip.contains(name)) continue;
      final rows = await db.query(name);
      if (rows.isEmpty) continue;
      out.add((name: name, csv: _tableCsv(rows)));
    }
    return out;
  }

  /// بيصدّر الكل ويفتح شاشة المشاركة (Drive / واتساب / الملفات...).
  /// بيرجّع عدد الجداول اللى اتصدّرت.
  static Future<int> exportAll() async {
    final csvs = await buildCsvs();
    final archive = Archive();
    for (final c in csvs) {
      // BOM عشان Excel يقرا العربى صح.
      final bytes = utf8.encode('﻿${c.csv}');
      archive.addFile(ArchiveFile.bytes('${c.name}.csv', bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, 'my_assistant_data_$stamp.zip'));
    await file.writeAsBytes(zipBytes);
    await Share.shareXFiles([XFile(file.path)],
        text: 'كل بيانات مساعدي (CSV لكل قسم)');
    return csvs.length;
  }

  /// بيحوّل صفوف جدول لـCSV (أول سطر = أسماء الأعمدة).
  static String _tableCsv(List<Map<String, Object?>> rows) {
    final headers = rows.first.keys.toList();
    final lines = <String>[headers.map(_esc).join(',')];
    for (final r in rows) {
      lines.add(headers.map((h) => _esc('${r[h] ?? ''}')).join(','));
    }
    return lines.join('\r\n');
  }

  static String _esc(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
