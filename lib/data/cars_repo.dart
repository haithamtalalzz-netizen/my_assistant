import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kCarEventTypes = [
  'service',
  'fuel',
  'insurance',
  'license',
  'other',
];

String carEventTypeLabel(String t) => switch (t) {
      'service' => tr('صيانة', 'Service'),
      'fuel' => tr('بنزين', 'Fuel'),
      'insurance' => tr('تأمين', 'Insurance'),
      'license' => tr('رخصة', 'License'),
      _ => tr('أخرى', 'Other'),
    };

/// السيارة — بيانات + أحداث (صيانة/بنزين/تأمين/رخصة) + تنبيهات تجديد + كفاءة وقود.
class CarsRepo {
  Future<List<Car>> cars() async {
    final db = await AppDb.instance;
    final rows = await db.query('cars', orderBy: 'id DESC');
    return rows.map(Car.fromMap).toList();
  }

  Future<int> saveCar(Car c) async {
    final db = await AppDb.instance;
    if (c.id == null) return db.insert('cars', c.toMap());
    await db.update('cars', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    return c.id!;
  }

  Future<void> deleteCar(int id) async {
    final db = await AppDb.instance;
    final events = await this.events(id);
    for (final e in events) {
      if (e.id != null) {
        await Notifications.cancel(Notifications.carEventNotifId(e.id!));
      }
    }
    await db.delete('car_events', where: 'car_id = ?', whereArgs: [id]);
    await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }

  // ---- الأحداث ----

  Future<List<CarEvent>> events(int carId, {String? type}) async {
    final db = await AppDb.instance;
    final rows = await db.query('car_events',
        where: type == null ? 'car_id = ?' : 'car_id = ? AND type = ?',
        whereArgs: type == null ? [carId] : [carId, type],
        orderBy: 'day DESC, id DESC');
    return rows.map(CarEvent.fromMap).toList();
  }

  Future<int> saveEvent(CarEvent e) async {
    final db = await AppDb.instance;
    final int id;
    if (e.id == null) {
      id = await db.insert('car_events', e.toMap());
    } else {
      id = e.id!;
      await db.update('car_events', e.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    // لو فيه عدّاد أحدث، حدّث عدّاد السيارة.
    if (e.odometer != null) {
      await db.rawUpdate(
          'UPDATE cars SET odometer = ? WHERE id = ? AND odometer < ?',
          [e.odometer, e.carId, e.odometer]);
    }
    await _rescheduleEvent(e.copyWithId(id));
    return id;
  }

  Future<void> deleteEvent(int id) async {
    final db = await AppDb.instance;
    await db.delete('car_events', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.carEventNotifId(id));
  }

  Future<void> _rescheduleEvent(CarEvent e) async {
    if (e.id == null) return;
    await Notifications.cancel(Notifications.carEventNotifId(e.id!));
    final due = e.nextDueDate;
    if (due == null) return;
    // ذكّر الساعة ١٠ صباحًا فى يوم الاستحقاق.
    final when = DateTime(due.year, due.month, due.day, 10);
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.carEventNotifId(e.id!),
      title: tr('تجديد ${carEventTypeLabel(e.type)} السيارة',
          'Car ${carEventTypeLabel(e.type)} renewal'),
      body: e.note.isEmpty
          ? tr('قرب موعد التجديد', 'Renewal is due soon')
          : e.note,
      when: when,
    );
  }

  Future<void> rescheduleAll() async {
    for (final c in await cars()) {
      if (c.id == null) continue;
      for (final e in await events(c.id!)) {
        await _rescheduleEvent(e);
      }
    }
  }

  // ---- إحصائيات ----

  /// إجمالى المصروف على سيارة.
  Future<double> totalSpent(int carId) async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(cost),0) t FROM car_events WHERE car_id = ?',
        [carId]);
    return (r.first['t'] as num).toDouble();
  }

  /// متوسط استهلاك الوقود (كم/لتر) من فرق العدّادات بين تعبئتين متتاليتين.
  /// بيرجّع null لو مفيش بيانات كافية.
  Future<double?> fuelEconomy(int carId) async {
    final fuels = (await events(carId, type: 'fuel'))
        .where((e) => e.odometer != null && (e.liters ?? 0) > 0)
        .toList()
      ..sort((a, b) => a.odometer!.compareTo(b.odometer!));
    if (fuels.length < 2) return null;
    final km = fuels.last.odometer! - fuels.first.odometer!;
    // لتر كل التعبئات ما عدا الأولى (المسافة اتقطعت بيها).
    final liters =
        fuels.skip(1).fold<double>(0, (s, e) => s + (e.liters ?? 0));
    if (liters <= 0 || km <= 0) return null;
    return km / liters;
  }
}

extension _CarEventCopy on CarEvent {
  CarEvent copyWithId(int id) => CarEvent(
        id: id,
        carId: carId,
        type: type,
        day: day,
        cost: cost,
        odometer: odometer,
        liters: liters,
        nextDue: nextDue,
        note: note,
        createdAt: createdAt,
      );
}
