import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/debts_repo.dart';
import '../data/gameya_repo.dart';
import '../data/subscriptions_repo.dart';
import '../data/docs_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/meds_repo.dart';
import '../data/plants_repo.dart';
import '../data/relatives_repo.dart';
import '../data/tasks_repo.dart';
import '../data/vaccinations_repo.dart';
import '../models/models.dart';
import 'ar.dart';
import 'l10n.dart';

/// نوع البند — بيحدد الأيقونة واللون والإجراء فى الواجهة.
enum AttentionKind {
  bill,
  med,
  appointment,
  task,
  doc,
  vaccine,
  plant,
  maintenance,
  relative,
  debt,
  subscription,
  gameya,
}

/// بند «محتاج منك دلوقتي» — حاجة متأخرة أو مستحقة النهارده من أى قسم.
class AttentionItem {
  final AttentionKind kind;

  /// رقم السجل (لتنفيذ الإجراء) — للأدوية بيبقى رقم الدوا.
  final int id;

  /// جرعة الدوا (slot) — للأدوية بس.
  final String? slot;

  final String text;

  /// درجة الإلحاح: أقل = أهم. ٠ = فات ميعاده.
  final int urgency;

  /// نص زرار التنفيذ الفورى (null = مفيش إجراء، بس بيفتح الصفحة).
  final String? actionLabel;

  const AttentionItem({
    required this.kind,
    required this.id,
    required this.text,
    required this.urgency,
    this.slot,
    this.actionLabel,
  });
}

