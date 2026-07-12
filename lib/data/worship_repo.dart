import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import 'settings_repo.dart';

/// إحداثيات الكعبة المشرّفة — لحساب اتجاه القبلة.
const double kKaabaLat = 21.4224779;
const double kKaabaLng = 39.6357155;

/// اتجاه القبلة (درجة من الشمال، باتجاه عقارب الساعة) من موقع المستخدم.
double qiblaBearing(double lat, double lng) {
  final phi1 = lat * math.pi / 180;
  final phi2 = kKaabaLat * math.pi / 180;
  final dLng = (kKaabaLng - lng) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
  final theta = math.atan2(y, x);
  return (theta * 180 / math.pi + 360) % 360;
}

/// عبادات: تتبّع الصلوات الخمس + عدّاد المسبحة.
class WorshipRepo {
  final _settings = SettingsRepo();

  // ---- تتبّع الصلوات ----

  /// أرقام الصلوات (0..4) اللى اتصلّت النهارده.
  Future<Set<int>> prayedOn(DateTime day) async {
    final db = await AppDb.instance;
    final rows = await db
        .query('prayer_log', where: 'day = ?', whereArgs: [dateKey(day)]);
    return rows.map((r) => r['prayer'] as int).toSet();
  }

  Future<Set<int>> prayedToday() => prayedOn(DateTime.now());

  Future<void> togglePrayer(DateTime day, int prayer, bool done) async {
    final db = await AppDb.instance;
    if (done) {
      await db.insert('prayer_log', {'day': dateKey(day), 'prayer': prayer},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('prayer_log',
          where: 'day = ? AND prayer = ?', whereArgs: [dateKey(day), prayer]);
    }
  }

  /// عدد الأيام المتتالية اللى اتصلّى فيها الخمس صلوات كاملة (بينتهى عند اليوم).
  Future<int> fullDaysStreak() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT day, COUNT(*) as c FROM prayer_log GROUP BY day HAVING c >= 5');
    final complete = rows.map((r) => r['day'] as String).toSet();
    var streak = 0;
    var d = dateOnly(DateTime.now());
    // لو النهارده لسه مكملش، نبدأ العد من امبارح.
    if (!complete.contains(dateKey(d))) d = d.subtract(const Duration(days: 1));
    while (complete.contains(dateKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- المسبحة ----

  Future<int> tasbihTotal() async =>
      int.tryParse(await _settings.get('tasbih_total') ?? '') ?? 0;

  Future<void> addTasbih(int n) async {
    final cur = await tasbihTotal();
    await _settings.set('tasbih_total', '${cur + n}');
  }

  Future<void> resetTasbih() async => _settings.set('tasbih_total', '0');
}

/// مفتاح اليوم (YYYY-MM-DD) — نفس صيغة باقى الجداول.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
