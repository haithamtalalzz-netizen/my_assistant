import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';

/// حلقة تقدّم واحدة (صلوات/مياه/عادات/أدوية).
class GlanceRing {
  final IconData icon;
  final String label;
  final int done;
  final int total;
  final Color color;
  const GlanceRing({
    required this.icon,
    required this.label,
    required this.done,
    required this.total,
    required this.color,
  });

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  bool get complete => total > 0 && done >= total;
}

/// «يومك فى سطر» — صف حلقات تقدّم مضغوط بدل كروت منفصلة لكل حاجة.
/// بيعرض بس الحلقات اللى ليها معنى (total > 0).
class DayGlance extends StatelessWidget {
  final List<GlanceRing> rings;

  /// بيتنادى لما المستخدم يدوس على حلقة (للتنقّل للقسم).
  final void Function(GlanceRing)? onTap;

  const DayGlance({super.key, required this.rings, this.onTap});

  @override
  Widget build(BuildContext context) {
    final shown = [for (final r in rings) if (r.total > 0) r];
    if (shown.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final r in shown)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap == null ? null : () => onTap!(r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: CustomPaint(
                            painter: _RingPainter(
                              fraction: r.fraction,
                              color: r.color,
                              track: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                            child: Center(
                              child: r.complete
                                  ? Icon(Icons.check,
                                      size: 18, color: r.color)
                                  : Icon(r.icon, size: 16, color: r.color),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${arNum(r.done)}/${arNum(r.total)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: r.complete ? r.color : null,
                          ),
                        ),
                        Text(
                          r.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// حلقة بسيطة: مسار رمادى + قوس ملوّن بنسبة الإنجاز.
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;
  _RingPainter(
      {required this.fraction, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // من فوق
      2 * math.pi * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// نص مختصر للحالة (للاستخدام فى الاختبارات/التلميحات).
String glanceSummary(List<GlanceRing> rings) {
  final shown = [for (final r in rings) if (r.total > 0) r];
  if (shown.isEmpty) return '';
  final done = shown.where((r) => r.complete).length;
  return tr('${arNum(done)} من ${arNum(shown.length)} خلصت',
      '${arNum(done)} of ${arNum(shown.length)} complete');
}