/// بيلمّ كل اللى محتاج تصرّف من كل أقسام التطبيق، مرتّب بالإلحاح.
///
/// نقّى ومحلى بالكامل — مجرد قراءة من قواعد البيانات المحلية.
/// [now] بتتحقن فى الاختبارات.
Future<List<AttentionItem>> collectAttention([DateTime? nowArg]) async {
  final now = nowArg ?? DateTime.now();
  final today = dayKey(now);
  final out = <AttentionItem>[];

  // ————— فواتير مستحقة (أعلى إلحاح: فلوس بتتأخر) —————
  for (final b in await BillsRepo().due(now)) {
    if (b.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.bill,
      id: b.id!,
      text: tr('فاتورة مستحقة: ${b.name} — ${egp(b.amount)}',
          'Bill due: ${b.name} — ${egp(b.amount)}'),
      urgency: 0,
      actionLabel: tr('اتدفعت', 'Paid'),
    ));
  }

  // ————— مهام فات ميعادها أو النهارده —————
  for (final t in await TasksRepo().dueTasks(now)) {
    if (t.id == null || t.due == null) continue;
    final overdue = t.due!.isBefore(now);
    out.add(AttentionItem(
      kind: AttentionKind.task,
      id: t.id!,
      text: overdue
          ? tr('مهمة متأخرة: ${t.title}', 'Overdue task: ${t.title}')
          : tr('مهمة النهارده: ${t.title}', 'Task today: ${t.title}'),
      urgency: overdue ? 0 : 2,
      actionLabel: tr('تمّت', 'Done'),
    ));
  }

  // ————— جرعات دوا لسه ماتخدتش —————
  final taken = await MedsRepo().takenOn(today);
  for (final m in await MedsRepo().all(activeOnly: true)) {
    if (m.id == null) continue;
    for (final slot in m.times) {
      if (taken.contains('${m.id}|$slot')) continue;
      // الجرعة اللى ميعادها فات = ملحّة؛ اللى جاية بعدين تفضل تحت.
      final due = _slotTime(now, slot);
      final passed = due != null && due.isBefore(now);
      out.add(AttentionItem(
        kind: AttentionKind.med,
        id: m.id!,
        slot: slot,
        text: passed
            ? tr('جرعة فاتت: ${m.name} ($slot)', 'Missed dose: ${m.name} ($slot)')
            : tr('دوا: ${m.name} ($slot)', 'Med: ${m.name} ($slot)'),
        urgency: passed ? 1 : 5,
        actionLabel: tr('اتاخد', 'Taken'),
      ));
    }
  }

  // ————— مواعيد النهارده (اللى لسه ماتمتش) —————
  for (final a in await AppointmentsRepo().forDay(now)) {
    if (a.id == null) continue;
    final soon = a.when.difference(now).inMinutes <= 120;
    out.add(AttentionItem(
      kind: AttentionKind.appointment,
      id: a.id!,
      text: tr('موعد: ${a.title} — ${arTime(a.when)}',
          'Appointment: ${a.title} — ${arTime(a.when)}'),
      urgency: soon ? 1 : 3,
      actionLabel: tr('تم', 'Done'),
    ));
  }

  // ————— وثائق وتجديدات وتطعيمات قربت —————
  for (final d in await DocsRepo().expiringSoon()) {
    if (d.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.doc,
      id: d.id!,
      text: tr('مستند قرب يخلص: ${d.title}', 'Document expiring: ${d.title}'),
      urgency: 4,
      // «جدّدته» معناها ننقل الإصدار للنهارده — بيشتغل بس لما يبقى فيه
      // مدة صلاحية يتحسب منها الانتهاء الجديد.
      actionLabel: d.validYears > 0 ? tr('جدّدته', 'Renewed') : null,
    ));
  }
  for (final v in await VaccinationsRepo().dueSoon(days: 14)) {
    if (v.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.vaccine,
      id: v.id!,
      text: tr('جرعة تطعيم قربت: ${v.name}', 'Vaccine due: ${v.name}'),
      urgency: 4,
      actionLabel: tr('اتاخد', 'Taken'),
    ));
  }

  // ————— البيت وصلة الرحم —————
  for (final p in await PlantsRepo().due(now)) {
    if (p.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.plant,
      id: p.id!,
      text: tr('${p.name} محتاجة مياه', '${p.name} needs water'),
      urgency: 6,
      actionLabel: tr('سقيت', 'Watered'),
    ));
  }
  for (final m in await HomeMaintenanceRepo().due(now)) {
    if (m.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.maintenance,
      id: m.id!,
      text: tr('صيانة مستحقة: ${m.name}', 'Maintenance due: ${m.name}'),
      urgency: 6,
      actionLabel: tr('اتعملت', 'Done'),
    ));
  }
  for (final r in await RelativesRepo().due(now)) {
    if (r.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.relative,
      id: r.id!,
      text: tr('اطمن على ${r.name}', 'Check on ${r.name}'),
      urgency: 7,
      actionLabel: tr('اتطمنت', 'Contacted'),
    ));
  }

  // ————— الفلوس: ديون واشتراكات وجمعية —————
  // الديون اللى ليك ومعدّى عليها شهر — فكّرك تحصّلها (اللى عليك بتفكّرك
  // كمان إنك تسدّد).
  for (final d in await DebtsRepo().all()) {
    if (d.id == null || d.settled) continue;
    final since = DateTime.tryParse(d.createdAt);
    if (since == null || now.difference(since).inDays < 30) continue;
    final mine = d.direction == 'لى';
    out.add(AttentionItem(
      kind: AttentionKind.debt,
      id: d.id!,
      text: mine
          ? tr('${d.person} لسه مدين لك ${egp(d.amount)}',
              '${d.person} still owes you ${egp(d.amount)}')
          : tr('لسه عليك ${egp(d.amount)} لـ${d.person}',
              'You still owe ${egp(d.amount)} to ${d.person}'),
      urgency: 5,
      actionLabel: tr('اتسدد', 'Settled'),
    ));
  }

  // اشتراك بيتجدّد خلال ٣ أيام — عشان تلغيه قبل ما يتخصم.
  for (final sub in await SubscriptionsRepo().all()) {
    if (sub.id == null || !sub.active) continue;
    final days = _daysUntilMonthDay(now, sub.dayOfMonth);
    if (days > 3) continue;
    out.add(AttentionItem(
      kind: AttentionKind.subscription,
      id: sub.id!,
      text: days <= 0
          ? tr('اشتراك بيتجدّد النهاردة: ${sub.name} — ${egp(sub.amount)}',
              'Subscription renews today: ${sub.name} — ${egp(sub.amount)}')
          : tr('اشتراك بيتجدّد بعد ${arNum(days)} يوم: ${sub.name}',
              'Subscription renews in ${arNum(days)} days: ${sub.name}'),
      urgency: 5,
    ));
  }

  // قسط الجمعية بتاع الشهر ده لو لسه مادفعش.
  final monthKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}';
  for (final g in await GameyaRepo().all()) {
    if (g.id == null) continue;
    if (now.day < g.dayOfMonth) continue;
    final paid = await GameyaRepo().paidMonths(g.id!);
    if (paid.contains(monthKey)) continue;
    out.add(AttentionItem(
      kind: AttentionKind.gameya,
      id: g.id!,
      text: tr('قسط الجمعية: ${g.name} — ${egp(g.amount)}',
          'Gameya payment: ${g.name} — ${egp(g.amount)}'),
      urgency: 3,
      actionLabel: tr('دفعت', 'Paid'),
    ));
  }

  out.sort((a, b) => a.urgency.compareTo(b.urgency));
  return out;
}

