import 'log.dart';
import 'dart:io' show Platform;

import 'package:health/health.dart';

import 'ar.dart';

/// غلاف Health Connect (أندرويد) / HealthKit (iOS مستقبلًا) — قراءة فقط.
/// بيغطي أي ساعة ذكية بتكتب لـ Health Connect: سامسونج، Wear OS، Fitbit،
/// Garmin، وهواوي (لو تطبيقها بيصدّر لـ Health Connect). آبل ووتش هتشتغل
/// أوتوماتيك على نسخة iOS بنفس الكود (نفس مكتبة `health`).
///
/// كل النداءات best-effort: أي فشل يرجع null/false من غير ما يكسر حاجة.
class HealthService {
  HealthService._();

  static final Health _health = Health();
  static bool _configured = false;

  /// أنواع البيانات اللي بنطلب إذن قراءتها — واحدة مركزية عشان الطلب متسق.
  /// المسافة نوعها مختلف بين المنصتين، فبنختار حسب المنصة.
  static List<HealthDataType> get _readTypes => [
        HealthDataType.STEPS,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        _distanceType,
        HealthDataType.WORKOUT,
      ];

  static HealthDataType get _distanceType => Platform.isIOS
      ? HealthDataType.DISTANCE_WALKING_RUNNING
      : HealthDataType.DISTANCE_DELTA;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  static Future<bool> available() async {
    try {
      await _ensureConfigured();
      // على iOS مفيش Health Connect لكن HealthKit متاح دايمًا.
      if (Platform.isIOS) return true;
      return await _health.isHealthConnectAvailable();
    } on Exception catch (e) {
      logError('Health Connect مش متاح', e);
      return false;
    }
  }

  /// يطلب أذونات قراءة كل مقاييس اللياقة — يرجع true لو المستخدم وافق.
  static Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final types = _readTypes;
      return await _health.requestAuthorization(
        types,
        permissions: [for (final _ in types) HealthDataAccess.READ],
      );
    } on Exception catch (e) {
      logError('فشل طلب أذونات الصحة', e);
      return false;
    }
  }

  static Future<int?> stepsToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      return await _health.getTotalStepsInInterval(dateOnly(now), now);
    } on Exception catch (e) {
      logError('فشل قراءة الخطوات', e);
      return null;
    }
  }

  /// مجموع السعرات النشطة المحروقة النهارده (kcal) — من الساعة.
  static Future<int?> activeCaloriesToday() async {
    final total = await _sumToday(HealthDataType.ACTIVE_ENERGY_BURNED);
    if (total == null || total <= 0) return null;
    return total.round();
  }

  /// المسافة المقطوعة النهارده بالكيلومتر (المصدر بالمتر).
  static Future<double?> distanceTodayKm() async {
    final meters = await _sumToday(_distanceType);
    if (meters == null || meters <= 0) return null;
    return (meters / 1000 * 100).roundToDouble() / 100; // تقريب لخانتين
  }

  /// نبض الراحة (أحدث قراءة آخر ٢٤ ساعة) — بديل لمتوسط النبض لو مش متاح.
  static Future<int?> restingHeartRate() async {
    final resting = await _latestToday(HealthDataType.RESTING_HEART_RATE);
    if (resting != null) return resting.round();
    final latest = await _latestToday(HealthDataType.HEART_RATE);
    return latest?.round();
  }

  /// عدد جلسات التمرين النهارده (من الساعة) — لربطها بخطة التمرين.
  static Future<int?> workoutsToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: dateOnly(now),
        endTime: now,
      );
      final clean = _health.removeDuplicates(points);
      return clean.isEmpty ? null : clean.length;
    } on Exception catch (e) {
      logError('فشل قراءة التمارين', e);
      return null;
    }
  }

  /// مجموع ساعات نوم آخر ليلة (من ٦ مساء امبارح لـ ١٢ ظهر النهارده).
  static Future<double?> lastNightSleepHours() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final today = dateOnly(now);
      final sessions = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: today.subtract(const Duration(hours: 6)),
        endTime: today.add(const Duration(hours: 12)),
      );
      if (sessions.isEmpty) return null;
      var total = Duration.zero;
      for (final s in _health.removeDuplicates(sessions)) {
        total += s.dateTo.difference(s.dateFrom);
      }
      final hours = total.inMinutes / 60.0;
      if (hours <= 0 || hours > 16) return null;
      // نقرب لأقرب نص ساعة — كفاية للعرض والنصايح.
      return (hours * 2).roundToDouble() / 2;
    } on Exception catch (e) {
      logError('فشل قراءة النوم', e);
      return null;
    }
  }

  // ————— أدوات داخلية —————

  /// مجموع قيم نوع رقمي على مدار النهارده (بعد إزالة التكرار من مصادر متعددة).
  static Future<double?> _sumToday(HealthDataType type) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: dateOnly(now),
        endTime: now,
      );
      final clean = _health.removeDuplicates(points);
      if (clean.isEmpty) return null;
      var sum = 0.0;
      for (final p in clean) {
        final v = _numeric(p);
        if (v != null) sum += v;
      }
      return sum;
    } on Exception catch (e) {
      logError('فشل قراءة $type', e);
      return null;
    }
  }

  /// أحدث قراءة رقمية لنوع النهارده.
  static Future<double?> _latestToday(HealthDataType type) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
      );
      if (points.isEmpty) return null;
      points.sort((a, b) => a.dateTo.compareTo(b.dateTo));
      return _numeric(points.last);
    } on Exception catch (e) {
      logError('فشل قراءة $type', e);
      return null;
    }
  }

  static double? _numeric(HealthDataPoint p) {
    final v = p.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return null;
  }
}
