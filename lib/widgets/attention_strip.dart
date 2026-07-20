import 'package:flutter/material.dart';

import '../core/attention.dart';
import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/appointments_repo.dart';
import '../data/bills_repo.dart';
import '../data/meds_repo.dart';
import '../data/plants_repo.dart';
import '../data/tasks_repo.dart';

/// أيقونة ولون كل نوع بند.
({IconData icon, Color color}) _style(AttentionKind k) => switch (k) {
      AttentionKind.bill => (
          icon: Icons.receipt_long_outlined,
          color: Colors.redAccent
        ),
      AttentionKind.med => (icon: Icons.medication_outlined, color: Colors.pink),
      AttentionKind.appointment => (icon: Icons.event_outlined, color: Colors.blue),
      AttentionKind.task => (icon: Icons.checklist_outlined, color: Colors.indigo),
      AttentionKind.doc => (icon: Icons.folder_outlined, color: Colors.teal),
      AttentionKind.vaccine => (icon: Icons.vaccines_outlined, color: Colors.teal),
      AttentionKind.plant => (icon: Icons.yard_outlined, color: Colors.green),
      AttentionKind.maintenance => (
          icon: Icons.home_repair_service_outlined,
          color: Colors.orange
        ),
      AttentionKind.relative => (
          icon: Icons.diversity_1_outlined,
          color: Colors.purple
        ),
    };

/// شريط «محتاج منك دلوقتي» — كل المتأخر/المستحق من كل الأقسام فى مكان واحد
/// بأزرار تنفيذ فورية. لو مفيش حاجة بيعرض سطر «كله تمام».
class AttentionStrip extends StatefulWidget {
  final List<AttentionItem> items;

  /// بيتنادى بعد أى إجراء عشان الرئيسية تعيد التحميل.
  final Future<void> Function() onChanged;

  const AttentionStrip({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<AttentionStrip> createState() => _AttentionStripState();
}

class _AttentionStripState extends State<AttentionStrip> {
  /// أقصى عدد بنود يتعرض قبل «عرض الكل».
  static const _max = 4;
  bool _expanded = false;
  final _busy = <String>{};

  String _key(AttentionItem i) => '${i.kind}|${i.id}|${i.slot}';

  /// بينفّذ إجراء البند فى مكانه (من غير ما تفتح صفحته).
  Future<void> _act(AttentionItem it) async {
    final k = _key(it);
    if (_busy.contains(k)) return;
    setState(() => _busy.add(k));
    try {
      switch (it.kind) {
        case AttentionKind.bill:
          await BillsRepo().markPaid(it.id);
        case AttentionKind.task:
          await TasksRepo().setDone(it.id, true);
        case AttentionKind.med:
          await MedsRepo()
              .setTaken(it.id, dayKey(DateTime.now()), it.slot ?? '', true);
        case AttentionKind.appointment:
          await AppointmentsRepo().setDone(it.id, true);
        case AttentionKind.plant:
          // markWatered بتاخد الكائن نفسه مش الرقم.
          final repo = PlantsRepo();
          final plants = await repo.all();
          final p = plants.where((x) => x.id == it.id).firstOrNull;
          if (p != null) await repo.markWatered(p);
        default:
          break;
      }
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy.remove(k));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.items.isEmpty) return _allClear(scheme);

    final shown =
        _expanded ? widget.items : widget.items.take(_max).toList();
    final rest = widget.items.length - shown.length;
    final urgent = widget.items.where((i) => i.urgency == 0).length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high_rounded,
                    size: 18, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr('محتاج منك دلوقتي', 'Needs you now'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (urgent > 0 ? scheme.error : scheme.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    arNum(widget.items.length),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: urgent > 0 ? scheme.error : scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final it in shown) _row(it, scheme),
            if (rest > 0 || _expanded)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded
                      ? tr('عرض أقل', 'Show less')
                      : tr('و ${arNum(rest)} كمان', '$rest more')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(AttentionItem it, ColorScheme scheme) {
    final s = _style(it.kind);
    final busy = _busy.contains(_key(it));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(s.icon, size: 18, color: s.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              it.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                // اللى فات ميعاده بيتكتب بخط تقيل
                fontWeight:
                    it.urgency == 0 ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (it.actionLabel != null)
            busy
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: s.color,
                    ),
                    onPressed: () => _act(it),
                    child: Text(it.actionLabel!,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
        ],
      ),
    );
  }

  Widget _allClear(ColorScheme scheme) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2FA36B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('كله تمام — مفيش حاجة متأخرة 👌',
                      "All clear — nothing pending 👌"),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
}
