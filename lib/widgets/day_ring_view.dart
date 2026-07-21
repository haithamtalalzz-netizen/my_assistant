import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_timeline.dart';
import '../core/l10n.dart';

/// موضع البند على الحلقة كنسبة من اليوم (٠ = ١٢ بالليل، ١ = آخر اليوم).
/// دالة نقية عشان تتاخد عليها اختبارات من غير رسم.
double dayFraction(DateTime at) =>
    (at.hour * 60 + at.minute) / (24 * 60);

/// زاوية البند بالراديان على دايرة بتبدأ من فوق وبتلف مع عقارب الساعة.
double ringAngle(DateTime at) => dayFraction(at) * 2 * math.pi - math.pi / 2;

/// «حلقة اليوم» — دايرة زى الساعة بنودك متوزّعة حواليها بمواعيدها،
/// وفى النص الحاجة الجاية. بصة واحدة تفهم منها شكل يومك كله.
class DayRingView extends StatelessWidget {
  final List<DayEvent> events;
  final DateTime now;
  final void Function(DayEvent event, bool done) onToggle;

  const DayRingView({
    super.key,
    required this.events,
    required this.now,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timed = events.where((e) => e.at != null).toList();
    final next = nextPendingEvent(events, now);
    final remaining = events.where((e) => !e.done).length;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _RingPainter(
                  events: timed,
                  now: now,
                  track: scheme.surfaceContainerHighest,
                  nowColor: scheme.tertiary,
                  doneColor: scheme.primary,
                  pendingColor: scheme.outline,
                  lateColor: scheme.error,
                ),
              ),
              // النص: اللى جاى دلوقتى.
              Padding(
                padding: const EdgeInsets.all(56),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      next == null
                          ? tr('خلصت', 'All done')
                          : tr('اللى جاى', 'Next up'),
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    if (next != null) ...[
                      Text(next.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        next.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      if (next.at != null)
                        Text(
                          arTime(next.at!),
                          style: TextStyle(
                              fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                    ] else
                      const Text('🎉', style: TextStyle(fontSize: 30)),
                    const SizedBox(height: 8),
                    Text(
                      tr('فاضل ${arNum(remaining)}', '${arNum(remaining)} left'),
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (next != null)
          FilledButton.icon(
            onPressed: () => onToggle(next, true),
            icon: const Icon(Icons.check_rounded),
            label: Text(tr('تمّت — اللى بعدها', 'Done — next')),
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<DayEvent> events;
  final DateTime now;
  final Color track;
  final Color nowColor;
  final Color doneColor;
  final Color pendingColor;
  final Color lateColor;

  _RingPainter({
    required this.events,
    required this.now,
    required this.track,
    required this.nowColor,
    required this.doneColor,
    required this.pendingColor,
    required this.lateColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 26;

    // الحلقة الأساسية.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = track,
    );

    // القوس من أول اليوم لدلوقتى — بيوضّح إحنا فين فى اليوم.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      dayFraction(now) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = nowColor.withValues(alpha: .30),
    );

    // نقطة لكل بند فى مكانها الزمنى.
    for (final e in events) {
      final angle = ringAngle(e.at!);
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final late = !e.done && e.at!.isBefore(now);
      final color = e.done
          ? doneColor
          : late
              ? lateColor
              : pendingColor;
      // حلقة بيضا حوالين النقطة عشان تفضل بارزة فوق القوس.
      canvas.drawCircle(p, 8, Paint()..color = track);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = color
          ..style = e.done ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // مؤشّر «دلوقتى».
    final nowAngle = ringAngle(now);
    final tip = Offset(
      center.dx + (radius + 12) * math.cos(nowAngle),
      center.dy + (radius + 12) * math.sin(nowAngle),
    );
    final base = Offset(
      center.dx + (radius - 12) * math.cos(nowAngle),
      center.dy + (radius - 12) * math.sin(nowAngle),
    );
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = nowColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.now != now || old.events.length != events.length;
}
