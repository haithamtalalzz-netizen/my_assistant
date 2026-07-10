import 'dart:math' as math;

import 'package:flutter/material.dart';

/// كوباية مياه مرسومة — بتتملّى حسب [fraction] (٠..١) زي الموكاب.
class WaterGlass extends StatelessWidget {
  final double fraction;
  final double width;
  final double height;

  const WaterGlass({
    super.key,
    required this.fraction,
    this.width = 56,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _WaterGlassPainter(fraction.clamp(0, 1)),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double fraction;
  _WaterGlassPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // كوباية مخروطية بسيطة (أعلى أوسع من أسفل).
    final inset = w * 0.12;
    final glass = Path()
      ..moveTo(inset * 0.4, h * 0.06)
      ..lineTo(w - inset * 0.4, h * 0.06)
      ..lineTo(w - inset, h * 0.94)
      ..quadraticBezierTo(w - inset, h, w - inset * 1.8, h)
      ..lineTo(inset * 1.8, h)
      ..quadraticBezierTo(inset, h, inset, h * 0.94)
      ..close();

    // المياه (من تحت لفوق حسب النسبة).
    if (fraction > 0) {
      final waterTop = h * 0.06 + (h * 0.88) * (1 - fraction);
      canvas.save();
      canvas.clipPath(glass);
      final rect = Rect.fromLTRB(0, waterTop, w, h);
      final water = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5AC8FA), Color(0xFF2E9BEA)],
        ).createShader(rect);
      canvas.drawRect(rect, water);
      canvas.restore();
    }

    // حدّ الكوباية.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF7FB4D8)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(glass, stroke);

    // ورقة صغيرة على الحافة (زي الموكاب).
    final leaf = Paint()..color = const Color(0xFF35C98A);
    final lp = Path()
      ..moveTo(w * 0.74, h * 0.10)
      ..quadraticBezierTo(w * 0.98, h * 0.02, w * 0.96, h * 0.20)
      ..quadraticBezierTo(w * 0.82, h * 0.20, w * 0.74, h * 0.10)
      ..close();
    canvas.drawPath(lp, leaf);
  }

  @override
  bool shouldRepaint(_WaterGlassPainter old) => old.fraction != fraction;
}

/// خط نوم متموّج (موجة جيبية) — زخرفة زي الموكاب.
class SleepWave extends StatelessWidget {
  final Color color;
  final double height;

  const SleepWave({super.key, required this.color, this.height = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SleepWavePainter(color)),
    );
  }
}

class _SleepWavePainter extends CustomPainter {
  final Color color;
  _SleepWavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    final mid = h / 2;
    final amp = h * 0.32;
    path.moveTo(0, mid);
    for (double x = 0; x <= w; x += 2) {
      final y = mid + amp * math.sin((x / w) * 4 * math.pi);
      path.lineTo(x, y);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55);
    canvas.drawPath(path, line);
    // نقطة بداية مضيئة.
    canvas.drawCircle(Offset(2, mid), 3.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SleepWavePainter old) => old.color != color;
}
