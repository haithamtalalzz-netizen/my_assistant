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

  /// يجدول تذكير قبل الدورة بيومين + بداية أيام الخصوبة (للسيدات فقط).
  Future<void> ensureReminders() async {
    await Notifications.cancel(Notifications.cyclePeriodNotifId);
    await Notifications.cancel(Notifications.cycleFertileNotifId);
    final settings = SettingsRepo();
    if (await settings.get('gender') != 'female') return;
    if (await settings.get('cycle_reminders') == '0') return;
    final p = await predict();
    if (!p.hasData || p.nextStart == null) return;

    final ns = p.nextStart!;
    final before =
        DateTime(ns.year, ns.month, ns.day, 9).subtract(const Duration(days: 2));
    await Notifications.scheduleOnce(
      id: Notifications.cyclePeriodNotifId,
      title: tr('الدورة قربت 🌸', 'Period is near 🌸'),
      body: tr('دورتك متوقّعة خلال يومين — جهّزي نفسك.',
          'Your period is expected in ~2 days.'),
      when: before,
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
