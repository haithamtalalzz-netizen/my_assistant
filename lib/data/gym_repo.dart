import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';
import 'settings_repo.dart';
import 'workout_repo.dart';

/// أوضاع التمرين الجاهزة → توزيع أيام الأسبوع (Dart weekday: 1=إثنين..7=أحد).
/// الأسبوع بيبدأ سبت في مصر، فبنبدأ من 6 (السبت).
const Map<String, Map<int, String>> kGymPrograms = {
  'ppl': {6: 'دفع', 7: 'سحب', 1: 'أرجل', 2: 'دفع', 3: 'سحب', 4: 'أرجل'},
  'upperlower': {6: 'علوي', 7: 'سفلي', 2: 'علوي', 3: 'سفلي'},
  'fullbody': {6: 'فل بودي', 1: 'فل بودي', 3: 'فل بودي'},
  'home': {6: 'تمرين بيت', 1: 'تمرين بيت', 3: 'تمرين بيت'},
  'cardio': {6: 'كارديو', 1: 'كارديو', 3: 'كارديو', 5: 'كارديو'},
};

String gymProgramLabel(String key) => switch (key) {
      'ppl' => tr('دفع/سحب/أرجل (PPL)', 'Push / Pull / Legs'),
      'upperlower' => tr('علوي/سفلي', 'Upper / Lower'),
      'fullbody' => tr('فل بودي', 'Full body'),
      'home' => tr('تمرين بيت', 'Home workout'),
      'cardio' => tr('كارديو', 'Cardio'),
      _ => key,
    };

/// مكتبة تمارين جاهزة للاختيار السريع (المستخدم يقدر يكتب أي تمرين تاني).
const Map<String, List<String>> kGymExercises = {
  'صدر': ['بنش برس', 'بنش مايل', 'تفتيح', 'ضغط'],
  'ظهر': ['عقلة', 'سحب أرضي', 'سحب علوي', 'رفعة ميتة'],
  'أرجل': ['سكوات', 'دفع أرجل', 'دِدلِفت رجل', 'سمانة'],
  'أكتاف': ['ضغط كتف', 'رفرفة جانبي', 'رفرفة أمامي'],
  'ذراع': ['مرجحة بايسبس', 'ترايسبس', 'فرنسي', 'باتشيكر'],
  'بطن': ['كرانش', 'بلانك', 'رفع أرجل'],
};

class GymRepo {
  final _settings = SettingsRepo();

  // ---- الوضع الحالي ----

  Future<String> currentProgram() async =>
      await _settings.get('gym_program') ?? '';

  /// يفعّل وضع تمرين: بيكتب توزيعه في الخطة الأسبوعية (فبيظهر في اليوم والتذكيرات).
  Future<void> setProgram(String key) async {
    await _settings.set('gym_program', key);
    final preset = kGymPrograms[key];
    if (preset != null) await WorkoutRepo().savePlan(Map.of(preset));
  }

  // ---- الجلسات والمجموعات ----

  Future<int> addSession(GymSession s) async {
    final db = await AppDb.instance;
    return db.insert('gym_sessions', s.toMap());
  }

  Future<void> addSet(GymSet s) async {
    final db = await AppDb.instance;
    await db.insert('gym_sets', s.toMap());
  }

  Future<void> deleteSession(int id) async {
    final db = await AppDb.instance;
    await db.delete('gym_sets', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('gym_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GymSession>> recentSessions({int limit = 30}) async {
    final db = await AppDb.instance;
    final rows = await db.query('gym_sessions',
        orderBy: 'day DESC, id DESC', limit: limit);
    return rows.map(GymSession.fromMap).toList();
  }

  Future<List<GymSet>> setsFor(int sessionId) async {
    final db = await AppDb.instance;
    final rows = await db.query('gym_sets',
        where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'set_index, id');
    return rows.map(GymSet.fromMap).toList();
  }

  /// أعلى وزن مسجّل لكل تمرين (PR) — مرتب تنازليًا بالوزن.
  Future<List<({String exercise, double weight, int reps})>>
      personalRecords() async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery('''
      SELECT s.exercise AS exercise, s.weight AS weight, s.reps AS reps
      FROM gym_sets s
      JOIN (
        SELECT exercise, MAX(weight) AS mw FROM gym_sets
        WHERE weight > 0 GROUP BY exercise
      ) best ON s.exercise = best.exercise AND s.weight = best.mw
      GROUP BY s.exercise
      ORDER BY s.weight DESC
    ''');
    return [
      for (final r in rows)
        (
          exercise: r['exercise'] as String,
          weight: (r['weight'] as num).toDouble(),
          reps: (r['reps'] as num).toInt(),
        )
    ];
  }
}
