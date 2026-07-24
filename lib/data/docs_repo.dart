import 'package:flutter/material.dart';
import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';


/// مفتاح إعداد قفل المستندات بالبصمة.
const String kDocsLockSetting = 'docs_lock';

/// أنواع المستندات — المفتاح بيتخزّن والعرض عبر [docTypeLabel].
const List<String> kDocTypes = [
  'license', 'passport', 'id', 'insurance', 'contract',
  'certificate', 'warranty', 'other',
];

String docTypeLabel(String t) => switch (t) {
      'license' => tr('رخصة', 'License'),
      'passport' => tr('جواز سفر', 'Passport'),
      'id' => tr('بطاقة', 'ID card'),
      'insurance' => tr('تأمين', 'Insurance'),
      'contract' => tr('عقد', 'Contract'),
      'certificate' => tr('شهادة', 'Certificate'),
      'warranty' => tr('ضمان', 'Warranty'),
      _ => tr('أخرى', 'Other'),
    };

/// أيقونة النوع — بتخلّى القايمة تتقري بنظرة.
IconData docTypeIcon(String t) => switch (t) {
      'license' => Icons.badge_outlined,
      'passport' => Icons.airplane_ticket_outlined,
      'id' => Icons.credit_card_outlined,
      'insurance' => Icons.shield_outlined,
      'contract' => Icons.description_outlined,
      'certificate' => Icons.workspace_premium_outlined,
      'warranty' => Icons.verified_outlined,
      _ => Icons.folder_outlined,
    };

class DocsRepo {
  Future<List<DocItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('documents',
        orderBy: 'CASE WHEN expiry IS NULL THEN 1 ELSE 0 END, expiry, id DESC');
    return rows.map(DocItem.fromMap).toList();
  }

  /// المستندات اللي هتنتهي خلال [days] يوم — وتشمل المنتهية بالفعل.
  /// المستندات اللى قربت تنتهى.
  ///
  /// بيفلتر فى Dart مش SQL عن قصد: الانتهاء ممكن يكون **محسوب** من
  /// (الإصدار + مدة الصلاحية) ومش متخزّن فى عمود `expiry`، واستعلام SQL
  /// على العمود لوحده كان هيسيب المستندات دى تفوت من غير تنبيه.
  Future<List<DocItem>> expiringSoon({int days = 30}) async {
    final limit = dayKey(DateTime.now().add(Duration(days: days)));
    final out = <DocItem>[];
    for (final d in await all()) {
      final exp = d.effectiveExpiry;
      if (exp != null && exp.compareTo(limit) <= 0) out.add(d);
    }
    out.sort((a, b) => a.effectiveExpiry!.compareTo(b.effectiveExpiry!));
    return out;
  }

  Future<int> save(DocItem d) async {
    final db = await AppDb.instance;
    final int id;
    if (d.id == null) {
      id = await db.insert('documents', d.toMap());
    } else {
      id = d.id!;
      await db.update('documents', d.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, d);
    return id;
  }

  /// بعد الاستعادة من نسخة احتياطية: إعادة جدولة تنبيهات الانتهاء.
  Future<void> rescheduleAll() async {
    for (final d in await all()) {
      await _reschedule(d.id!, d);
    }
  }

  Future<void> _reschedule(int id, DocItem d) async {
    await Notifications.cancel(Notifications.docNotifId(id));
    // الانتهاء الفعلى (المكتوب أو المحسوب من الإصدار + المدة).
    final expStr = d.effectiveExpiry;
    if (expStr == null) return;
    final exp = DateTime.tryParse(expStr);
    if (exp == null) return;
    final remindAt = DateTime(exp.year, exp.month, exp.day, 9)
        .subtract(Duration(days: d.remindDays));
    await Notifications.scheduleOnce(
      id: Notifications.docNotifId(id),
      title: tr('مستند قرب يخلص: ${d.title}', 'Document expiring soon: ${d.title}'),
      body: tr('ينتهي يوم ${arShortDate(exp)} — جدده بدري',
          'Expires on ${arShortDate(exp)} — renew early'),
      when: remindAt,
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.docNotifId(id));
  }
}
