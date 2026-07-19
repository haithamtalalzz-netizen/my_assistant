import '../core/ar.dart';
import '../core/db.dart';

/// بند حفظ (سورة/صفحة/مقطع) في خطة المراجعة بالتكرار المتباعد.
class MemorizationItem {
  final int? id;
  final String label;
  final int box; // مستوى Leitner (0 = أول الصف)
  final String nextReview; // YYYY-MM-DD
  final String lastReviewed;
  final int reviews;
  final String notes;

  const MemorizationItem({
    this.id,
    required this.label,
    required this.box,
    required this.nextReview,
    required this.lastReviewed,
    required this.reviews,
    required this.notes,
  });

  factory MemorizationItem.fromMap(Map<String, Object?> m) => MemorizationItem(
        id: m['id'] as int?,
        label: (m['label'] as String?) ?? '',
        box: (m['box'] as int?) ?? 0,
        nextReview: (m['next_review'] as String?) ?? '',
        lastReviewed: (m['last_reviewed'] as String?) ?? '',
        reviews: (m['reviews'] as int?) ?? 0,
        notes: (m['notes'] as String?) ?? '',
      );

  bool dueBy(DateTime day) =>
      nextReview.isNotEmpty && nextReview.compareTo(dayKey(day)) <= 0;
}

/// حفظ ومراجعة القرآن بالتكرار المتباعد (Leitner). المراجعة الناجحة بترفع
/// المستوى وتباعد الموعد؛ الضعيفة بترجّع البند لأول الصف (يتراجع بكرة).
class MemorizationRepo {
  /// فترات المراجعة بالأيام حسب المستوى (المستوى الأعلى = تباعد أكبر).
  static const List<int> intervals = [1, 3, 7, 14, 30, 60, 90];

  static int intervalForBox(int box) =>
      intervals[box.clamp(0, intervals.length - 1)];

  /// تاريخ المراجعة الجاية = بداية اليوم + فترة المستوى.
  static String nextReviewFor(int box, DateTime from) {
    final base = DateTime(from.year, from.month, from.day);
    return dayKey(base.add(Duration(days: intervalForBox(box))));
  }

  Future<int> add(String label, {String notes = ''}) async {
    final db = await AppDb.instance;
    final now = DateTime.now();
    return db.insert('memorization', {
      'label': label.trim(),
      'box': 0,
      'next_review': dayKey(now), // متاح للمراجعة من النهاردة
      'last_reviewed': '',
      'reviews': 0,
      'notes': notes.trim(),
      'created_at': now.toIso8601String(),
    });
  }

  Future<List<MemorizationItem>> all() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('memorization', orderBy: 'next_review ASC, id DESC');
    return rows.map(MemorizationItem.fromMap).toList();
  }

  Future<List<MemorizationItem>> due([DateTime? today]) async {
    final db = await AppDb.instance;
    final t = dayKey(today ?? DateTime.now());
    final rows = await db.query('memorization',
        where: 'next_review <= ?', whereArgs: [t], orderBy: 'next_review ASC');
    return rows.map(MemorizationItem.fromMap).toList();
  }

  Future<int> dueCount([DateTime? today]) async => (await due(today)).length;

  /// مراجعة بند: [ok] تمام يرفع المستوى ويباعد؛ لأ (ضعيف) يرجّعه لأول الصف.
  Future<void> review(int id, bool ok, {DateTime? today}) async {
    final db = await AppDb.instance;
    final now = today ?? DateTime.now();
    final rows = await db
        .query('memorization', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final cur = MemorizationItem.fromMap(rows.first);
    final newBox = ok ? (cur.box + 1).clamp(0, intervals.length - 1) : 0;
    await db.update(
      'memorization',
      {
        'box': newBox,
        'next_review': nextReviewFor(newBox, now),
        'last_reviewed': dayKey(now),
        'reviews': cur.reviews + 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('memorization', where: 'id = ?', whereArgs: [id]);
  }
}
