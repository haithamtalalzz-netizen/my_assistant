import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import 'income_repo.dart';
import 'meals_repo.dart';
import 'medical_repo.dart';
import 'meters_repo.dart';
import 'money_repo.dart';
import 'social_repo.dart';

/// حدث واحد في تقويم النتيجة — الشاشة بتحوّل [kind] لأيقونة.
class DayEvent {
  final String kind;
  final String text;

  /// وقت HH:mm لو متاح (للمواعيد) — للترتيب والعرض.
  final String? time;

  const DayEvent({required this.kind, required this.text, this.time});
}

/// بيجمّع كل اللي اتعمل في التطبيق في يوم معيّن — لتقويم المراجعة.
class DayLogRepo {
  static const List<String> _dayTables = [
    'expenses', 'income', 'meals', 'med_logs', 'habit_logs', 'workout_logs',
    'gym_sessions', 'measurements', 'medical_records', 'meter_readings',
    'social_obligations', 'water_logs', 'sleep_logs', 'steps_logs',
    'body_progress',
  ];

  /// أيام الشهر اللي فيها أي نشاط (لتنقيط خلايا التقويم).
  Future<Set<String>> daysWithActivity(int year, int month) async {
    final db = await AppDb.instance;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}%';
    final unions = [
      for (final t in _dayTables) 'SELECT day FROM $t WHERE day LIKE ?',
      "SELECT substr(when_at,1,10) AS day FROM appointments WHERE when_at LIKE ?",
    ].join(' UNION ');
    final args = [for (var i = 0; i < _dayTables.length + 1; i++) prefix];
    final rows =
        await db.rawQuery('SELECT DISTINCT day FROM ($unions)', args);
    return {for (final r in rows) r['day'] as String};
  }

  /// كل أحداث يوم معيّن، مرتبة بالوقت لو متاح.
  Future<List<DayEvent>> forDay(String day) async {
    final db = await AppDb.instance;
    final events = <DayEvent>[];

    // المواعيد.
    final appts = await db.query('appointments',
        where: "substr(when_at,1,10) = ?", whereArgs: [day]);
    for (final a in appts) {
      final when = DateTime.tryParse(a['when_at'] as String);
      final done = (a['done'] as int? ?? 0) == 1;
      events.add(DayEvent(
        kind: 'appointment',
        time: when == null
            ? null
            : '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
        text: '${done ? '✓ ' : ''}${a['title']}',
      ));
    }

    // المصاريف.
    for (final e in await db.query('expenses',
        where: 'day = ?', whereArgs: [day])) {
      events.add(DayEvent(
        kind: 'expense',
        text: tr('مصروف: ${egp((e['amount'] as num).toDouble())} — '
            '${expenseCategoryLabel(e['category'] as String)}',
            'Spent: ${egp((e['amount'] as num).toDouble())} — '
            '${expenseCategoryLabel(e['category'] as String)}'),
      ));
    }

    // الدخل.
    for (final i in await db.query('income',
        where: 'day = ?', whereArgs: [day])) {
      events.add(DayEvent(
        kind: 'income',
        text: tr('دخل: ${egp((i['amount'] as num).toDouble())} — '
            '${incomeSourceLabel(i['source'] as String)}',
            'Income: ${egp((i['amount'] as num).toDouble())} — '
            '${incomeSourceLabel(i['source'] as String)}'),
      ));
    }

    // الوجبات.
    for (final m in await db.query('meals',
        where: 'day = ?', whereArgs: [day])) {
      events.add(DayEvent(
        kind: 'meal',
        text: '${mealSlotLabel(m['slot'] as String)}: ${m['description']}',
      ));
    }

    // جرعات الدوا.
    final meds = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM med_logs WHERE day = ?', [day]);
    final medCount = (meds.first['c'] as num).toInt();
    if (medCount > 0) {
      events.add(DayEvent(
          kind: 'med',
          text: tr('${arNum(medCount)} جرعة دوا اتاخدت',
              '${arNum(medCount)} med doses taken')));
    }

    // العادات.
    final habits = await db.rawQuery('''
      SELECT h.name AS name FROM habit_logs l
      JOIN habits h ON h.id = l.habit_id WHERE l.day = ?
    ''', [day]);
    for (final h in habits) {
      events.add(DayEvent(
          kind: 'habit',
          text: tr('عادة: ${h['name']}', 'Habit: ${h['name']}')));
    }

    // التمرين + جلسات الجيم.
    for (final w in await db.query('workout_logs',
        where: 'day = ?', whereArgs: [day])) {
      final title = (w['title'] as String? ?? '').trim();
      events.add(DayEvent(
          kind: 'workout',
          text: title.isEmpty
              ? tr('تمرين اتعمل', 'Workout done')
              : tr('تمرين: $title', 'Workout: $title')));
    }
    for (final g in await db.query('gym_sessions',
        where: 'day = ?', whereArgs: [day])) {
      final prog = (g['program'] as String? ?? '').trim();
      final sets = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM gym_sets WHERE session_id = ?', [g['id']]);
      final c = (sets.first['c'] as num).toInt();
      events.add(DayEvent(
          kind: 'gym',
          text: tr('جيم${prog.isEmpty ? '' : ' ($prog)'}: ${arNum(c)} مجموعة',
              'Gym${prog.isEmpty ? '' : ' ($prog)'}: ${arNum(c)} sets')));
    }

    // القياسات.
    for (final m in await db.query('measurements',
        where: 'day = ?', whereArgs: [day])) {
      final v = (m['value'] as num).toDouble();
      final v2 = (m['value2'] as num?)?.toDouble();
      final val = v2 != null
          ? '${arNum(v.toInt())}/${arNum(v2.toInt())}'
          : arNum(v % 1 == 0 ? v.toInt() : v);
      events.add(DayEvent(
          kind: 'measurement', text: '${m['type']}: $val ${m['unit'] ?? ''}'));
    }

    // السجلات الطبية.
    for (final r in await db.query('medical_records',
        where: 'day = ?', whereArgs: [day])) {
      events.add(DayEvent(
          kind: 'medical',
          text: '${medicalTypeLabel(r['type'] as String)}: ${r['title']}'));
    }

    // قراءات العدادات.
    for (final r in await db.query('meter_readings',
        where: 'day = ?', whereArgs: [day])) {
      events.add(DayEvent(
          kind: 'meter',
          text: tr('عداد ${meterTypeLabel(r['meter_type'] as String)}: '
              '${arNum((r['reading'] as num).toDouble())}',
              'Meter ${meterTypeLabel(r['meter_type'] as String)}: '
              '${arNum((r['reading'] as num).toDouble())}')));
    }

    // الواجبات الاجتماعية.
    for (final s in await db.query('social_obligations',
        where: 'day = ?', whereArgs: [day])) {
      final amt = (s['amount'] as num?)?.toDouble();
      events.add(DayEvent(
          kind: 'social',
          text: '${socialTypeLabel(s['type'] as String)} '
              '${socialDirectionLabel(s['direction'] as String)} '
              '${s['person']}${amt == null ? '' : ' — ${egp(amt)}'}'));
    }

    // لقطة صحة اليوم: مياه/نوم/خطوات.
    final water = await db.query('water_logs',
        where: 'day = ?', whereArgs: [day]);
    if (water.isNotEmpty && (water.first['glasses'] as num).toInt() > 0) {
      events.add(DayEvent(
          kind: 'health',
          text: tr('مياه: ${arNum((water.first['glasses'] as num).toInt())} كوباية',
              'Water: ${arNum((water.first['glasses'] as num).toInt())} cups')));
    }
    final sleep = await db.query('sleep_logs',
        where: 'day = ?', whereArgs: [day]);
    if (sleep.isNotEmpty) {
      final h = (sleep.first['hours'] as num).toDouble();
      events.add(DayEvent(
          kind: 'health',
          text: tr('نوم: ${arNum(h % 1 == 0 ? h.toInt() : h)} ساعة',
              'Sleep: ${arNum(h % 1 == 0 ? h.toInt() : h)} h')));
    }
    final steps = await db.query('steps_logs',
        where: 'day = ?', whereArgs: [day]);
    if (steps.isNotEmpty && (steps.first['steps'] as num).toInt() > 0) {
      events.add(DayEvent(
          kind: 'health',
          text: tr('خطوات: ${arNum((steps.first['steps'] as num).toInt())}',
              'Steps: ${arNum((steps.first['steps'] as num).toInt())}')));
    }

    // ترتيب: اللي ليه وقت الأول بالوقت، وبعدين الباقي.
    events.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return a.time!.compareTo(b.time!);
    });
    return events;
  }
}
