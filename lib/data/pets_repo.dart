import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kPetEventTypes = ['vaccine', 'vet', 'food', 'other'];

String petEventTypeLabel(String t) => switch (t) {
      'vaccine' => tr('تطعيم', 'Vaccine'),
      'vet' => tr('بيطري', 'Vet'),
      'food' => tr('أكل', 'Food'),
      _ => tr('أخرى', 'Other'),
    };

/// الحيوانات الأليفة — بيانات + أحداث (تطعيم/بيطري/أكل) + تنبيه الاستحقاق الجاى.
class PetsRepo {
  Future<List<Pet>> pets() async {
    final db = await AppDb.instance;
    final rows = await db.query('pets', orderBy: 'id DESC');
    return rows.map(Pet.fromMap).toList();
  }

  Future<int> savePet(Pet p) async {
    final db = await AppDb.instance;
    if (p.id == null) return db.insert('pets', p.toMap());
    await db.update('pets', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  Future<void> deletePet(int id) async {
    final db = await AppDb.instance;
    for (final e in await events(id)) {
      if (e.id != null) {
        await Notifications.cancel(Notifications.petEventNotifId(e.id!));
      }
    }
    await db.delete('pet_events', where: 'pet_id = ?', whereArgs: [id]);
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  // ---- الأحداث ----

  Future<List<PetEvent>> events(int petId) async {
    final db = await AppDb.instance;
    final rows = await db.query('pet_events',
        where: 'pet_id = ?', whereArgs: [petId], orderBy: 'day DESC, id DESC');
    return rows.map(PetEvent.fromMap).toList();
  }

  Future<int> saveEvent(PetEvent e) async {
    final db = await AppDb.instance;
    final int id;
    if (e.id == null) {
      id = await db.insert('pet_events', e.toMap());
    } else {
      id = e.id!;
      await db.update('pet_events', e.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(e.copyWithId(id));
    return id;
  }

  Future<void> deleteEvent(int id) async {
    final db = await AppDb.instance;
    await db.delete('pet_events', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.petEventNotifId(id));
  }

  Future<void> _reschedule(PetEvent e) async {
    if (e.id == null) return;
    await Notifications.cancel(Notifications.petEventNotifId(e.id!));
    final due = e.nextDueDate;
    if (due == null) return;
    final when = DateTime(due.year, due.month, due.day, 10);
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.petEventNotifId(e.id!),
      title: tr('موعد ${petEventTypeLabel(e.type)}', '${petEventTypeLabel(e.type)} due'),
      body: e.note.isEmpty ? tr('قرب الموعد', 'Coming up soon') : e.note,
      when: when,
    );
  }

  Future<void> rescheduleAll() async {
    for (final p in await pets()) {
      if (p.id == null) continue;
      for (final e in await events(p.id!)) {
        await _reschedule(e);
      }
    }
  }
}

extension _PetEventCopy on PetEvent {
  PetEvent copyWithId(int id) => PetEvent(
        id: id,
        petId: petId,
        type: type,
        day: day,
        nextDue: nextDue,
        note: note,
        createdAt: createdAt,
      );
}
