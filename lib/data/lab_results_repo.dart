import '../core/db.dart';
import '../models/models.dart';

/// تحليل شائع بوحدته ونطاقه الطبيعى الافتراضى — عشان يتملى تلقائى عند الاختيار.
class LabTestSpec {
  final String name;
  final String unit;
  final String low;
  final String high;
  const LabTestSpec(this.name, this.unit, this.low, this.high);
}

/// تحاليل مصرية/عامة شائعة + نطاقاتها التقريبية (للأدوات الاسترشادية فقط —
/// النطاق الفعلى بيرجع لمعمل التحليل). محلى بالكامل.
const List<LabTestSpec> kCommonLabTests = [
  LabTestSpec('سكر صائم', 'mg/dL', '70', '100'),
  LabTestSpec('سكر فاطر', 'mg/dL', '70', '140'),
  LabTestSpec('تراكمى HbA1c', '%', '4', '5.6'),
  LabTestSpec('كوليسترول كلى', 'mg/dL', '', '200'),
  LabTestSpec('كوليسترول ضار LDL', 'mg/dL', '', '130'),
  LabTestSpec('كوليسترول نافع HDL', 'mg/dL', '40', ''),
  LabTestSpec('دهون ثلاثية', 'mg/dL', '', '150'),
  LabTestSpec('هيموجلوبين', 'g/dL', '12', '17'),
  LabTestSpec('فيتامين د', 'ng/mL', '30', '100'),
  LabTestSpec('حديد', 'µg/dL', '60', '170'),
  LabTestSpec('كرياتينين', 'mg/dL', '0.6', '1.3'),
  LabTestSpec('حمض اليوريك', 'mg/dL', '3.5', '7.2'),
  LabTestSpec('TSH الغدة الدرقية', 'mIU/L', '0.4', '4'),
  LabTestSpec('ضغط الدم الانقباضى', 'mmHg', '90', '120'),
  LabTestSpec('فيتامين B12', 'pg/mL', '200', '900'),
];

/// ملخّص التحاليل فى شهر.
class LabMonthSummary {
  final int logged;
  final int outOfRange;

  /// تحاليل رجعت للنطاق الطبيعى بعد ما كانت بره.
  final List<String> improved;

  /// تحاليل خرجت عن النطاق بعد ما كانت طبيعية.
  final List<String> worsened;

  const LabMonthSummary({
    required this.logged,
    required this.outOfRange,
    required this.improved,
    required this.worsened,
  });

  bool get isEmpty => logged == 0;
}

/// مؤشرات التحاليل الطبية — نتائج بقيمها ونطاقاتها لتتبّع الاتجاه عبر الزمن.
class LabResultsRepo {
  Future<List<LabResult>> all() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('lab_results', orderBy: 'name, date DESC, id DESC');
    return rows.map(LabResult.fromMap).toList();
  }

  /// كل نتائج تحليل باسمه، مرتّبة بالتاريخ تصاعدياً (للرسم البيانى).
  Future<List<LabResult>> forName(String name) async {
    final db = await AppDb.instance;
    final rows = await db.query('lab_results',
        where: 'name = ?', whereArgs: [name], orderBy: 'date, id');
    return rows.map(LabResult.fromMap).toList();
  }

  /// أسماء التحاليل المتسجّلة (كل تحليل مرة).
  Future<List<String>> names() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT name FROM lab_results GROUP BY name ORDER BY MAX(date) DESC');
    return [for (final r in rows) r['name'] as String];
  }

  /// آخر نتيجة لكل تحليل (لعرض القائمة الرئيسية).
  Future<List<LabResult>> latestPerName() async {
    final list = await all();
    final seen = <String>{};
    final out = <LabResult>[];
    for (final r in list) {
      if (seen.add(r.name)) out.add(r);
    }
    return out;
  }

  /// عدد التحاليل اللى آخر قيمة فيها خارج النطاق الطبيعى (لبادج لوحة الصحة).
  Future<int> outOfRangeCount() async {
    final latest = await latestPerName();
    return latest.where((r) => r.outOfRange).length;
  }

  /// ملخّص شهرى: كام تحليل اتسجّل الشهر ده، كام خارج النطاق، وإيه اللى
  /// اتحسّن/ساء عن آخر قياس قبله. [at] للاختبار.
  Future<LabMonthSummary> monthSummary([DateTime? at]) async {
    final now = at ?? DateTime.now();
    final prefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final all = await this.all(); // مرتّبة بالاسم ثم التاريخ تنازلياً
    final thisMonth = [for (final r in all) if (r.date.startsWith(prefix)) r];

    final improved = <String>[];
    final worsened = <String>[];
    for (final r in thisMonth) {
      // القياس اللى قبله مباشرةً لنفس التحليل (أى تاريخ أقدم).
      final older = [
        for (final o in all)
          if (o.name == r.name && o.date.compareTo(r.date) < 0) o
      ];
      if (older.isEmpty) continue;
      older.sort((a, b) => b.date.compareTo(a.date));
      final prev = older.first;
      // «اتحسّن» = خرج من النطاق ودخله، أو فضل جوه وقرب من النص.
      if (prev.outOfRange && !r.outOfRange) {
        improved.add(r.name);
      } else if (!prev.outOfRange && r.outOfRange) {
        worsened.add(r.name);
      }
    }

    return LabMonthSummary(
      logged: thisMonth.length,
      outOfRange: thisMonth.where((r) => r.outOfRange).length,
      improved: improved,
      worsened: worsened,
    );
  }

  Future<int> save(LabResult r) async {
    final db = await AppDb.instance;
    if (r.id == null) return db.insert('lab_results', r.toMap());
    await db
        .update('lab_results', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
    return r.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('lab_results', where: 'id = ?', whereArgs: [id]);
  }
}
