import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/hub_stats.dart';

/// كارت خلاصة «تطوّرى»: كام يوم من الأسبوع فيه نشاط + أطول سلسلة.
///
/// التطوّر تراكم مش حدث، فالرقم اللى بيهمّ هو **الاستمرار** مش المجموع.
class GrowthWeekCard extends StatefulWidget {
  const GrowthWeekCard({super.key});

  @override
  State<GrowthWeekCard> createState() => _GrowthWeekCardState();
}

class _GrowthWeekCardState extends State<GrowthWeekCard> {
  int? _days;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (days, streak) = await growthWeek();
    if (!mounted) return;
    setState(() {
      _days = days;
      _streak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const violet = Color(0xFF8B5CF6);
    const orange = Color(0xFFFF6F00);
    final days = _days;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: violet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: violet.withValues(alpha: 0.22)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.auto_awesome, size: 22, color: violet),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('الأسبوع ده', 'This week'),
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 3),
                  Text(
                      days == null
                          ? tr('بيحسب…', 'Loading…')
                          : tr('${arNum(days)} من 7 أيام',
                              '${arNum(days)} of 7 days'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                ]),
          ),
          if (_streak > 0)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(arNum(_streak),
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: orange)),
              Text(tr('يوم ورا بعض', 'day streak'),
                  style: TextStyle(
                      fontSize: 9.5, color: scheme.onSurfaceVariant)),
            ]),
        ]),
        const SizedBox(height: 11),
        // 🔴 المسار لازم يبان: لو لونه زى لون الكارت الشريط يطلع **مليان**
        // دايماً مهما كانت النسبة.
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (days ?? 0) / 7,
            minHeight: 8,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation(violet),
          ),
        ),
      ]),
    );
  }
}
