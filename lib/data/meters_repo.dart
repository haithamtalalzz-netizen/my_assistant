import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kMeterTypes = ['electricity', 'water', 'gas'];

String meterTypeLabel(String t) => switch (t) {
      'electricity' => tr('الكهربا', 'Electricity'),
      'water' => tr('المياه', 'Water'),
      'gas' => tr('الغاز', 'Gas'),
      _ => t,
    };

class MetersRepo {
  Future<int> add(MeterReading r) async {
    final db = await AppDb.instance;
    return db.insert('meter_readings', r.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('meter_readings', where: 'id = ?', whereArgs: [id]);
  }

  /// قراءات نوع معيّن — الأحدث أولًا.
  Future<List<MeterReading>> forType(String type) async {
    final db = await AppDb.instance;
    final rows = await db.query('meter_readings',
        where: 'meter_type = ?', whereArgs: [type], orderBy: 'day DESC, id DESC');
    return rows.map(MeterReading.fromMap).toList();
  }

  /// آخر قراءة لكل نوع.
  Future<Map<String, MeterReading>> latestByType() async {
    final result = <String, MeterReading>{};
    for (final t in kMeterTypes) {
      final list = await forType(t);
      if (list.isNotEmpty) result[t] = list.first;
    }
    return result;
  }

  /// تذكير شهري (يوم ٢٥) لتسجيل قراءات العدادات.
  Future<void> ensureMonthlyReminder() async {
    await Notifications.scheduleMonthly(
      id: Notifications.meterNotifId(0),
      title: tr('قراءات العدادات', 'Meter readings'),
      body: tr('سجّل قراءة الكهربا والمياه والغاز الشهر ده',
          "Log this month's electricity, water & gas readings"),
      dayOfMonth: 25,
      hour: 18,
      minute: 0,
    );
  }
}
