// منطق حسابات الزكاة — نقى وقابل للاختبار (منفصل عن الواجهة).
//
// نصاب الذهب 85 جم (عيار 24)، والفضة 595 جم، والمقدار 2.5% (ربع العُشر)
// من صافى المال الزكوى إذا بلغ النصاب وحال عليه الحول (سنة هجرية).

/// نصاب الذهب بالجرام (عيار 24).
const double kGoldNisabGrams = 85;

/// نصاب الفضة بالجرام.
const double kSilverNisabGrams = 595;

/// مقدار الزكاة = ربع العُشر.
const double kZakatRate = 0.025;

/// العيارات الشائعة. نقاء الذهب = العيار ÷ 24.
const List<int> kGoldKarats = [24, 22, 21, 18, 14, 12, 9];

/// نسبة النقاء لعيار معيّن (عيار 24 = 1.0، عيار 21 = 0.875 …).
double karatPurity(int karat) => karat / 24.0;

/// أساس احتساب النصاب — بالذهب (الأعلى) أو بالفضة (الأقل، أنفع للفقير).
enum NisabBasis { gold, silver }

/// قطعة ذهب: وزن + عيار + سعر جرام اختيارى.
///
/// لو [pricePerGram] غير محدَّد، تُشتقّ قيمة القطعة من سعر جرام عيار 24
/// مضروبًا فى نسبة النقاء — فيكفى المستخدم إدخال سعر عيار 24 مرّة واحدة.
class GoldHolding {
  final double grams;
  final int karat;
  final double? pricePerGram;

  const GoldHolding({
    required this.grams,
    this.karat = 24,
    this.pricePerGram,
  });

  /// جرامات الذهب الخالص المكافئة (عيار 24) — تُستخدم للنصاب الوزنى.
  double get pureGrams => grams * karatPurity(karat);

  /// قيمة القطعة بالجنيه حسب سعر جرام عيار 24 (أو السعر المُدخل لو وُجد).
  double value(double gold24PricePerGram) {
    final p = pricePerGram ?? (gold24PricePerGram * karatPurity(karat));
    return grams * p;
  }
}

/// كل مدخلات حاسبة الزكاة.
class ZakatInput {
  final double cash; // نقود: كاش + أرصدة بنكية
  final List<GoldHolding> gold; // قطع الذهب
  final double gold24Price; // سعر جرام عيار 24 (للنصاب وتقييم الذهب)
  final double silverGrams; // وزن الفضة بالجرام
  final double silverPricePerGram; // سعر جرام الفضة
  final double trade; // عروض التجارة (قيمة سوقية)
  final double investments; // أسهم واستثمارات للمتاجرة
  final double receivables; // ديون مرجوّة لك (يغلب رجوعها)
  final double debts; // ديون/مصروفات مستحقة عليك الآن
  final NisabBasis nisabBasis;

  const ZakatInput({
    this.cash = 0,
    this.gold = const [],
    this.gold24Price = 0,
    this.silverGrams = 0,
    this.silverPricePerGram = 0,
    this.trade = 0,
    this.investments = 0,
    this.receivables = 0,
    this.debts = 0,
    this.nisabBasis = NisabBasis.gold,
  });
}

/// نتيجة الحساب.
class ZakatResult {
  final double goldValue; // إجمالى قيمة الذهب
  final double pureGoldGrams; // إجمالى الذهب الخالص المكافئ
  final double silverValue; // قيمة الفضة
  final double totalAssets; // مجموع الأصول قبل خصم الديون
  final double deductibles; // الديون المخصومة
  final double zakatable; // صافى المال الزكوى
  final double nisabValue; // قيمة النصاب بالجنيه
  final bool isDue; // بلغ النصاب؟
  final double zakatDue; // المبلغ المستحق

  const ZakatResult({
    required this.goldValue,
    required this.pureGoldGrams,
    required this.silverValue,
    required this.totalAssets,
    required this.deductibles,
    required this.zakatable,
    required this.nisabValue,
    required this.isDue,
    required this.zakatDue,
  });
}

/// يحسب الزكاة من [i].
ZakatResult computeZakat(ZakatInput i) {
  final goldValue =
      i.gold.fold<double>(0, (s, g) => s + g.value(i.gold24Price));
  final pureGold = i.gold.fold<double>(0, (s, g) => s + g.pureGrams);
  final silverValue = i.silverGrams * i.silverPricePerGram;

  final totalAssets =
      i.cash + goldValue + silverValue + i.trade + i.investments + i.receivables;
  final zakatable = totalAssets - i.debts;

  final nisabValue = i.nisabBasis == NisabBasis.gold
      ? i.gold24Price * kGoldNisabGrams
      : i.silverPricePerGram * kSilverNisabGrams;

  final isDue = nisabValue > 0 && zakatable >= nisabValue;
  final zakatDue = isDue ? zakatable * kZakatRate : 0.0;

  return ZakatResult(
    goldValue: goldValue,
    pureGoldGrams: pureGold,
    silverValue: silverValue,
    totalAssets: totalAssets,
    deductibles: i.debts,
    zakatable: zakatable,
    nisabValue: nisabValue,
    isDue: isDue,
    zakatDue: zakatDue,
  );
}
