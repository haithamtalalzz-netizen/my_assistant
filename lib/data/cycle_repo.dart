import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';
import 'settings_repo.dart';

// ---- خيارات التسجيل اليومي (مفاتيح ثابتة + عرض ثنائي اللغة) ----
const List<String> kMoods = [
  'happy', 'calm', 'sad', 'irritable', 'anxious', 'upset', 'energetic', 'tired'
];

String moodEmoji(String k) => switch (k) {
      'happy' => '😊',
      'calm' => '😌',
      'sad' => '😢',
      'irritable' => '😠',
      'anxious' => '😟',
      'upset' => '😞',
      'energetic' => '⚡',
      'tired' => '😴',
      _ => '🙂',
    };

String moodLabel(String k) => switch (k) {
      'happy' => tr('سعيدة', 'Happy'),
      'calm' => tr('هادئة', 'Calm'),
      'sad' => tr('حزينة', 'Sad'),
      'irritable' => tr('عصبية', 'Irritable'),
      'anxious' => tr('قلقانة', 'Anxious'),
      'upset' => tr('متضايقة', 'Upset'),
      'energetic' => tr('نشيطة', 'Energetic'),
      'tired' => tr('مرهقة', 'Tired'),
      _ => k,
    };

const List<String> kSymptoms = [
  'cramps', 'headache', 'bloating', 'backache', 'fatigue',
  'acne', 'breast', 'nausea', 'cravings'
];

String symptomLabel(String k) => switch (k) {
      'cramps' => tr('مغص', 'Cramps'),
      'headache' => tr('صداع', 'Headache'),
      'bloating' => tr('انتفاخ', 'Bloating'),
      'backache' => tr('ألم ظهر', 'Backache'),
      'fatigue' => tr('إرهاق', 'Fatigue'),
      'acne' => tr('حبوب', 'Acne'),
      'breast' => tr('ألم صدر', 'Breast pain'),
      'nausea' => tr('غثيان', 'Nausea'),
      'cravings' => tr('نهم أكل', 'Cravings'),
      _ => k,
    };

const List<String> kFlows = ['light', 'medium', 'heavy'];

String flowLabel(String k) => switch (k) {
      'light' => tr('خفيف', 'Light'),
      'medium' => tr('متوسط', 'Medium'),
      'heavy' => tr('غزير', 'Heavy'),
      _ => k,
    };

// ---- مراحل الدورة (لتحليل الأنماط) ----
const List<String> kPhases = ['period', 'follicular', 'ovulation', 'luteal'];

String phaseName(String k) => switch (k) {
      'period' => tr('الدورة', 'Period'),
      'follicular' => tr('قبل التبويض', 'Follicular'),
      'ovulation' => tr('التبويض', 'Ovulation'),
      'luteal' => tr('ما قبل الطمث', 'Luteal (PMS)'),
      _ => k,
    };

/// أنماط الأعراض والمزاج في مرحلة معيّنة.
class PhaseInsight {
  final String phase;
  final int days;
  final List<MapEntry<String, int>> topSymptoms;
  final String? topMood;
  const PhaseInsight(this.phase, this.days, this.topSymptoms, this.topMood);
}

/// مقارنة النوم/المياه/الوزن بين (الدورة + ما قبل الطمث) وباقي الشهر.
class CycleHealthLink {
  final double? sleepSensitive, sleepRest;
  final double? waterSensitive, waterRest;
  final double? weightSensitive, weightRest;
  const CycleHealthLink({
    this.sleepSensitive,
    this.sleepRest,
    this.waterSensitive,
    this.waterRest,
    this.weightSensitive,
    this.weightRest,
  });
  bool get hasAny =>
      (sleepSensitive != null && sleepRest != null) ||
      (waterSensitive != null && waterRest != null) ||
      (weightSensitive != null && weightRest != null);
}

/// توقّعات الدورة الشهرية المحسوبة من التواريخ المسجّلة.
class CyclePrediction {
  final int loggedCount;
  final int avgCycleLength; // متوسط طول الدورة
  final DateTime? lastStart;
  final DateTime? nextStart;
  final int? currentDay; // اليوم الحالي في الدورة
  final int? daysUntilNext; // كام يوم على الدورة الجاية
  final DateTime? ovulation; // يوم التبويض المتوقّع
  final DateTime? fertileStart;
  final DateTime? fertileEnd;

