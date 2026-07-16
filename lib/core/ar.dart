import 'package:intl/intl.dart';

import 'app_state.dart';

/// أرقام العرض: إنجليزية (لاتينية) في كل اللغات — قرار تصميم 2026-07-09.
/// (مفاتيح الـ DB بتستخدم dayKey مباشرةً فمابتتأثرش.)
String arNum(Object value) => value.toString();

/// يحوّل أي أرقام شرقية في نص لإنجليزية (للتواريخ اللي بيطلعها intl بالعربي).
String _west(String s) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return s.replaceAllMapped(RegExp(r'[٠-٩]'),
      (m) => eastern.indexOf(m[0]!).toString());
}

/// لغة عرض التواريخ حسب اللغة الحالية.
String _dl() => AppState.isEnglish ? 'en' : 'ar';

/// يطبع الأرقام العربية الشرقية والفارسية لأرقام إنجليزية قبل أي parse.
String toEnglishDigits(String input) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buf = StringBuffer();
  for (final ch in input.split('')) {
    final e = eastern.indexOf(ch);
    final p = persian.indexOf(ch);
    if (e >= 0) {
      buf.write(e);
    } else if (p >= 0) {
      buf.write(p);
    } else if (ch == '،' || ch == ',') {
      buf.write('.');
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

double? parseNumber(String input) => double.tryParse(toEnglishDigits(input.trim()));

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// مفتاح اليوم بصيغة YYYY-MM-DD — يستخدم في كل جداول السجلات اليومية.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String arFullDate(DateTime d) =>
    _west(DateFormat('EEEE d MMMM y', _dl()).format(d));
String arShortDate(DateTime d) => _west(DateFormat('d MMM y', _dl()).format(d));
String arMonth(DateTime d) => _west(DateFormat('MMMM y', _dl()).format(d));
String arMonthShort(DateTime d) => _west(DateFormat('MMM', _dl()).format(d));
String arTime(DateTime d) => _west(DateFormat('h:mm a', _dl()).format(d));
String arDateTime(DateTime d) => '${arShortDate(d)} · ${arTime(d)}';

/// وقت جرعة مخزن كـ HH:mm.
String arTimeOfSlot(String hhmm) {
  final parts = hhmm.split(':');
  return arTime(DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1])));
}

String greetingFor(DateTime now) {
  final morning = now.hour >= 4 && now.hour < 12;
  if (AppState.isEnglish) return morning ? 'Good morning' : 'Good evening';
  return morning ? 'صباح الخير' : 'مساء الخير';
}

String egp(num v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  return AppState.isEnglish ? '${arNum(s)} EGP' : '${arNum(s)} ج.م';
}
