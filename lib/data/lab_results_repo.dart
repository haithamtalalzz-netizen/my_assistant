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
