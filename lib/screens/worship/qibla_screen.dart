import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';

/// بوصلة القبلة — سهم أخضر بيوجّهك لاتجاه الكعبة، بيتحرّك مع مستشعر البوصلة.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading; // اتجاه الجهاز (درجة من الشمال) — null على الويب/غير مدعوم.
  double _bearing = 0; // اتجاه القبلة من الموقع.
  double _distanceKm = 0; // المسافة لمكة.
  String _place = '';
  bool _loading = true;
  bool _noSensor = false;
  bool _wasAligned = false;
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final gov = await resolvePlace(SettingsRepo());
    _bearing = qiblaBearing(gov.lat, gov.lng);
    _distanceKm = _haversineKm(gov.lat, gov.lng, 21.4225, 39.8262); // الكعبة
    _place = gov.name;
    if (!kIsWeb) {
      final stream = FlutterCompass.events;
      if (stream != null) {
        _sub = stream.listen((e) {
          if (!mounted) return;
          setState(() => _heading = e.heading);
          _maybeHaptic();
        });
      } else {
        _noSensor = true;
      }
    } else {
      _noSensor = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// مسافة القوس الأكبر بالكيلومتر (haversine).
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _maybeHaptic() {
    final aligned = _aligned;
    if (aligned && !_wasAligned) HapticFeedback.mediumImpact();
    _wasAligned = aligned;
  }

  /// الفرق الزاوى بين اتجاه الجهاز والقبلة (0 = مستقبلها).
  double get _qiblaRelative {
    final h = _heading ?? 0;
    return (_bearing - h + 360) % 360;
  }

  bool get _aligned {
    if (_heading == null) return false;
    final d = _qiblaRelative;
    return d < 8 || d > 352;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final relRad = _qiblaRelative * math.pi / 180;
    final headRad = (_heading ?? 0) * math.pi / 180;
    final aligned = _aligned;

    return Scaffold(
      appBar: AppBar(title: Text(tr('اتجاه القبلة', 'Qibla direction'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    aligned
                        ? tr('أنت الآن باتجاه القبلة ✓', 'You are facing the Qibla ✓')
                        : tr('لِف الهاتف حتى يستقيم السهم لأعلى',
                            'Turn the phone until the arrow points up'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: aligned ? const Color(0xFF2FA36B) : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // وردة البوصلة — بتلف عكس اتجاه الجهاز فالشمال يفضل شمال.
                        Transform.rotate(
                          angle: -headRad,
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: _RosePainter(
                              ring: scheme.outlineVariant,
                              tick: scheme.onSurfaceVariant,
                              north: Colors.redAccent,
                              label: scheme.onSurface,
                            ),
                          ),
                        ),
                        // سهم القبلة.
                        Transform.rotate(
                          angle: relRad,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation,
                                  size: 90,
                                  color: aligned
                                      ? const Color(0xFF2FA36B)
                                      : scheme.primary),
                              const SizedBox(height: 4),
                              Text('🕋', style: const TextStyle(fontSize: 22)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _infoRow(tr('القبلة من الشمال', 'Qibla from North'),
                      '${arNum(_bearing.round())}°'),
                  _infoRow(tr('المسافة لمكة', 'Distance to Mecca'),
                      tr('${arNum(_distanceKm.round())} كم',
                          '${arNum(_distanceKm.round())} km')),
                  if (_heading != null)
                    _infoRow(tr('اتجاه الهاتف', 'Phone heading'),
                        '${arNum(_heading!.round())}°'),
                  _infoRow(tr('الموقع', 'Location'), _place),
                  if (_noSensor) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr(
                            'البوصلة الحيّة تشتغل على الموبايل فقط. القبلة عندك على '
                            '${arNum(_bearing.round())}° من الشمال — وجّه أعلى الشاشة نحو الشمال ثم لِف بمقدارها.',
                            'The live compass works on mobile only. Your Qibla is at '
                            '${arNum(_bearing.round())}° from North.'),
                        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

/// وردة البوصلة: حلقة + علامات كل 30° + حروف الاتجاهات (الشمال أحمر).
class _RosePainter extends CustomPainter {
  final Color ring;
  final Color tick;
  final Color north;
  final Color label;

  _RosePainter({
    required this.ring,
    required this.tick,
    required this.north,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    for (var deg = 0; deg < 360; deg += 15) {
      final major = deg % 90 == 0;
      final a = (deg - 90) * math.pi / 180;
      final outer = c + Offset(math.cos(a) * r, math.sin(a) * r);
      final inner =
          c + Offset(math.cos(a) * (r - (major ? 16 : 8)), math.sin(a) * (r - (major ? 16 : 8)));
      canvas.drawLine(inner, outer, Paint()
        ..color = deg == 0 ? north : tick
        ..strokeWidth = major ? 3 : 1.5);
    }

    const dirs = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    dirs.forEach((deg, txt) {
      final a = (deg - 90) * math.pi / 180;
      final pos = c + Offset(math.cos(a) * (r - 34), math.sin(a) * (r - 34));
      final tp = TextPainter(
        text: TextSpan(
            text: txt,
            style: TextStyle(
                color: deg == 0 ? north : label,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_RosePainter old) =>
      old.ring != ring || old.tick != tick || old.north != north || old.label != label;
}
