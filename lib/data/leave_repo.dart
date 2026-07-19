import '../core/db.dart';

/// إجازة واحدة اتاخدت (يوم + عدد أيام + نوع).
class LeaveEntry {
  final int? id;
  final String day; // YYYY-MM-DD
  final double days; // ممكن نص يوم (0.5)
  final String kind;
  final String note;

  const LeaveEntry({
    this.id,
    required this.day,
    required this.days,
    required this.kind,
    required this.note,
  });

  factory LeaveEntry.fromMap(Map<String, Object?> m) => LeaveEntry(
        id: m['id'] as int?,
        day: (m['day'] as String?) ?? '',
        days: ((m['days'] as num?) ?? 0).toDouble(),
        kind: (m['kind'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
      );
}

/// أنواع الإجازات المقترحة (المستخدم يقدر يكتب نوع تانى).
const List<String> kLeaveKinds = ['اعتيادية', 'عارضة', 'مرضية', 'بدون أجر'];

/// رصيد الإجازات السنوى — تسجيل الإجازات المأخوذة + حساب المتبقّى.
class LeaveRepo {
  static String _yearPrefix(int? year) =>
      '${(year ?? DateTime.now().year).toString().padLeft(4, '0')}-';

  Future<int> add(String day, double days,
      {String kind = '', String note = ''}) async {
    final db = await AppDb.instance;
    return db.insert('leave_ledger', {
      'day': day,
      'days': days,
      'kind': kind.trim(),
      'note': note.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// إجازات سنة معيّنة (افتراضيًا السنة الحالية)، الأحدث أول.
  Future<List<LeaveEntry>> forYear([int? year]) async {
    final db = await AppDb.instance;
    final rows = await db.query('leave_ledger',
        where: 'day LIKE ?',
        whereArgs: ['${_yearPrefix(year)}%'],
        orderBy: 'day DESC, id DESC');
    return rows.map(LeaveEntry.fromMap).toList();
  }

  /// مجموع الأيام المأخوذة في السنة.
  Future<double> takenInYear([int? year]) async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(days),0) t FROM leave_ledger WHERE day LIKE ?',
        ['${_yearPrefix(year)}%']);
    return ((r.first['t'] as num?) ?? 0).toDouble();
  }

  /// المتبقّى = الرصيد السنوى − المأخوذ (ممكن يبقى سالب لو عدّى رصيده).
  Future<double> remaining(int entitlement, [int? year]) async =>
      entitlement - await takenInYear(year);

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('leave_ledger', where: 'id = ?', whereArgs: [id]);
  }
}
