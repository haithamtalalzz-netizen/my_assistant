import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import 'l10n.dart';

/// لقطة لحظية أثناء التتبع.
class ActivitySample {
  final double distanceMeters;
  final Duration elapsed;
  final double? speedKmh;
  const ActivitySample({
    required this.distanceMeters,
    required this.elapsed,
    this.speedKmh,
  });
}

/// متتبّع مشي/جري بالـGPS — بيجمع المسافة من تدفّق المواقع أثناء فتح الشاشة.
class WalkTracker {
  WalkTracker(this.onUpdate);

  final void Function(ActivitySample sample) onUpdate;

  StreamSubscription<Position>? _sub;
  Position? _last;
  double _meters = 0;
  DateTime? _start;
  Duration _accumulated = Duration.zero;

  bool get isTracking => _sub != null;
  double get meters => _meters;

  /// بيتأكد إن الموقع مفعّل والإذن متاح. بيرجّع رسالة خطأ أو null لو تمام.
  static Future<String?> ensureReady() async {
    if (kIsWeb) {
      return tr('تتبّع الـGPS متاح على الموبايل بس', 'GPS tracking is mobile-only');
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return tr('فعّل خدمة الموقع (GPS) من إعدادات الموبايل',
            'Turn on Location (GPS) in your phone settings');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return tr('محتاج إذن الموقع عشان يحسب المسافة',
            'Location permission is needed to measure distance');
      }
      return null;
    } on Exception catch (_) {
      return tr('تعذّر الوصول للموقع', 'Could not access location');
    }
  }

  /// يبدأ/يكمّل التتبع.
  Future<void> start() async {
    if (_sub != null) return;
    _start = DateTime.now();
    _last = null;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    if (_last != null) {
      final d = Geolocator.distanceBetween(
        _last!.latitude,
        _last!.longitude,
        pos.latitude,
        pos.longitude,
      );
      // فلترة قفزات الـGPS غير الواقعية (دقة ضعيفة) — نتجاهل أي وثبة > 60 م.
      if (d.isFinite && d < 60) _meters += d;
    }
    _last = pos;
    onUpdate(ActivitySample(
      distanceMeters: _meters,
      elapsed: elapsed,
      speedKmh: pos.speed >= 0 ? pos.speed * 3.6 : null,
    ));
  }

  Duration get elapsed {
    if (_start == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_start!);
  }

  /// إيقاف مؤقّت — بيحافظ على المسافة والوقت المتراكم.
  void pause() {
    if (_start != null) {
      _accumulated += DateTime.now().difference(_start!);
      _start = null;
    }
    _sub?.cancel();
    _sub = null;
    _last = null;
  }

  /// إنهاء التتبع وإرجاع اللقطة النهائية.
  ActivitySample stop() {
    pause();
    return ActivitySample(distanceMeters: _meters, elapsed: elapsed);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

/// موقع الجهاز الحالي مرة واحدة (للـ«حدد موقعي تلقائيًا»). null لو فشل/مرفوض.
Future<Position?> currentPosition() async {
  if (kIsWeb) return null;
  final err = await WalkTracker.ensureReady();
  if (err != null) return null;
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 15));
  } on Exception catch (_) {
    return null;
  }
}

/// تقدير السعرات المحروقة (تقريبي): مسافة × وزن × معامل النشاط.
double estimateCalories({
  required double distanceKm,
  required double weightKg,
  required bool running,
}) {
  final factor = running ? 0.90 : 0.60; // سعرة لكل كجم لكل كم
  return distanceKm * weightKg * factor;
}

/// تقدير عدد الخطوات من المسافة (طول الخطوة ≈ 0.72 م).
int estimateSteps(double meters, {double stride = 0.72}) =>
    stride <= 0 ? 0 : (meters / stride).round();
