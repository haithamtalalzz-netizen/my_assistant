import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kSubscriptionCategories = [
  'ترفيه',
  'رياضة',
  'إنترنت',
  'برامج',
  'تعليم',
  'أخرى',
];

String subscriptionCategoryLabel(String c) => switch (c) {
      'ترفيه' => tr('ترفيه', 'Entertainment'),
      'رياضة' => tr('رياضة', 'Fitness'),
      'إنترنت' => tr('إنترنت', 'Internet'),
      'برامج' => tr('برامج', 'Software'),
      'تعليم' => tr('تعليم', 'Education'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => c,
    };

/// الاشتراكات الدورية (نتفليكس/جيم/إنترنت…) — شهرى/سنوى + تذكير التجديد.
class SubscriptionsRepo {
  Future<List<Subscription>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('subscriptions', orderBy: 'active DESC, name');
    return rows.map(Subscription.fromMap).toList();
  }

  /// إجمالى التكلفة الشهرية المكافئة للاشتراكات المفعّلة.
  Future<double> monthlyTotal() async {
    final subs = await all();
    return subs
        .where((s) => s.active)
        .fold<double>(0, (sum, s) => sum + s.monthlyCost);
  }

  Future<int> save(Subscription s) async {
    final db = await AppDb.instance;
    final int id;
    if (s.id == null) {
      id = await db.insert('subscriptions', s.toMap());
    } else {
      id = s.id!;
      await db.update('subscriptions', s.toMap(),
          where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, s);
    return id;
  }

  Future<void> setActive(int id, bool active) async {
    final db = await AppDb.instance;
    await db.update('subscriptions', {'active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    if (!active) await Notifications.cancel(Notifications.subscriptionNotifId(id));
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.subscriptionNotifId(id));
  }

  Future<void> _reschedule(int id, Subscription s) async {
    await Notifications.cancel(Notifications.subscriptionNotifId(id));
    // التذكير الشهرى بيغطّى الأغلبية؛ السنوى بيتذكّر برضه فى نفس يوم الشهر.
    if (!s.active) return;
    await Notifications.scheduleMonthly(
      id: Notifications.subscriptionNotifId(id),
      title: tr('تجديد اشتراك: ${s.name}', 'Subscription renews: ${s.name}'),
      body: s.cycle == 'yearly'
          ? tr('اشتراك سنوى — راجع إن كان وقته', 'Yearly — check if it is time')
          : tr('اشتراك شهرى مستحق', 'Monthly subscription due'),
      dayOfMonth: s.dayOfMonth,
      hour: 10,
      minute: 0,
    );
  }

  Future<void> rescheduleAll() async {
    for (final s in await all()) {
      if (s.id != null) await _reschedule(s.id!, s);
    }
  }
}
