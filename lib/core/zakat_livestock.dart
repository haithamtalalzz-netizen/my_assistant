// زكاة الزروع والثمار + زكاة الأنعام (الغنم/البقر/الإبل) — منطق نقى قابل
// للاختبار، بالجداول الفقهية المشهورة (قول الجمهور).
//
// • الزروع والثمار: نصاب ٥ أوسق ≈ ٦٥٣ كجم؛ العُشر (١٠٪) لِما سُقى بلا كلفة،
//   ونصف العُشر (٥٪) لِما سُقى بكلفة. لا يُشترط حول (تجب عند الحصاد).
// • الأنعام: تُشترط السَّوم (الرعى) وحولان الحول. الواجب يُخرَج «عينًا» (حيوانًا)،
//   ويجوز إخراج قيمته عند بعض الفقهاء.

/// نصاب الزروع والثمار بالكيلوجرام (٥ أوسق).
const double kCropNisabKg = 653;

class CropZakatResult {
  final bool isDue;
  final double rate; // ٠.١٠ أو ٠.٠٥
  final double zakatKg;
  const CropZakatResult({
    required this.isDue,
    required this.rate,
    required this.zakatKg,
  });
}

/// زكاة محصول وزنه [weightKg]. [irrigatedWithCost] = سُقى بمشقّة/تكلفة (بئر/آلة).
CropZakatResult cropZakat(double weightKg, {required bool irrigatedWithCost}) {
  final rate = irrigatedWithCost ? 0.05 : 0.10;
  final isDue = weightKg >= kCropNisabKg;
  return CropZakatResult(
    isDue: isDue,
    rate: rate,
    zakatKg: isDue ? weightKg * rate : 0,
  );
}

/// بند واجب من الأنعام (عدد + نوع الحيوان).
class ZakatDueItem {
  final int count;
  final String label;
  const ZakatDueItem(this.count, this.label);
}

/// أنواع الأنعام.
enum Livestock { sheep, cattle, camel }

/// زكاة الغنم (سائمة، حال عليها الحول). فارغة = دون النصاب (٤٠).
List<ZakatDueItem> sheepZakat(int n) {
  if (n < 40) return const [];
  if (n <= 120) return const [ZakatDueItem(1, 'شاة')];
  if (n <= 200) return const [ZakatDueItem(2, 'شاة')];
  if (n <= 399) return const [ZakatDueItem(3, 'شاة')];
  return [ZakatDueItem(n ~/ 100, 'شاة')]; // ٤٠٠ فأكثر: شاة لكل مائة
}

/// زكاة البقر. النصاب ٣٠: تبيع (سنة) لكل ٣٠، ومسنّة (سنتان) لكل ٤٠.
List<ZakatDueItem> cattleZakat(int n) {
  if (n < 30) return const [];
  if (n < 40) return const [ZakatDueItem(1, 'تبيع')];
  if (n < 60) return const [ZakatDueItem(1, 'مسنّة')];
  // نغطّى العدد بتوليفة ٣٠(تبيع)+٤٠(مسنّة) بأقل «وقص» (باقٍ < ٣٠)،
  // ونفضّل عند التساوى أكثر مسنّة (أعلى قيمة).
  int bt = 0, bm = 0, bestCov = -1;
  for (int m = 0; m <= n ~/ 40; m++) {
    final t = (n - 40 * m) ~/ 30;
    final cov = 40 * m + 30 * t;
    if (cov > bestCov || (cov == bestCov && m > bm)) {
      bestCov = cov;
      bm = m;
      bt = t;
    }
  }
  return [
    if (bm > 0) ZakatDueItem(bm, 'مسنّة'),
    if (bt > 0) ZakatDueItem(bt, 'تبيع'),
  ];
}

/// زكاة الإبل. جدول ثابت حتى ١٢٠، ثم بنت لبون لكل ٤٠ وحِقّة لكل ٥٠.
List<ZakatDueItem> camelZakat(int n) {
  if (n < 5) return const [];
  if (n < 25) return [ZakatDueItem(n ~/ 5, 'شاة')]; // ٥→١ شاة .. ٢٠→٤ شياه
  if (n < 36) return const [ZakatDueItem(1, 'بنت مخاض')];
  if (n < 46) return const [ZakatDueItem(1, 'بنت لبون')];
  if (n < 61) return const [ZakatDueItem(1, 'حِقّة')];
  if (n < 76) return const [ZakatDueItem(1, 'جَذَعة')];
  if (n < 91) return const [ZakatDueItem(2, 'بنت لبون')];
  if (n <= 120) return const [ZakatDueItem(2, 'حِقّة')];
  // ١٢١ فأكثر: نغطّى بتوليفة ٤٠(بنت لبون)+٥٠(حِقّة) بأقل وقص، ونفضّل أكثر حِقّة.
  int bl = 0, bh = 0, bestCov = -1;
  for (int h = 0; h <= n ~/ 50; h++) {
    final l = (n - 50 * h) ~/ 40;
    final cov = 50 * h + 40 * l;
    if (cov > bestCov || (cov == bestCov && h > bh)) {
      bestCov = cov;
      bh = h;
      bl = l;
    }
  }
  return [
    if (bh > 0) ZakatDueItem(bh, 'حِقّة'),
    if (bl > 0) ZakatDueItem(bl, 'بنت لبون'),
  ];
}

/// موزّع حسب النوع.
List<ZakatDueItem> livestockZakat(Livestock kind, int n) => switch (kind) {
      Livestock.sheep => sheepZakat(n),
      Livestock.cattle => cattleZakat(n),
      Livestock.camel => camelZakat(n),
    };

/// أدنى نصاب لكل نوع (لعرض «دون النصاب»).
int livestockNisab(Livestock kind) => switch (kind) {
      Livestock.sheep => 40,
      Livestock.cattle => 30,
      Livestock.camel => 5,
    };
