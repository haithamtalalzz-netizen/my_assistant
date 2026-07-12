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
        .query('prayer_log', where: 'day = ?', whereArgs: [dayKey(day)]);
    return rows.map((r) => r['prayer'] as int).toSet();
  }

  Future<Set<int>> prayedToday() => prayedOn(DateTime.now());

  Future<void> togglePrayer(DateTime day, int prayer, bool done) async {
    final db = await AppDb.instance;
    if (done) {
      await db.insert('prayer_log', {'day': dayKey(day), 'prayer': prayer},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('prayer_log',
          where: 'day = ? AND prayer = ?', whereArgs: [dayKey(day), prayer]);
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
    if (!complete.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    while (complete.contains(dayKey(d))) {
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

  // ---- تتبّع السنن والنوافل ----

  Future<Set<String>> sunnahDoneOn(DateTime day) async {
    final db = await AppDb.instance;
    final rows = await db
        .query('sunnah_log', where: 'day = ?', whereArgs: [dayKey(day)]);
    return rows.map((r) => r['name'] as String).toSet();
  }

  Future<void> toggleSunnah(DateTime day, String name, bool done) async {
    final db = await AppDb.instance;
    if (done) {
      await db.insert('sunnah_log', {'day': dayKey(day), 'name': name},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('sunnah_log',
          where: 'day = ? AND name = ?', whereArgs: [dayKey(day), name]);
    }
  }

  // ---- ختمة القرآن ----

  /// الختمة النشطة (أحدث واحدة) أو null.
  Future<Khatma?> activeKhatma() async {
    final db = await AppDb.instance;
    final rows = await db.query('quran_khatma',
        orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return Khatma.fromMap(rows.first);
  }

  Future<void> startKhatma({int dailyTarget = 4, int totalPages = 604}) async {
    final db = await AppDb.instance;
    final now = DateTime.now();
    await db.insert('quran_khatma', {
      'start_day': dayKey(now),
      'total_pages': totalPages,
      'current_page': 0,
      'daily_target': dailyTarget,
      'created_at': now.toIso8601String(),
    });
  }

  /// يسجّل ورد اليوم (عدد صفحات) — بيقدّم current_page ويسجّل فى khatma_reads.
  Future<void> logKhatmaRead(int pages) async {
    if (pages <= 0) return;
    final k = await activeKhatma();
    if (k == null) return;
    final db = await AppDb.instance;
    final now = DateTime.now();
    final next = (k.currentPage + pages).clamp(0, k.totalPages);
    await db.update('quran_khatma', {'current_page': next},
        where: 'id = ?', whereArgs: [k.id]);
    await db.insert('khatma_reads', {
      'day': dayKey(now),
      'pages': pages,
      'created_at': now.toIso8601String(),
    });
  }

  /// متوسط الصفحات فى اليوم من السجل الفعلى (0 لو مفيش).
  Future<double> khatmaAvgPerDay() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT day, SUM(pages) as p FROM khatma_reads GROUP BY day');
    if (rows.isEmpty) return 0;
    final total = rows.fold<int>(0, (s, r) => s + (r['p'] as int));
    return total / rows.length;
  }

  Future<void> resetKhatma() async {
    final db = await AppDb.instance;
    await db.delete('quran_khatma');
    await db.delete('khatma_reads');
  }
}

/// ختمة قرآن نشطة.
class Khatma {
  final int id;
  final String startDay;
  final int totalPages;
  final int currentPage;
  final int dailyTarget;

  Khatma({
    required this.id,
    required this.startDay,
    required this.totalPages,
    required this.currentPage,
    required this.dailyTarget,
  });

  int get remainingPages => (totalPages - currentPage).clamp(0, totalPages);
  double get progress => totalPages == 0 ? 0 : currentPage / totalPages;
  bool get done => currentPage >= totalPages;

  /// كام يوم فاضل بمعدّل معيّن (على الأقل الهدف اليومى).
  int daysToFinish(double avgPerDay) {
    final rate = avgPerDay > 0 ? avgPerDay : dailyTarget.toDouble();
    if (rate <= 0) return 0;
    return (remainingPages / rate).ceil();
  }

  factory Khatma.fromMap(Map<String, Object?> m) => Khatma(
        id: m['id'] as int,
        startDay: m['start_day'] as String,
        totalPages: m['total_pages'] as int,
        currentPage: m['current_page'] as int,
        dailyTarget: m['daily_target'] as int,
      );
}