/// كام يوم لحد يوم [dayOfMonth] الجاى — ٠ يعنى النهاردة.
int _daysUntilMonthDay(DateTime now, int dayOfMonth) {
  final d = dayOfMonth.clamp(1, 28);
  if (now.day <= d) return d - now.day;
  // عدّى الشهر ده → الشهر الجاى.
  final next = DateTime(now.year, now.month + 1, d);
  return next.difference(DateTime(now.year, now.month, now.day)).inDays;
}

/// بيحوّل جرعة زى «08:00» لوقت النهارده — null لو مش وقت صالح.
DateTime? _slotTime(DateTime now, String slot) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(slot.trim());
  if (m == null) return null;
  final h = int.tryParse(m.group(1)!), mi = int.tryParse(m.group(2)!);
  if (h == null || mi == null || h > 23 || mi > 59) return null;
  return DateTime(now.year, now.month, now.day, h, mi);
}

/// بينفّذ إجراء البند فورًا (زرار «تمّت»/«اتاخد»/«اتدفعت»…).
///
/// موجودة هنا مش فى الشاشة عشان تفضل **قابلة للاختبار** ومصدر واحد لأى
/// واجهة بتعرض التنبيهات. بترجّع false لو النوع مالوش إجراء.
Future<bool> performAttentionAction(AttentionItem item,
    {DateTime? nowArg}) async {
  final now = nowArg ?? DateTime.now();
  final today = dayKey(now);
  switch (item.kind) {
    case AttentionKind.bill:
      await BillsRepo().markPaid(item.id, now: now);
      return true;
    case AttentionKind.task:
      await TasksRepo().setDone(item.id, true);
      return true;
    case AttentionKind.med:
      if (item.slot == null) return false;
      await MedsRepo().setTaken(item.id, today, item.slot!, true);
      return true;
    case AttentionKind.appointment:
      await AppointmentsRepo().setDone(item.id, true);
      return true;
    case AttentionKind.plant:
      final p = (await PlantsRepo().all()).where((x) => x.id == item.id);
      if (p.isEmpty) return false;
      await PlantsRepo().markWatered(p.first, now: now);
      return true;
    case AttentionKind.maintenance:
      await HomeMaintenanceRepo().markDone(item.id);
      return true;
    case AttentionKind.relative:
      final r = (await RelativesRepo().all()).where((x) => x.id == item.id);
      if (r.isEmpty) return false;
      await RelativesRepo().markContacted(r.first, now: now);
      return true;
    case AttentionKind.doc:
      // «جدّدته» = الإصدار بقى النهاردة، والانتهاء بيتحسب لوحده.
      final docs = (await DocsRepo().all()).where((x) => x.id == item.id);
      if (docs.isEmpty || docs.first.validYears <= 0) return false;
      final d = docs.first;
      await DocsRepo().save(DocItem(
        id: d.id,
        title: d.title,
        imagePath: d.imagePath,
        images: d.images,
        expiry: null, // المكتوب بإيد بيتشال عشان المحسوب يشتغل
        remindDays: d.remindDays,
        notes: d.notes,
        type: d.type,
        docNumber: d.docNumber,
        issuer: d.issuer,
        owner: d.owner,
        issued: today,
        validYears: d.validYears,
        renewCost: d.renewCost,
      ));
      return true;
    case AttentionKind.vaccine:
      final vs = (await VaccinationsRepo().all()).where((x) => x.id == item.id);
      if (vs.isEmpty) return false;
      final v = vs.first;
      await VaccinationsRepo().save(Vaccination(
        id: v.id,
        name: v.name,
        person: v.person,
        date: today, // الجرعة اتاخدت النهاردة
        nextDue: '', // الجاية بيحددها المستخدم
        notes: v.notes,
        createdAt: v.createdAt,
      ));
      return true;
    case AttentionKind.debt:
      await DebtsRepo().setSettled(item.id, true);
      return true;
    case AttentionKind.gameya:
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      await GameyaRepo().setPaid(item.id, monthKey, true);
      return true;
    case AttentionKind.subscription:
      // الاشتراك بيتجدّد لوحده — مفيش إجراء، بس بيفكّرك تلغيه لو عايز.
      return false;
  }
}
