import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import 'income_repo.dart';
import 'meals_repo.dart';
import 'medical_repo.dart';
import 'money_repo.dart';
import 'social_repo.dart';

/// نتيجة بحث واحدة — [kind] بيحدد الشاشة اللي تتفتح لما يتضغط عليها.
class SearchHit {
  final String kind;
  final String title;
  final String subtitle;

  const SearchHit(
      {required this.kind, required this.title, required this.subtitle});
}

/// بحث عام عبر كل بيانات التطبيق — LIKE على الحقول النصية المهمة.
class SearchRepo {
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final db = await AppDb.instance;
    final like = '%$q%';
    final hits = <SearchHit>[];

    Future<void> add(String sql, List<Object?> args,
        SearchHit Function(Map<String, Object?>) map) async {
      final rows = await db.rawQuery(sql, args);
      for (final r in rows) {
        hits.add(map(r));
      }
    }

    // المواعيد.
    await add(
        "SELECT title, category, when_at FROM appointments WHERE title LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like], (r) {
      final w = DateTime.tryParse(r['when_at'] as String);
      return SearchHit(
          kind: 'appointment',
          title: r['title'] as String,
          subtitle: tr('موعد', 'Appointment') +
              (w == null ? '' : ' • ${arShortDate(w)}'));
    });

    // المصاريف.
    await add(
        "SELECT amount, category, note, day FROM expenses WHERE note LIKE ? OR category LIKE ? ORDER BY day DESC LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'expense',
            title: (r['note'] as String).isEmpty
                ? expenseCategoryLabel(r['category'] as String)
                : r['note'] as String,
            subtitle:
                '${tr('مصروف', 'Expense')} • ${egp((r['amount'] as num).toDouble())}'));

    // الدخل.
    await add(
        "SELECT amount, source, note FROM income WHERE source LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'income',
            title: incomeSourceLabel(r['source'] as String),
            subtitle:
                '${tr('دخل', 'Income')} • ${egp((r['amount'] as num).toDouble())}'));

    // الأدوية.
    await add(
        "SELECT name FROM medications WHERE name LIKE ? LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'medication',
            title: r['name'] as String,
            subtitle: tr('دواء', 'Medication')));

    // المستندات.
    await add(
        "SELECT title FROM documents WHERE title LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'document',
            title: r['title'] as String,
            subtitle: tr('مستند', 'Document')));

    // السجلات الطبية.
    await add(
        "SELECT type, title, provider FROM medical_records WHERE title LIKE ? OR provider LIKE ? OR result LIKE ? LIMIT 10",
        [like, like, like],
        (r) => SearchHit(
            kind: 'medical',
            title: r['title'] as String,
            subtitle:
                '${medicalTypeLabel(r['type'] as String)}${(r['provider'] as String).isEmpty ? '' : ' • ${r['provider']}'}'));

    // صيدلية البيت.
    await add(
        "SELECT name, quantity FROM home_pharmacy WHERE name LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'pharmacy',
            title: r['name'] as String,
            subtitle:
                '${tr('صيدلية البيت', 'Pharmacy')} • ×${arNum((r['quantity'] as num).toInt())}'));

    // الضمانات.
    await add(
        "SELECT item_name FROM warranties WHERE item_name LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'warranty',
            title: r['item_name'] as String,
            subtitle: tr('ضمان', 'Warranty')));

    // الديون.
    await add(
        "SELECT person, amount, direction FROM debts WHERE person LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'debt',
            title: r['person'] as String,
            subtitle:
                '${tr('دين/سلفة', 'Debt')} • ${egp((r['amount'] as num).toDouble())}'));

    // الواجبات الاجتماعية.
    await add(
        "SELECT person, type, occasion FROM social_obligations WHERE person LIKE ? OR occasion LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'social',
            title: r['person'] as String,
            subtitle:
                '${socialTypeLabel(r['type'] as String)}${(r['occasion'] as String).isEmpty ? '' : ' • ${r['occasion']}'}'));

    // الملابس.
    await add(
        "SELECT name, color FROM clothes WHERE name LIKE ? OR color LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'clothing',
            title: r['name'] as String,
            subtitle: tr('ملابس', 'Clothing')));

    // أهداف الادخار.
    await add(
        "SELECT name FROM savings_goals WHERE name LIKE ? LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'savings',
            title: r['name'] as String,
            subtitle: tr('هدف ادخار', 'Savings goal')));

    // العادات.
    await add(
        "SELECT name FROM habits WHERE name LIKE ? AND archived = 0 LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'habit',
            title: r['name'] as String,
            subtitle: tr('عادة', 'Habit')));

    // الوجبات.
    await add(
        "SELECT slot, description FROM meals WHERE description LIKE ? ORDER BY day DESC LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'meal',
            title: r['description'] as String,
            subtitle: mealSlotLabel(r['slot'] as String)));

    // صيانة البيت.
    await add(
        "SELECT name FROM home_maintenance WHERE name LIKE ? LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'home_maint',
            title: r['name'] as String,
            subtitle: tr('صيانة البيت', 'Home maintenance')));

    // المهام.
    await add(
        "SELECT title, done FROM tasks WHERE title LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'task',
            title: r['title'] as String,
            subtitle: (r['done'] as int? ?? 0) == 1
                ? '${tr('مهمة', 'Task')} • ${tr('تمّت', 'Done')}'
                : tr('مهمة', 'Task')));

    // الاشتراكات.
    await add(
        "SELECT name, amount FROM subscriptions WHERE name LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'subscription',
            title: r['name'] as String,
            subtitle:
                '${tr('اشتراك', 'Subscription')} • ${egp((r['amount'] as num).toDouble())}'));

    // الأهداف.
    await add(
        "SELECT title FROM goals WHERE title LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'goal',
            title: r['title'] as String,
            subtitle: tr('هدف', 'Goal')));

    // السيارات.
    await add(
        "SELECT name, plate FROM cars WHERE name LIKE ? OR plate LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like, like],
        (r) => SearchHit(
            kind: 'car',
            title: r['name'] as String,
            subtitle: '${tr('سيارة', 'Car')}'
                '${(r['plate'] as String).isEmpty ? '' : ' • ${r['plate']}'}'));

    // التجديدات.
    await add(
        "SELECT title, type FROM renewals WHERE title LIKE ? OR notes LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'renewal',
            title: r['title'] as String,
            subtitle: tr('تجديد', 'Renewal')));

    // الرحلات.
    await add(
        "SELECT title, destination FROM trips WHERE title LIKE ? OR destination LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'trip',
            title: r['title'] as String,
            subtitle: '${tr('رحلة', 'Trip')}'
                '${(r['destination'] as String).isEmpty ? '' : ' • ${r['destination']}'}'));

    // الدورات التعليمية.
    await add(
        "SELECT title, provider FROM courses WHERE title LIKE ? OR provider LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'course',
            title: r['title'] as String,
            subtitle: tr('دورة', 'Course')));

    // الحيوانات الأليفة.
    await add(
        "SELECT name, species FROM pets WHERE name LIKE ? OR species LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'pet',
            title: r['name'] as String,
            subtitle: tr('حيوان أليف', 'Pet')));

    // التطعيمات.
    await add(
        "SELECT name, person FROM vaccinations WHERE name LIKE ? OR person LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'vaccination',
            title: r['name'] as String,
            subtitle: '${tr('تطعيم', 'Vaccine')}'
                '${(r['person'] as String).isEmpty ? '' : ' • ${r['person']}'}'));

    // مؤشرات التحاليل.
    await add(
        "SELECT name, value, unit FROM lab_results WHERE name LIKE ? ORDER BY date DESC LIMIT 10",
        [like],
        (r) => SearchHit(
            kind: 'lab',
            title: r['name'] as String,
            subtitle:
                '${tr('تحليل', 'Lab')} • ${arNum((r['value'] as num).toString())} ${r['unit']}'));

    // قائمة الأمنيات.
    await add(
        "SELECT name FROM wishlist WHERE name LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'wish',
            title: r['name'] as String,
            subtitle: tr('أمنية', 'Wish')));

    // قائمة المشاهدة.
    await add(
        "SELECT title FROM watchlist WHERE title LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'watch',
            title: r['title'] as String,
            subtitle: tr('مشاهدة', 'Watchlist')));

    // الكتب.
    await add(
        "SELECT title, author FROM books WHERE title LIKE ? OR author LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'book',
            title: r['title'] as String,
            subtitle: '${tr('كتاب', 'Book')}'
                '${(r['author'] as String).isEmpty ? '' : ' • ${r['author']}'}'));

    // جرد ممتلكات البيت.
    await add(
        "SELECT name, location FROM home_inventory WHERE name LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'inventory',
            title: r['name'] as String,
            subtitle: tr('جرد البيت', 'Home inventory')));

    // نباتات البيت.
    await add(
        "SELECT name, location FROM plants WHERE name LIKE ? OR note LIKE ? LIMIT 10",
        [like, like],
        (r) => SearchHit(
            kind: 'plant',
            title: r['name'] as String,
            subtitle: tr('نبات', 'Plant')));

    return hits;
  }
}
