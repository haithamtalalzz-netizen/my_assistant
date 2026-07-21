import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'ar.dart';
import 'db.dart';
import 'log.dart';

/// بند واحد فى الأرشيف — جدول اتشال من التطبيق وبياناته اتحفظت.
class ArchivedEntry {
  final String table;
  final int rowCount;
  final String archivedAt;

  const ArchivedEntry(
      {required this.table, required this.rowCount, required this.archivedAt});

  /// الاسم العربى للبند (زى ما كان ظاهر فى التطبيق قبل ما يتشال).
  String get label => kArchivedLabels[table] ?? table;
}

/// أسماء البنود اللى اتشالت — عشان المستخدم يعرف الجدول ده كان بتاع إيه.
const Map<String, String> kArchivedLabels = {
  'trips': 'السفر — الرحلات',
  'trip_items': 'السفر — قوائم الشنطة',
  'cars': 'السيارة',
  'car_events': 'السيارة — الصيانة والبنزين',
  'assets': 'أموالى الخارجية',
  'gratitude': 'مفكرة الامتنان',
  'home_inventory': 'جرد البيت',
  'leave_ledger': 'رصيد الإجازات',
  'meter_readings': 'قراءات العدادات',
  'quran_reviews': 'مراجعة القرآن',
  'renewals': 'التجديدات',
  'secret_notes': 'الخزنة السرية',
  'social_obligations': 'الواجبات الاجتماعية',
  'time_capsules': 'الكبسولة الزمنية',
  'warranties': 'الضمانات',
  'watchlist': 'قائمة المشاهدة',
};

/// قراءة وتصدير بيانات البنود اللى اتشالت من التطبيق (ترقية v59).
///
/// البيانات محفوظة جوه جدول `archived_tables` كـJSON، فبتسافر مع النسخة
/// الاحتياطية كمان. الوحدة دى بتخلّى المستخدم يشوفها ويصدّرها.
class ArchivedData {
  static const String tableName = 'archived_tables';

  static Future<bool> _exists(Database db) async {
    final r = await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]);
    return r.isNotEmpty;
  }

  /// قايمة البنود المؤرشفة (من غير الصفوف نفسها — عشان تفضل خفيفة).
  /// بترجع فاضية لو مفيش أرشيف أصلاً (جهاز اتحدّث قبل ما الأرشفة تتعمل).
  static Future<List<ArchivedEntry>> list() async {
    try {
      final db = await AppDb.instance;
      if (!await _exists(db)) return const [];
      final rows = await db.query(tableName, orderBy: 'name');
      return [
        for (final r in rows)
          ArchivedEntry(
            table: r['name'] as String,
            rowCount: (r['row_count'] as num?)?.toInt() ?? 0,
            archivedAt: (r['archived_at'] as String?) ?? '',
          ),
      ];
    } on Exception catch (e, st) {
      logError('فشلت قراءة الأرشيف', e, st);
      return const [];
    }
  }

  /// إجمالى الصفوف المحفوظة فى كل الأرشيف.
  static Future<int> totalRows() async {
    final items = await list();
    return items.fold<int>(0, (a, b) => a + b.rowCount);
  }

  /// كل الأرشيف كـJSON مقروء — بند لكل جدول جواه صفوفه.
  static Future<String> exportJson() async {
    final db = await AppDb.instance;
    if (!await _exists(db)) return '{}';
    final rows = await db.query(tableName, orderBy: 'name');
    final out = <String, dynamic>{
      'app': 'my_assistant',
      'kind': 'archived_data',
      'exported_at': DateTime.now().toIso8601String(),
      'sections': [
        for (final r in rows)
          {
            'table': r['name'],
            'label': kArchivedLabels[r['name']] ?? r['name'],
            'row_count': r['row_count'],
            'archived_at': r['archived_at'],
            'rows': jsonDecode((r['rows_json'] as String?) ?? '[]'),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// بيكتب الأرشيف فى ملف مؤقت ويفتح شاشة المشاركة.
  /// بيرجع false لو مفيش حاجة مؤرشفة.
  static Future<bool> shareExport() async {
    final items = await list();
    if (items.isEmpty) return false;
    final json = await exportJson();
    final temp = await getTemporaryDirectory();
    final file = File(p.join(
        temp.path, 'my_assistant_archived_${dayKey(DateTime.now())}.json'));
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)],
        text: 'بيانات البنود المؤرشفة — My Assistant');
    return true;
  }

  /// بيمسح الأرشيف نهائيًا (بعد ما المستخدم يصدّره ويطمن).
  /// بيرجع عدد البنود اللى اتمسحت.
  static Future<int> deleteAll() async {
    final db = await AppDb.instance;
    if (!await _exists(db)) return 0;
    final n = await db.delete(tableName);
    return n;
  }
}
