import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

/// توقّعات الدورة الشهرية المحسوبة من التواريخ المسجّلة.
class CyclePrediction {
  final int loggedCount;
  final int avgCycleLength; // متوسط طول الدورة
  final DateTime? lastStart;
  final DateTime? nextStart;
  final int? currentDay; // اليوم الحالي في الدورة
  final int? daysUntilNext; // كام يوم على الدورة الجاية
  final DateTime? ovulation; // يوم التبويض المتوقّع
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  const CyclePrediction({
    this.loggedCount = 0,
    this.avgCycleLength = 28,
    this.lastStart,
    this.nextStart,
    this.currentDay,
    this.daysUntilNext,
    this.ovulation,
    this.fertileStart,
    this.fertileEnd,
  });

  bool get hasData => lastStart != null;
}

class CycleRepo {
  Future<int> add(CycleLog log) async {
    final db = await AppDb.instance;
    return db.insert('cycle_logs', log.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('cycle_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// كل الدورات المسجّلة — الأحدث الأول.
  Future<List<CycleLog>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('cycle_logs', orderBy: 'start_day DESC');
    return rows.map(CycleLog.fromMap).toList();
  }

  /// يحسب التوقّعات من التواريخ المسجّلة.
  Future<CyclePrediction> predict() async {
    final logs = await all();
    if (logs.isEmpty) return const CyclePrediction();

    // تواريخ البداية تصاعديًا.
    final starts = logs
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();
    if (starts.isEmpty) return const CyclePrediction();

    // متوسط طول الدورة من الفروق بين البدايات المتتالية.
    var avg = 28;
    if (starts.length >= 2) {
      var sum = 0;
      var n = 0;
      for (var i = 1; i < starts.length; i++) {
        final diff = starts[i].difference(starts[i - 1]).inDays;
        if (diff >= 15 && diff <= 60) {
          sum += diff;
          n++;
        }
      }
      if (n > 0) avg = (sum / n).round().clamp(21, 40);
    }

    final last = starts.last;
    final today = dateOnly(DateTime.now());
    final next = last.add(Duration(days: avg));
    final ovulation = next.subtract(const Duration(days: 14));
    final currentDay = today.difference(last).inDays + 1;

    return CyclePrediction(
      loggedCount: starts.length,
      avgCycleLength: avg,
      lastStart: last,
      nextStart: next,
      currentDay: currentDay >= 1 ? currentDay : null,
      daysUntilNext: next.difference(today).inDays,
      ovulation: ovulation,
      fertileStart: ovulation.subtract(const Duration(days: 5)),
      fertileEnd: ovulation.add(const Duration(days: 1)),
    );
  }
}
