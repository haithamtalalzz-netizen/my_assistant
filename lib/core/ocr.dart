import 'ar.dart';
// النسخة الأصلية (ML Kit) على الموبايل/سطح المكتب، و stub على الويب —
// عشان حزمة mlkit مش بتتبني للويب.
import 'ocr_recognizer_stub.dart'
    if (dart.library.io) 'ocr_recognizer_native.dart' as recognizer;

/// قراءة نصوص من الصور على الجهاز (ML Kit — مجاني).
/// ملحوظة مهمة: بيقرا الأرقام واللاتيني كويس، لكن مش بيدعم النص العربي —
/// فبنستخدمه لاستخراج المبالغ والتواريخ بس.
class OcrService {
  static Future<String?> recognizeFromPath(String path) =>
      recognizer.recognizeFromPath(path);
}

/// يستخرج إجمالي الفاتورة من نص الـ OCR — دالة نقية قابلة للاختبار.
double? extractReceiptTotal(String rawText) {
  final text = toEnglishDigits(rawText);
  final lines = text.split('\n');
  // «cash» و«amount» متشالين عمدًا — المدفوع كاش غالبًا أكبر من الإجمالي.
  const keywords = [
    'total', 'net', 'grand',
    'الإجمالي', 'اجمالي', 'الاجمالي', 'إجمالي', 'الصافي', 'صافي', 'المطلوب',
  ];

  List<double> numbersIn(String line) {
    final result = <double>[];
    // 1,234.56 → شيل فواصل الآلاف الأول.
    final cleaned = line.replaceAllMapped(
        RegExp(r'(\d),(\d{3})'), (m) => '${m[1]}${m[2]}');
    for (final m in RegExp(r'\d+(?:[.,]\d{1,2})?').allMatches(cleaned)) {
      final v = double.tryParse(m[0]!.replaceAll(',', '.'));
      if (v != null && v > 0 && v < 1000000) result.add(v);
    }
    return result;
  }

  // أولوية للسطور اللي فيها كلمة إجمالي.
  final keywordNumbers = <double>[];
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (keywords.any(lower.contains)) {
      keywordNumbers.addAll(numbersIn(line));
    }
  }
  if (keywordNumbers.isNotEmpty) {
    return keywordNumbers.reduce((a, b) => a > b ? a : b);
  }

  // من غير كلمة مفتاحية: أكبر رقم منطقي في الفاتورة كلها.
  final all = <double>[];
  for (final line in lines) {
    all.addAll(numbersIn(line));
  }
  if (all.isEmpty) return null;
  final max = all.reduce((a, b) => a > b ? a : b);
  return max >= 1 ? max : null;
}

/// يستخرج التواريخ من نص OCR — dd/mm/yyyy وأشكاله + yyyy-mm-dd.
List<DateTime> extractDates(String rawText) {
  final text = toEnglishDigits(rawText);
  final results = <DateTime>[];
  for (final m in RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})')
      .allMatches(text)) {
    final d = int.parse(m[1]!);
    final mo = int.parse(m[2]!);
    var y = int.parse(m[3]!);
    if (y < 100) y += 2000;
    if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12 && y >= 2000 && y <= 2060) {
      final date = DateTime(y, mo, d);
      if (date.month == mo && date.day == d) results.add(date);
    }
  }
  for (final m
      in RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').allMatches(text)) {
    final y = int.parse(m[1]!);
    final mo = int.parse(m[2]!);
    final d = int.parse(m[3]!);
    if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12 && y >= 2000 && y <= 2060) {
      final date = DateTime(y, mo, d);
      if (date.month == mo && date.day == d) results.add(date);
    }
  }
  return results;
}

/// أنسب تاريخ انتهاء مقترح: أبعد تاريخ مستقبلي معقول (لحد ٢٠ سنة).
DateTime? bestExpiryDate(String rawText, DateTime now) {
  final dates = extractDates(rawText);
  DateTime? best;
  for (final d in dates) {
    if (d.isAfter(now) &&
        d.isBefore(now.add(const Duration(days: 365 * 20)))) {
      if (best == null || d.isAfter(best)) best = d;
    }
  }
  return best;
}

