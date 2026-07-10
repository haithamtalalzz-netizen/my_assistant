import 'dart:developer' as dev;

import 'package:flutter_contacts/flutter_contacts.dart';

import '../data/occasions_repo.dart';
import '../models/models.dart';

/// استيراد أعياد الميلاد من جهات الاتصال → مناسبات سنوية.
class ContactsImport {
  /// يرجع عدد أعياد الميلاد المضافة، أو null لو الإذن اترفض.
  static Future<int?> importBirthdays() async {
    try {
      final granted =
          await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return null;
      final contacts =
          await FlutterContacts.getContacts(withProperties: true);
      final repo = OccasionsRepo();
      final existing = await repo.all();
      var added = 0;
      for (final c in contacts) {
        final name = c.displayName.trim();
        if (name.isEmpty) continue;
        for (final e in c.events) {
          if (e.label != EventLabel.birthday) continue;
          final dup = existing.any((o) =>
              o.person == name && o.month == e.month && o.day == e.day);
          if (dup) continue;
          await repo.save(Occasion(
            title: 'عيد ميلاد',
            person: name,
            month: e.month,
            day: e.day,
            remindDays: 1,
          ));
          added++;
        }
      }
      return added;
    } on Exception catch (e) {
      dev.log('فشل استيراد أعياد الميلاد', error: e);
      return null;
    }
  }
}
