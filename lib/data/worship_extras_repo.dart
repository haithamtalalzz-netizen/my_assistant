import 'dart:convert';

import '../core/ar.dart';
import 'settings_repo.dart';

/// صدقة مسجّلة.
class SadaqahEntry {
  final String day; // yyyy-MM-dd
  final double amount;
  final String note;
  const SadaqahEntry(this.day, this.amount, this.note);

  Map<String, Object?> toJson() => {'d': day, 'a': amount, 'n': note};

  factory SadaqahEntry.fromJson(Map<String, dynamic> m) => SadaqahEntry(
        m['d'] as String? ?? '',
        (m['a'] as num?)?.toDouble() ?? 0,
        m['n'] as String? ?? '',
      );
}

/// قيام الليل + الصدقات — مخزّنة كـJSON فى الإعدادات (بلا هجرة قاعدة بيانات).
class WorshipExtrasRepo {
  final _s = SettingsRepo();

  static const _kQiyam = 'qiyam_days'; // قائمة أيام
  static const _kSadaqah = 'sadaqah_log'; // قائمة صدقات
  static const _kSadaqahGoal = 'sadaqah_monthly_goal';

  // ---- قيام الليل ----

  Future<Set<String>> qiyamDays() async {
    final raw = await _s.get(_kQiyam) ?? '';
    if (raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toSet();
    } on FormatException {
      return {};
    }
  }

  Future<bool> qiyamOn(DateTime day) async =>
      (await qiyamDays()).contains(dayKey(day));

  Future<void> setQiyam(DateTime day, bool done) async {
    final days = await qiyamDays();
    final k = dayKey(day);
    done ? days.add(k) : days.remove(k);
    // نحتفظ بآخر ٤٠٠ يوم بس.
    final list = days.toList()..sort();
    final trimmed = list.length > 400 ? list.sublist(list.length - 400) : list;
    await _s.set(_kQiyam, jsonEncode(trimmed));
  }

  /// أيام القيام المتتالية المنتهية عند اليوم (أو أمس لو النهاردة لسه).
  Future<int> qiyamStreak() async {
    final days = await qiyamDays();
    var streak = 0;
    var d = dateOnly(DateTime.now());
    if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    while (days.contains(dayKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<int> qiyamCountLast(int n) async {
    final days = await qiyamDays();
    final from = dateOnly(DateTime.now()).subtract(Duration(days: n - 1));
    return days.where((k) {
      final d = DateTime.tryParse(k);
      return d != null && !d.isBefore(from);
    }).length;
  }

  // ---- الصدقات ----

  Future<List<SadaqahEntry>> sadaqat() async {
    final raw = await _s.get(_kSadaqah) ?? '';
    if (raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SadaqahEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.day.compareTo(a.day));
    } on FormatException {
      return [];
    }
  }

  Future<void> addSadaqah(double amount, String note, {DateTime? at}) async {
    if (amount <= 0) return;
    final list = await sadaqat();
    list.insert(
        0, SadaqahEntry(dayKey(at ?? DateTime.now()), amount, note.trim()));
    final trimmed = list.length > 300 ? list.sublist(0, 300) : list;
    await _s.set(_kSadaqah, jsonEncode([for (final e in trimmed) e.toJson()]));
  }

  Future<void> removeSadaqahAt(int index) async {
    final list = await sadaqat();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _s.set(_kSadaqah, jsonEncode([for (final e in list) e.toJson()]));
  }

  /// إجمالى صدقات شهر معيّن (الحالى افتراضيًّا).
  Future<double> sadaqahThisMonth([DateTime? at]) async {
    final now = at ?? DateTime.now();
    final prefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final list = await sadaqat();
    return list
        .where((e) => e.day.startsWith(prefix))
        .fold<double>(0, (s, e) => s + e.amount);
  }

  Future<double> sadaqahGoal() async =>
      double.tryParse(await _s.get(_kSadaqahGoal) ?? '') ?? 0;

  Future<void> setSadaqahGoal(double v) async =>
      _s.set(_kSadaqahGoal, v.toString());

  /// هل فيه صدقة اتسجّلت النهاردة؟ (لبند «صدقة» فى برنامج اليوم)
  Future<bool> sadaqahToday() async {
    final k = dayKey(DateTime.now());
    return (await sadaqat()).any((e) => e.day == k);
  }
}