  const CyclePrediction({
    this.loggedCount = 0,
    this.avgCycleLength = 28,
    this.lastStart,
    this.nextStart,
    this.currentDay,
    this.daysUntilNext,
    this.ovulation,
    this.fertileStart,
    this.fertileEnd,
  });

  bool get hasData => lastStart != null;
}

class CycleRepo {
  Future<int> add(CycleLog log) async {
    final db = await AppDb.instance;
    return db.insert('cycle_logs', log.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('cycle_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// كل الدورات المسجّلة — الأحدث الأول.
  Future<List<CycleLog>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('cycle_logs', orderBy: 'start_day DESC');
    return rows.map(CycleLog.fromMap).toList();
  }

  // ---- التسجيل اليومي (مزاج/أعراض/شدة نزيف/وزن) ----

  Future<CycleDay?> dayLog(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('cycle_days', where: 'day = ?', whereArgs: [day]);
    return rows.isEmpty ? null : CycleDay.fromMap(rows.first);
  }

  Future<void> saveDay(CycleDay d) async {
    final db = await AppDb.instance;
    // لو كل الحقول فاضية، امسح السجل بدل ما نخزّن سطر فاضي.
    if (d.mood.isEmpty &&
        d.symptoms.isEmpty &&
        d.flow.isEmpty &&
        d.weight == null &&
        d.note.isEmpty) {
      await db.delete('cycle_days', where: 'day = ?', whereArgs: [d.day]);
      return;
    }
    await db.insert('cycle_days', d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CycleDay>> recentDays({int limit = 30}) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('cycle_days', orderBy: 'day DESC', limit: limit);
    return rows.map(CycleDay.fromMap).toList();
  }

  // ---- حبوب منع الحمل ----

  Future<bool> pillTakenOn(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('pill_logs', where: 'day = ?', whereArgs: [day]);
    return rows.isNotEmpty;
  }

  Future<void> setPillTaken(String day, bool taken) async {
    final db = await AppDb.instance;
    if (taken) {
      await db.insert('pill_logs',
          {'day': day, 'created_at': DateTime.now().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('pill_logs', where: 'day = ?', whereArgs: [day]);
    }
  }

  /// عدد الأيام المتتالية اللي اتاخدت فيها الحبة لحد النهاردة.
  Future<int> pillStreak() async {
    final db = await AppDb.instance;
    final rows = await db.query('pill_logs');
    final set = {for (final r in rows) r['day'] as String};
    var streak = 0;
    var d = dateOnly(DateTime.now());
    while (set.contains(dayKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---- مدة الدورة ----

  Future<void> updatePeriodLength(int id, int days) async {
    final db = await AppDb.instance;
    await db.update('cycle_logs', {'period_days': days.clamp(1, 14)},
        where: 'id = ?', whereArgs: [id]);
  }

  /// الفروق بين الدورات المتتالية (بالأيام) — لرسم الانتظام.
  Future<List<int>> cycleIntervals() async {
    final starts = (await all())
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();
    final out = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final diff = starts[i].difference(starts[i - 1]).inDays;
      if (diff >= 10 && diff <= 90) out.add(diff);
    }
    return out;
  }

  /// مقارنة النوم/المياه/الوزن بين مرحلة (الدورة+PMS) وباقي الشهر (آخر ~90 يوم).
  Future<CycleHealthLink> phaseHealth() async {
    final logs = await all();
    final starts = logs
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();
    if (starts.isEmpty) return const CycleHealthLink();

    var avg = 28;
    if (starts.length >= 2) {
      var sum = 0, n = 0;
      for (var i = 1; i < starts.length; i++) {
        final diff = starts[i].difference(starts[i - 1]).inDays;
        if (diff >= 15 && diff <= 60) {
          sum += diff;
          n++;
        }
      }
      if (n > 0) avg = (sum / n).round().clamp(21, 40);
    }
    final ov = avg - 14;

    final db = await AppDb.instance;
    final now = dateOnly(DateTime.now());
    final fromKey = dayKey(now.subtract(const Duration(days: 89)));
    final waterRows = await db
        .query('water_logs', where: 'day >= ?', whereArgs: [fromKey]);
    final sleepRows = await db
        .query('sleep_logs', where: 'day >= ?', whereArgs: [fromKey]);
    final waterBy = {
      for (final r in waterRows) r['day'] as String: (r['glasses'] as num).toDouble()
    };
    final sleepBy = {
      for (final r in sleepRows) r['day'] as String: (r['hours'] as num).toDouble()
    };
    final weightBy = {
      for (final d in await recentDays(limit: 400))
        if (d.weight != null) d.day: d.weight!
    };

    final sS = <double>[], sR = <double>[]; // sleep
    final wS = <double>[], wR = <double>[]; // water
    final gS = <double>[], gR = <double>[]; // weight
    for (var i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      DateTime? ref;
      for (final s in starts) {
        if (!s.isAfter(date)) ref = s;
      }
      if (ref == null) continue;
      final cd = date.difference(ref).inDays + 1;
      final sensitive = cd <= 5 || cd > ov + 1; // الدورة أو ما قبل الطمث
      final key = dayKey(date);
      if (sleepBy[key] != null) (sensitive ? sS : sR).add(sleepBy[key]!);
      if (waterBy[key] != null) (sensitive ? wS : wR).add(waterBy[key]!);
      if (weightBy[key] != null) (sensitive ? gS : gR).add(weightBy[key]!);
    }
    double? avgOf(List<double> l) =>
        l.isEmpty ? null : l.reduce((a, b) => a + b) / l.length;
    return CycleHealthLink(
      sleepSensitive: avgOf(sS),
      sleepRest: avgOf(sR),
      waterSensitive: avgOf(wS),
      waterRest: avgOf(wR),
      weightSensitive: avgOf(gS),
      weightRest: avgOf(gR),
    );
  }

  /// تحليل الأعراض والمزاج حسب مرحلة الدورة (من التسجيلات اليومية).
  Future<List<PhaseInsight>> phaseInsights() async {
    final days = await recentDays(limit: 400);
    final logs = await all();
    final starts = logs
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();
    if (starts.isEmpty || days.isEmpty) return [];

    var avg = 28;
    if (starts.length >= 2) {
      var sum = 0, n = 0;
      for (var i = 1; i < starts.length; i++) {
        final diff = starts[i].difference(starts[i - 1]).inDays;
        if (diff >= 15 && diff <= 60) {
          sum += diff;
          n++;
        }
      }
      if (n > 0) avg = (sum / n).round().clamp(21, 40);
    }
    final ov = avg - 14;

    final symptomCounts = {for (final p in kPhases) p: <String, int>{}};
    final moodCounts = {for (final p in kPhases) p: <String, int>{}};
    final phaseDays = {for (final p in kPhases) p: 0};

    for (final d in days) {
      final date = DateTime.tryParse(d.day);
      if (date == null) continue;
      final dd = dateOnly(date);
      DateTime? ref;
      for (final s in starts) {
        if (!s.isAfter(dd)) ref = s;
      }
      if (ref == null) continue;
      final cd = dd.difference(ref).inDays + 1;
      final phase = cd <= 5
          ? 'period'
          : cd < ov
              ? 'follicular'
              : cd <= ov + 1
                  ? 'ovulation'
                  : 'luteal';
      phaseDays[phase] = phaseDays[phase]! + 1;
      if (d.mood.isNotEmpty) {
        moodCounts[phase]![d.mood] = (moodCounts[phase]![d.mood] ?? 0) + 1;
      }
      for (final sy in d.symptomList) {
        symptomCounts[phase]![sy] = (symptomCounts[phase]![sy] ?? 0) + 1;
      }
    }

    final out = <PhaseInsight>[];
    for (final phase in kPhases) {
      if (phaseDays[phase] == 0) continue;
      final syms = symptomCounts[phase]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      String? topMood;
      var maxMood = 0;
      moodCounts[phase]!.forEach((k, v) {
        if (v > maxMood) {
          maxMood = v;
          topMood = k;
        }
      });
      out.add(PhaseInsight(
          phase, phaseDays[phase]!, syms.take(3).toList(), topMood));
    }
    return out;
  }

  /// يجدول تذكيرات الدورة + حبوب منع الحمل (للسيدات فقط).
  Future<void> ensureReminders() async {
    await Notifications.cancel(Notifications.cyclePeriodNotifId);
    await Notifications.cancel(Notifications.cycleFertileNotifId);
    await Notifications.cancel(Notifications.cycleLateNotifId);
    await Notifications.cancel(Notifications.cycleCareNotifId);
    await Notifications.cancel(Notifications.pillNotifId);
    final settings = SettingsRepo();
    if (await settings.get('gender') != 'female') return;

    // تذكير حبوب منع الحمل اليومي (مستقل عن تذكيرات الدورة).
    if (await settings.get('pill_reminder') == '1') {
      final t = (await settings.get('pill_time') ?? '21:00').split(':');
      await Notifications.scheduleDaily(
        id: Notifications.pillNotifId,
        title: tr('حبة منع الحمل 💊', 'Birth-control pill 💊'),
        body: tr('متنسيش تاخدي حبتك النهاردة.',
            "Don't forget to take your pill today."),
        hour: int.tryParse(t[0]) ?? 21,
        minute: t.length > 1 ? int.tryParse(t[1]) ?? 0 : 0,
      );
    }

    if (await settings.get('cycle_reminders') == '0') return;
    final p = await predict();
    if (!p.hasData || p.nextStart == null) return;
    final ns = p.nextStart!;

    await Notifications.scheduleOnce(
      id: Notifications.cyclePeriodNotifId,
      title: tr('الدورة قربت 🌸', 'Period is near 🌸'),
      body: tr('دورتك متوقّعة خلال يومين — جهّزي نفسك.',
          'Your period is expected in ~2 days.'),
      when: DateTime(ns.year, ns.month, ns.day, 9)
          .subtract(const Duration(days: 2)),
    );
    // عناية أثناء الدورة (يوم البداية المتوقّع).
    await Notifications.scheduleOnce(
      id: Notifications.cycleCareNotifId,
      title: tr('فترة الدورة 🌸', 'Your period 🌸'),
      body: tr('اشربي مياه كفاية وارتاحي — واسجّلي بدايتها.',
          'Drink enough water & rest — and log its start.'),
      when: DateTime(ns.year, ns.month, ns.day, 10),
    );
    // تنبيه تأخّر الدورة (بعد الموعد بـ3 أيام).
    await Notifications.scheduleOnce(
      id: Notifications.cycleLateNotifId,
      title: tr('دورتك اتأخرت ⏰', 'Period is late ⏰'),
      body: tr('عدّى 3 أيام على المتوقّع — سجّليها أو اطمني باختبار حمل.',
          "3 days past due — log it, or consider a pregnancy test."),
      when: DateTime(ns.year, ns.month, ns.day, 11)
          .add(const Duration(days: 3)),
    );
    final fs = p.fertileStart;
    if (fs != null) {
      await Notifications.scheduleOnce(
        id: Notifications.cycleFertileNotifId,
        title: tr('أيام الخصوبة بدأت', 'Fertile window started'),
        body: tr('فترة الخصوبة المتوقّعة بدأت النهاردة.',
            'Your predicted fertile window starts today.'),
        when: DateTime(fs.year, fs.month, fs.day, 9),
      );
    }
  }

  /// يحسب التوقّعات من التواريخ المسجّلة.
  Future<CyclePrediction> predict() async {
    final logs = await all();
    if (logs.isEmpty) return const CyclePrediction();

    // تواريخ البداية تصاعديًا.
    final starts = logs
        .map((l) => DateTime.tryParse(l.startDay))
        .whereType<DateTime>()
        .map(dateOnly)
        .toList()
      ..sort();
    if (starts.isEmpty) return const CyclePrediction();

    // متوسط طول الدورة من الفروق بين البدايات المتتالية.
    var avg = 28;
    if (starts.length >= 2) {
      var sum = 0;
      var n = 0;
      for (var i = 1; i < starts.length; i++) {
        final diff = starts[i].difference(starts[i - 1]).inDays;
        if (diff >= 15 && diff <= 60) {
          sum += diff;
          n++;
        }
      }
      if (n > 0) avg = (sum / n).round().clamp(21, 40);
    }

    final last = starts.last;
    final today = dateOnly(DateTime.now());
    final next = last.add(Duration(days: avg));
    final ovulation = next.subtract(const Duration(days: 14));
    final currentDay = today.difference(last).inDays + 1;

    return CyclePrediction(
      loggedCount: starts.length,
      avgCycleLength: avg,
      lastStart: last,
      nextStart: next,
      currentDay: currentDay >= 1 ? currentDay : null,
      daysUntilNext: next.difference(today).inDays,
      ovulation: ovulation,
      fertileStart: ovulation.subtract(const Duration(days: 5)),
      fertileEnd: ovulation.add(const Duration(days: 1)),
    );
  }
}
