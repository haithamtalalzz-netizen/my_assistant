import 'dart:math';

// أدوات كلمات السر — كلها على الجهاز: توليد كلمة قوية، تقييم القوة، وتدقيق
// أوفلاين يكشف الضعيف والمكرَّر. مفيش أى إرسال لأى سيرفر.

const String _lower = 'abcdefghijkmnpqrstuvwxyz'; // بلا l/o للّبس
const String _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // بلا I/O
const String _digits = '23456789'; // بلا 0/1
const String _symbols = '!@#\$%^&*-_=+?';

/// يولّد كلمة سر قوية بطول [length] تضمن حرف صغير وكبير ورقم (ورمز اختياريًا).
String generatePassword({int length = 16, bool symbols = true}) {
  final rnd = Random.secure();
  final pools = <String>[_lower, _upper, _digits, if (symbols) _symbols];
  final all = pools.join();
  final chars = <String>[
    // حرف مضمون من كل مجموعة أولًا.
    for (final p in pools) p[rnd.nextInt(p.length)],
    // ثم كمّل الباقى عشوائيًا.
    for (var i = pools.length; i < length; i++) all[rnd.nextInt(all.length)],
  ];
  // خلط Fisher-Yates عشان الحروف المضمونة ماتفضلش فى الأول.
  for (var i = chars.length - 1; i > 0; i--) {
    final j = rnd.nextInt(i + 1);
    final t = chars[i];
    chars[i] = chars[j];
    chars[j] = t;
  }
  return chars.join();
}

/// درجة قوة 0..6 حسب الطول وتنوّع الأصناف.
int passwordScore(String pw) {
  var s = 0;
  if (pw.length >= 8) s++;
  if (pw.length >= 12) s++;
  if (RegExp(r'[a-z]').hasMatch(pw)) s++;
  if (RegExp(r'[A-Z]').hasMatch(pw)) s++;
  if (RegExp(r'[0-9]').hasMatch(pw)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) s++;
  return s;
}

/// مستوى القوة: ضعيف (≤2) / متوسط (3–4) / قوى (≥5).
enum PwLevel { weak, fair, strong }

PwLevel passwordLevel(String pw) {
  final s = passwordScore(pw);
  if (s <= 2) return PwLevel.weak;
  if (s <= 4) return PwLevel.fair;
  return PwLevel.strong;
}

/// نتيجة تدقيق مجموعة كلمات سر.
class PasswordAudit {
  /// معرّفات الإدخالات ذات السر الضعيف.
  final Set<int> weakIds;

  /// مجموعات المعرّفات اللى بتتشارك نفس السر (كل مجموعة فيها ≥2).
  final List<List<int>> reusedGroups;

  const PasswordAudit(this.weakIds, this.reusedGroups);

  int get reusedCount =>
      reusedGroups.fold<int>(0, (s, g) => s + g.length);
  bool get isClean => weakIds.isEmpty && reusedGroups.isEmpty;
}

/// يدقّق خريطة (معرّف → السر). يكشف الضعيف والمكرَّر. نقى بالكامل.
PasswordAudit auditPasswords(Map<int, String> secrets) {
  final weak = <int>{};
  final byValue = <String, List<int>>{};
  secrets.forEach((id, pw) {
    if (pw.isEmpty) return;
    if (passwordLevel(pw) == PwLevel.weak) weak.add(id);
    byValue.putIfAbsent(pw, () => []).add(id);
  });
  final reused = [
    for (final e in byValue.entries)
      if (e.value.length >= 2) e.value,
  ];
  return PasswordAudit(weak, reused);
}
