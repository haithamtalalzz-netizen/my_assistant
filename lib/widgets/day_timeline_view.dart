import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_timeline.dart';
import '../core/l10n.dart';

/// عرض «يومك مرتّب بالوقت» — قايمة واحدة بدل كروت منفصلة لكل قسم.
///
/// اللى فات بيتلمّ فى سطر واحد قابل للفتح، عشان الشاشة تبتدى من
/// **اللى قدامك** مش من أول اليوم.
class DayTimelineView extends StatefulWidget {
  final List<DayEvent> events;
  final DateTime now;

  /// تعليم البند تم/مش تم.
  final void Function(DayEvent event, bool done) onToggle;

  const DayTimelineView({
    super.key,
    required this.events,
    required this.now,
    required this.onToggle,
  });

  @override
  State<DayTimelineView> createState() => _DayTimelineViewState();
}

class _DayTimelineViewState extends State<DayTimelineView> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timed = widget.events.where((e) => e.at != null).toList();
    final anytime = widget.events.where((e) => e.at == null).toList();

    // «فات» = وقته عدّى وخلص خلاص (اللى فات ولسه مش متعمول بيفضل ظاهر
    // عشان ما يضيعش من المستخدم).
    final past = timed
        .where((e) => e.whenRelativeTo(widget.now) == DayEventWhen.past && e.done)
        .toList();
    final rest = timed.where((e) => !past.contains(e)).toList();

    if (timed.isEmpty && anytime.isEmpty) {
      return _emptyDay(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (past.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _showPast = !_showPast),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(_showPast ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    tr('${arNum(past.length)} خلصوا النهاردة',
                        '${arNum(past.length)} done today'),
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          if (_showPast) for (final e in past) _row(context, e),
          const SizedBox(height: 4),
        ],
        for (final e in rest) _row(context, e),
        if (anytime.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            tr('أى وقت النهاردة', 'Anytime today'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in anytime)
                FilterChip(
                  selected: e.done,
                  onSelected: (v) => widget.onToggle(e, v),
                  label: Text(e.title),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _emptyDay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('☀️', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(
            tr('يومك فاضى — مفيش مواعيد ولا أدوية مسجّلة النهاردة.',
                'Your day is clear — nothing scheduled today.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// سطر واحد فى الخط الزمنى: الوقت · النقطة · المحتوى · علامة التمام.
  Widget _row(BuildContext context, DayEvent e) {
    final scheme = Theme.of(context).colorScheme;
    final when = e.whenRelativeTo(widget.now);
    final isNow = when == DayEventWhen.now;
    final isLate = when == DayEventWhen.past && !e.done;

    final dotColor = e.done
        ? scheme.primary
        : isNow
            ? scheme.tertiary
            : isLate
                ? scheme.error
                : scheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isNow ? scheme.tertiaryContainer.withValues(alpha: .45) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              e.at == null ? '' : arTime(e.at!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isLate ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          Text(e.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isNow ? FontWeight.w900 : FontWeight.w700,
                    decoration: e.done ? TextDecoration.lineThrough : null,
                    color: e.done ? scheme.onSurfaceVariant : null,
                  ),
                ),
                if (e.subtitle.trim().isNotEmpty)
                  Text(
                    e.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          // الوجبة اتسجّلت خلاص — مفيش حاجة تتعمل عليها.
          if (e.kind == DayEventKind.meal)
            Icon(Icons.check_circle, size: 20, color: scheme.primary)
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                e.done ? Icons.check_circle : Icons.circle_outlined,
                color: e.done ? scheme.primary : scheme.outline,
              ),
              tooltip: e.done ? tr('رجّعه', 'Undo') : tr('تم', 'Done'),
              onPressed: () => widget.onToggle(e, !e.done),
            ),
        ],
      ),
    );
  }
}
