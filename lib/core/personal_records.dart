import 'package:sqflite/sqflite.dart';

import '../data/habits_repo.dart';
import '../data/worship_repo.dart';
import 'ar.dart';
import 'db.dart';
import 'l10n.dart';

/// رقم قياسي شخصي واحد — أفضل ما حقّقه المستخدم في بند ما.
/// خالص من Flutter (قابل للاختبار)؛ الشاشة بتحوّل [emoji] لأيقونة/لون.
class PersonalRecord {
  final String emoji;
  final String label;
  final String value;

  /// سطر سياق تحت القيمة (اليوم/الشهر) — اختياري.
  final String? sub;

  const PersonalRecord(this.emoji, this.label, this.value, [this.sub]);
}

String _onDay(String? isoDay) {
  if (isoDay == null || isoDay.isEmpty) return '';
  try {
    final d = DateTime.tryParse(isoDay);
    return d != null ? tr('يوم ', 'on ') + arShortDate(d) : isoDay;
  } catch (_) {
    return isoDay; // locale not ready → raw ISO is fine as context
  }
}

String _inMonth(String? ym) {
  if (ym == null || ym.isEmpty) return '';
  try {
    final d = DateTime.tryParse('$ym-01');
    return d != null ? arMonth(d) : ym;
  } catch (_) {
    return ym;
  }
}

/// بيحسب كل الأرقام القياسية من الجداول الموجودة — قراءة فقط، بدون أى كتابة.
/// كل رقم داخل حارس مستقل فبند بلا بيانات بيتخطّى بدل ما يكسر الباقي.
/// [database] اختياري (للاختبار)؛ بدونه بيستخدم [AppDb.instance].
Future<List<PersonalRecord>> computePersonalRecords({Database? database}) async {
  final db = database ?? await AppDb.instance;
  final out = <PersonalRecord>[];

  Future<void> guard(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {/* بند واحد فشل ما يوقفش الباقي */}
  }

  // 👟 أكتر خطوات في يوم (SQLite بيرجّع صف الـMAX فالـday بتاعه)
  await guard(() async {
    final r =
        await db.rawQuery('SELECT day, MAX(steps) m FROM steps_logs WHERE steps > 0');
    final m = r.isNotEmpty ? r.first['m'] as int? : null;
    if (m != null && m > 0) {
      out.add(PersonalRecord('👟', tr('أكتر خطوات في يوم', 'Most steps in a day'),
          '${arNum(m)} ${tr('خطوة', 'steps')}', _onDay(r.first['day'] as String?)));
    }
  });

  // 💧 أكتر مياه في يوم
  await guard(() async {
    final r = await db
        .rawQuery('SELECT day, MAX(glasses) m FROM water_logs WHERE glasses > 0');
    final m = r.isNotEmpty ? r.first['m'] as int? : null;
    if (m != null && m > 0) {
      out.add(PersonalRecord('💧', tr('أكتر مياه في يوم', 'Most water in a day'),
          '${arNum(m)} ${tr('كوب', 'glasses')}', _onDay(r.first['day'] as String?)));
    }
  });

  // 💰 أعلى دخل في شهر
  await guard(() async {
    final r = await db.rawQuery(
        'SELECT substr(day,1,7) mo, SUM(amount) t FROM income '
        'GROUP BY mo ORDER BY t DESC LIMIT 1');
    if (r.isNotEmpty) {
      final t = (r.first['t'] as num?)?.round() ?? 0;
      if (t > 0) {
        out.add(PersonalRecord('💰', tr('أعلى دخل في شهر', 'Highest income month'),
            '${arNum(t)} ${tr('ج', 'EGP')}', _inMonth(r.first['mo'] as String?)));
      }
    }
  });

  // 💸 أقل صرف في شهر (يحتاج شهرين على الأقل عشان تبقى مقارنة ليها معنى)
  await guard(() async {
    final r = await db.rawQuery(
        'SELECT substr(day,1,7) mo, SUM(amount) t FROM expenses '
        'GROUP BY mo ORDER BY t ASC');
    if (r.length >= 2) {
      final t = (r.first['t'] as num?)?.round() ?? 0;
      out.add(PersonalRecord('💸', tr('أقل صرف في شهر', 'Lowest spend month'),
          '${arNum(t)} ${tr('ج', 'EGP')}', _inMonth(r.first['mo'] as String?)));
    }
  });

  // ⚖️ أخف وزن سجّلته (+ الأتقل كسياق)
  await guard(() async {
    final r = await db.rawQuery(
        'SELECT MIN(weight) lo, MAX(weight) hi FROM body_progress '
        'WHERE weight IS NOT NULL AND weight > 0');
    final lo = r.isNotEmpty ? (r.first['lo'] as num?)?.toDouble() : null;
    final hi = r.isNotEmpty ? (r.first['hi'] as num?)?.toDouble() : null;
    if (lo != null && lo > 0) {
      final sub = (hi != null && hi > lo)
          ? '${tr('الأعلى', 'peak')} ${arNum(hi.toStringAsFixed(1))} ${tr('كجم', 'kg')}'
          : null;
      out.add(PersonalRecord('⚖️', tr('أخف وزن سجّلته', 'Lightest weight logged'),
          '${arNum(lo.toStringAsFixed(1))} ${tr('كجم', 'kg')}', sub));
    }
  });

  // 🔥 أطول سلسلة عادة حالية
  await guard(() async {
    final habits = await HabitsRepo().analytics();
    if (habits.isNotEmpty) {
      final best = habits.reduce((a, b) => b.streak > a.streak ? b : a);
      if (best.streak >= 2) {
        out.add(PersonalRecord(
            '🔥',
            tr('أطول سلسلة عادة حالية', 'Longest current habit streak'),
            '${arNum(best.streak)} ${tr('يوم', 'days')}',
            best.habit.name));
      }
    }
  });

  // 🕌 سلسلة الصلاة الحالية (أيام كاملة متتالية)
  await guard(() async {
    final s = await WorshipRepo().fullDaysStreak();
    if (s > 0) {
      out.add(PersonalRecord('🕌', tr('سلسلة الصلاة الحالية', 'Current prayer streak'),
          '${arNum(s)} ${tr('يوم', 'days')}'));
    }
  });

  return out;
}
