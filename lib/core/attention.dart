import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/docs_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/meds_repo.dart';
import '../data/plants_repo.dart';
import '../data/relatives_repo.dart';
import '../data/tasks_repo.dart';
import '../data/vaccinations_repo.dart';
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
    ));
  }
  for (final v in await VaccinationsRepo().dueSoon(days: 14)) {
    if (v.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.vaccine,
      id: v.id!,
      text: tr('جرعة تطعيم قربت: ${v.name}', 'Vaccine due: ${v.name}'),
      urgency: 4,
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
    ));
  }
  for (final r in await RelativesRepo().due(now)) {
    if (r.id == null) continue;
    out.add(AttentionItem(
      kind: AttentionKind.relative,
      id: r.id!,
      text: tr('اطمن على ${r.name}', 'Check on ${r.name}'),
      urgency: 7,
    ));
  }

  out.sort((a, b) => a.urgency.compareTo(b.urgency));
  return out;
}

/// بيحوّل جرعة زى «08:00» لوقت النهارده — null لو مش وقت صالح.
DateTime? _slotTime(DateTime now, String slot) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(slot.trim());
  if (m == null) return null;
  final h = int.tryParse(m.group(1)!), mi = int.tryParse(m.group(2)!);
  if (h == null || mi == null || h > 23 || mi > 59) return null;
  return DateTime(now.year, now.month, now.day, h, mi);
}
