import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_timeline.dart';
import '../core/l10n.dart';

/// «الكارت الواحد» — حاجة واحدة بس قدّام المستخدم فى المرة.
///
/// اسحب يمين = تمّت · اسحب شمال = بعدين (بيروح آخر الكومة، **مش**
/// بيتشال — التأجيل مايمسحش حاجة). أسهل شكل ممكن: قرار واحد، مفيش
/// قايمة تتقرا ولا اختيارات تتفرز.
class DayDeckView extends StatefulWidget {
  final List<DayEvent> events;
  final DateTime now;
  final void Function(DayEvent event, bool done) onToggle;

  const DayDeckView({
    super.key,
    required this.events,
    required this.now,
    required this.onToggle,
  });

  @override
  State<DayDeckView> createState() => _DayDeckViewState();
}

class _DayDeckViewState extends State<DayDeckView> {
  /// البنود اللى المستخدم قال عليها «بعدين» فى الجلسة دى — بتتأجّل لآخر
  /// الكومة بدل ما تختفى. الحالة دى مؤقتة عن قصد (مش بتتخزّن): «بعدين»
  /// معناها دلوقتى مش وقتها، مش إنها اتلغت.
  final _later = <String>{};

  List<DayEvent> get _pending {
    final open = widget.events.where((e) => !e.done).toList();
    final now = open.where((e) => !_later.contains(e.actionKey)).toList();
    final later = open.where((e) => _later.contains(e.actionKey)).toList();
    return [...now, ...later];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = _pending;
    final doneCount = widget.events.where((e) => e.done).length;

    if (pending.isEmpty) return _allDone(context, doneCount);

    final top = pending.first;
    return Column(
      children: [
        Text(
          tr('فاضل ${arNum(pending.length)} · خلص ${arNum(doneCount)}',
              '${arNum(pending.length)} left · ${arNum(doneCount)} done'),
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        // الكارت اللى بعده باين ورا الحالى — بيوضّح إن فيه كومة.
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pending.length > 1)
                Positioned(
                  top: 16,
                  left: 18,
                  right: 18,
                  child: Opacity(
                    opacity: .45,
                    child: _card(context, pending[1], preview: true),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Dismissible(
                  key: ValueKey(top.actionKey),
                  background: _swipeHint(context, done: true),
                  secondaryBackground: _swipeHint(context, done: false),
                  onDismissed: (dir) {
                    // الاتجاه منطقى (start/end) فبيتظبط لوحده فى RTL.
                    if (dir == DismissDirection.startToEnd) {
                      widget.onToggle(top, true);
                    } else {
                      setState(() => _later.add(top.actionKey));
                    }
                  },
                  child: _card(context, top),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tr('اسحب يمين = تمّت · شمال = بعدين',
              'Swipe right = done · left = later'),
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, DayEvent e, {bool preview = false}) {
    final scheme = Theme.of(context).colorScheme;
    final late = e.at != null && e.at!.isBefore(widget.now);
    return Container(
      height: 230,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: late ? scheme.error.withValues(alpha: .5) : scheme.outlineVariant,
          width: late ? 2 : 1,
        ),
        boxShadow: preview
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(e.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            e.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          if (e.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              e.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            e.at == null
                ? tr('أى وقت النهاردة', 'Anytime today')
                : late
                    ? tr('كان ${arTime(e.at!)}', 'was ${arTime(e.at!)}')
                    : arTime(e.at!),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: late ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeHint(BuildContext context, {required bool done}) {
    final scheme = Theme.of(context).colorScheme;
    final color = done ? scheme.primary : scheme.tertiary;
    return Container(
      height: 230,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      alignment: done
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: color, size: 36),
          const SizedBox(height: 6),
          Text(done ? tr('تمّت', 'Done') : tr('بعدين', 'Later'),
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _allDone(BuildContext context, int doneCount) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 260,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            doneCount == 0
                ? tr('مفيش حاجة النهاردة.', 'Nothing today.')
                : tr('خلّصت كل حاجة النهاردة!', 'You finished everything today!'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          if (doneCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              tr('${arNum(doneCount)} بند خلصوا', '${arNum(doneCount)} done'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
