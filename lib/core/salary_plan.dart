import 'dart:convert';

/// ظرف واحد من أظرف المرتب — اسم + نسبة مئوية من المرتب.
class SalaryEnvelope {
  final String name;
  final double percent;
  const SalaryEnvelope(this.name, this.percent);

  Map<String, Object?> toMap() => {'name': name, 'percent': percent};
}

/// التوزيع المقترح الافتراضى (يقدر المستخدم يغيّره).
const List<SalaryEnvelope> kDefaultEnvelopes = [
  SalaryEnvelope('التزامات', 40),
  SalaryEnvelope('مصاريف المعيشة', 35),
  SalaryEnvelope('ادخار', 25),
];

/// يقرا الأظرف من JSON مخزّن في الإعدادات — يرجّع الافتراضى لو فاضى/تالف.
List<SalaryEnvelope> parseEnvelopes(String? json) {
  if (json == null || json.trim().isEmpty) return List.of(kDefaultEnvelopes);
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return List.of(kDefaultEnvelopes);
    final out = <SalaryEnvelope>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final name = (e['name'] as String?)?.trim() ?? '';
      final pct = (e['percent'] as num?)?.toDouble() ?? 0;
      if (name.isNotEmpty) out.add(SalaryEnvelope(name, pct));
    }
    return out.isEmpty ? List.of(kDefaultEnvelopes) : out;
  } catch (_) {
    return List.of(kDefaultEnvelopes);
  }
}

String encodeEnvelopes(List<SalaryEnvelope> list) =>
    jsonEncode([for (final e in list) e.toMap()]);

double totalPercent(List<SalaryEnvelope> list) =>
    list.fold(0.0, (s, e) => s + e.percent);

/// توزيع المرتب: لكل ظرف مبلغ = المرتب × نسبته ÷ ١٠٠.
List<MapEntry<SalaryEnvelope, double>> distribute(
        double salary, List<SalaryEnvelope> list) =>
    [for (final e in list) MapEntry(e, salary * e.percent / 100)];

/// كام يوم فاضل على القبض (يوم [payday] من الشهر). النهاردة القبض = 0.
/// بيراعى الشهور القصيرة (لو payday=31 وفبراير → آخر يوم في الشهر).
int daysUntilPayday(int payday, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  int clampDay(int y, int m) => payday.clamp(1, DateTime(y, m + 1, 0).day);

  var target = DateTime(t.year, t.month, clampDay(t.year, t.month));
  if (target.isBefore(t)) {
    final ny = t.month == 12 ? t.year + 1 : t.year;
    final nm = t.month == 12 ? 1 : t.month + 1;
    target = DateTime(ny, nm, clampDay(ny, nm));
  }
  return target.difference(t).inDays;
}
