import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

/// سجل التطعيمات — تطعيمات ليها تاريخ + جرعة جاية اختيارية + تذكير قبلها بأسبوع.
class VaccinationsRepo {
  Future<List<Vaccination>> all() async {
    final db = await AppDb.instance;
    // اللى ليها جرعة جاية الأول (الأقرب فى الأعلى)، بعدها الباقى بالأحدث.
    final rows = await db.query('vaccinations',
        orderBy: "CASE WHEN next_due = '' THEN 1 ELSE 0 END, next_due, date DESC");
    return rows.map(Vaccination.fromMap).toList();
  }

  /// الجرعات اللى قرب ميعادها خلال [days] يوم أو فاتت (للرئيسية/الصحة).
  Future<List<Vaccination>> dueSoon({int days = 30}) async {
    final list = await all();
    return [
      for (final v in list)
        if (v.daysLeft != null && v.daysLeft! <= days) v
    ];
  }

  Future<int> save(Vaccination v) async {
    final db = await AppDb.instance;
    final int id;
    if (v.id == null) {
      id = await db.insert('vaccinations', v.toMap());
    } else {
      id = v.id!;
      await db
          .update('vaccinations', v.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, v);
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.vaccineNotifId(id));
  }

  Future<void> _reschedule(int id, Vaccination v) async {
    await Notifications.cancel(Notifications.vaccineNotifId(id));
    final d = v.nextDueDate;
    if (d == null) return;
    // تذكير قبل الجرعة بأسبوع الساعة ١٠ صباحاً.
    final when =
        DateTime(d.year, d.month, d.day, 10).subtract(const Duration(days: 7));
    if (when.isBefore(DateTime.now())) return;
    final who = v.person.trim().isEmpty ? '' : ' (${v.person})';
    await Notifications.scheduleOnce(
      id: Notifications.vaccineNotifId(id),
      title: tr('قرب موعد تطعيم', 'Vaccine due soon'),
      body: tr('جرعة ${v.name}$who بعد أسبوع', '${v.name}$who dose in a week'),
      when: when,
    );
  }

  Future<void> rescheduleAll() async {
    for (final v in await all()) {
      if (v.id != null) await _reschedule(v.id!, v);
    }
  }
}