/// اللى اتقرا من صورة مستند — أى حقل ممكن يكون null لو ماتلاقاش.
class DocScan {
  final String? number;
  final String? issuer;
  final DateTime? issued;
  final DateTime? expiry;

  const DocScan({this.number, this.issuer, this.issued, this.expiry});

  bool get isEmpty =>
      number == null && issuer == null && issued == null && expiry == null;
}

/// كلمات بتدل على رقم المستند (عربى وإنجليزى).
const List<String> _kNumberHints = [
  'رقم', 'الرقم', 'رقم قومى', 'الرقم القومى', 'no', 'no.', 'number',
  'id', 'serial', 'passport',
];

/// كلمات بتدل على جهة الإصدار.
const List<String> _kIssuerHints = [
  'جهة', 'الجهة', 'اصدار', 'إصدار', 'صادر', 'وزارة', 'مصلحة', 'هيئة', 'إدارة',
  'issued by', 'authority', 'ministry',
];

/// بيستخرج بيانات المستند من نص الـOCR — **دالة نقية** عشان تتّست من غير
/// كاميرا ولا جهاز.
///
/// المنطق متحفّظ عن قصد: بيرجّع حاجة **لما يبقى واثق** بس؛ اقتراح غلط
/// بيتكتب فى خانة أسوأ من مفيش اقتراح (المستخدم ممكن مايراجعوش).
DocScan scanDocument(String rawText, DateTime now) {
  final lines = rawText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String? number;
  String? issuer;

  bool hasHint(String lower, List<String> hints) =>
      hints.any((h) => lower.contains(h));

  for (final line in lines) {
    final lower = line.toLowerCase();
    // ----- رقم المستند -----
    if (number == null && hasHint(lower, _kNumberHints)) {
      final digits = toEnglishDigits(line);
      // أطول سلسلة أرقام فى السطر (≥٦ أرقام) = الرقم غالبًا.
      String? best;
      for (final m in RegExp(r'\d[\d\s/-]{5,}').allMatches(digits)) {
        final cleaned = m[0]!.replaceAll(RegExp(r'\s'), '');
        if (best == null || cleaned.length > best.length) best = cleaned;
      }
      if (best != null && best.replaceAll(RegExp(r'\D'), '').length >= 6) {
        number = best;
      }
    }
    // ----- جهة الإصدار -----
    if (issuer == null && hasHint(lower, _kIssuerHints)) {
      // شيل الكلمة الدالة نفسها وخد الباقى لو فيه كلام معقول.
      var rest = line;
      for (final h in _kIssuerHints) {
        rest = rest.replaceAll(RegExp(h, caseSensitive: false), '');
      }
      rest = rest.replaceAll(RegExp(r'[:：\-]'), ' ');
      // «الإصدار» ناقص «إصدار» بيسيب «ال» — بقايا زى دى مش اسم جهة.
      rest = rest
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty && w != 'ال' && w != 'the')
          .join(' ')
          .trim();
      // لازم يبقى فيه حروف حقيقية (٣ على الأقل) — سطر أرقام أو بقايا
      // كلمة مش جهة إصدار.
      final letters = rest.replaceAll(RegExp(r'[\d\s/\-.,]'), '');
      if (letters.length >= 3) issuer = rest;
    }
  }

  // ----- التواريخ: الماضى = إصدار، المستقبل = انتهاء -----
  final dates = extractDates(rawText);
  DateTime? issued;
  DateTime? expiry;
  for (final d in dates) {
    if (d.isAfter(now)) {
      if (d.isBefore(now.add(const Duration(days: 365 * 20))) &&
          (expiry == null || d.isAfter(expiry))) {
        expiry = d;
      }
    } else {
      if (d.isAfter(now.subtract(const Duration(days: 365 * 30))) &&
          (issued == null || d.isAfter(issued))) {
        issued = d;
      }
    }
  }

  return DocScan(
      number: number, issuer: issuer, issued: issued, expiry: expiry);
}
