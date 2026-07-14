import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';
import 'settings_repo.dart';

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

  /// الاستهلاك بين كل قراءتين متتاليتين (زمنيًا) — لرسم الاستهلاك.
  Future<List<({String day, double delta})>> consumptions(String type,
      {int limit = 6}) async {
    final list = (await forType(type)).reversed.toList(); // زمنيًا تصاعدي
    final out = <({String day, double delta})>[];
    for (var i = 1; i < list.length; i++) {
      final d = list[i].reading - list[i - 1].reading;
      if (d >= 0) out.add((day: list[i].day, delta: d));
    }
    if (out.length > limit) return out.sublist(out.length - limit);
    return out;
  }

  /// سعر الوحدة لكل نوع (ج.م) — من الإعدادات.
  Future<double> rate(String type) async =>
      double.tryParse(await SettingsRepo().get('meter.rate.$type') ?? '') ?? 0;

  Future<void> setRate(String type, double value) async =>
      SettingsRepo().set('meter.rate.$type', value <= 0 ? '' : '$value');

  /// تقدير فاتورة الفترة الجاية = متوسط آخر استهلاكات × سعر الوحدة (0 لو مفيش).
  Future<double> estimateBill(String type) async {
    final cons = await consumptions(type);
    if (cons.isEmpty) return 0;
    final avg = cons.fold<double>(0, (s, c) => s + c.delta) / cons.length;
    return avg * await rate(type);
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
