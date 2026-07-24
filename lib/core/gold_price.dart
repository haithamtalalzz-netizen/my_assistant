import 'dart:convert';

import 'package:http/http.dart' as http;

import 'log.dart';

/// جلب سعر الذهب والفضة من البورصة العالمية (مجانى تمامًا، بدون مفتاح).
///
/// مصدران للموثوقية عبر الشبكات والمنصّات المختلفة:
///   1) **Yahoo Finance** (`GC=F` ذهب، `SI=F` فضة، `USDEGP=X` صرف) — يوصله
///      أغلب مزوّدى الإنترنت ويسمح لعملاء غير المتصفح، فيشتغل على الأندرويد.
///   2) احتياطى: **gold-api.com** + **open.er-api.com** — بترويسة CORS مفتوحة
///      فيشتغل على الويب لو الأول محجوب.
/// كله قراءة فقط ولا يُخزَّن على أى سيرفر. ملاحظة: **سعر عالمى استرشادى**
/// (قيمة المعدن)، قد يختلف قليلًا عن السوق المحلى — فالمستخدم يعدّله عند اللزوم.

/// جرامات الأونصة الترويسية.
const double kGramsPerTroyOz = 31.1034768;

/// يحوّل سعر الأونصة بالدولار + سعر الصرف إلى جنيه/جرام (عيار 24). نقى للاختبار.
double egpPerGram24(double usdPerOz, double usdToEgp) =>
    usdPerOz * usdToEgp / kGramsPerTroyOz;

/// أسعار لحظية محسوبة بالجنيه/جرام.
class GoldPrices {
  final double gold24EgpPerGram; // عيار 24
  final double silverEgpPerGram;
  final double goldOzEgp; // سعر أونصة الذهب بالجنيه (للعرض)

  const GoldPrices({
    required this.gold24EgpPerGram,
    required this.silverEgpPerGram,
    required this.goldOzEgp,
  });
}

/// نتيجة الجلب: إما أسعار، أو سبب فشل مختصر (للعرض والتشخيص).
class GoldFetchResult {
  final GoldPrices? prices;
  final String? diag;
  const GoldFetchResult(this.prices, this.diag);
}

class GoldPriceService {
  /// يجرّب المصادر بالترتيب، ويرجّع أول نجاح، أو سبب فشل مجمّع.
  static Future<GoldFetchResult> fetch() async {
    final a = await _tryYahoo();
    if (a.prices != null) return a;
    final b = await _tryGoldApi();
    if (b.prices != null) return b;
    return GoldFetchResult(null, '${a.diag ?? '?'} · ${b.diag ?? '?'}');
  }

  /// المصدر الأساسى: Yahoo Finance (بالدولار) + سعر الصرف.
  static Future<GoldFetchResult> _tryYahoo() async {
    try {
      final goldUsd = await _yahoo('GC=F');
      final fx = await _yahoo('USDEGP=X');
      final silverUsd = await _yahoo('SI=F');
      if (goldUsd == null) return const GoldFetchResult(null, 'yh:gold');
      if (fx == null) return const GoldFetchResult(null, 'yh:fx');
      return GoldFetchResult(
        GoldPrices(
          gold24EgpPerGram: egpPerGram24(goldUsd, fx),
          silverEgpPerGram: silverUsd == null ? 0 : egpPerGram24(silverUsd, fx),
          goldOzEgp: goldUsd * fx,
        ),
        null,
      );
    } on Exception catch (e) {
      logError('فشل جلب السعر من Yahoo', e);
      return GoldFetchResult(null, 'yh:${_short(e)}');
    }
  }

  /// الاحتياطى: gold-api.com (بالدولار) + سعر الصرف.
  static Future<GoldFetchResult> _tryGoldApi() async {
    try {
      final gold = await _spot('XAU');
      final silver = await _spot('XAG');
      final fx = await _usdToEgp();
      if (gold == null) return const GoldFetchResult(null, 'ga:gold');
      if (fx == null) return const GoldFetchResult(null, 'ga:fx');
      return GoldFetchResult(
        GoldPrices(
          gold24EgpPerGram: egpPerGram24(gold, fx),
          silverEgpPerGram: silver == null ? 0 : egpPerGram24(silver, fx),
          goldOzEgp: gold * fx,
        ),
        null,
      );
    } on Exception catch (e) {
      logError('فشل جلب سعر الذهب الاحتياطى', e);
      return GoldFetchResult(null, 'ga:${_short(e)}');
    }
  }

  static String _short(Object e) {
    final s = e.runtimeType.toString();
    return s.length > 24 ? s.substring(0, 24) : s;
  }

  /// سعر رمز من Yahoo (regularMarketPrice).
  static Future<double?> _yahoo(String symbol) async {
    final uri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/'
        '$symbol?interval=1d&range=1d');
    final res = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
    }).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final chart = j['chart'];
    final result = chart is Map ? chart['result'] : null;
    if (result is! List || result.isEmpty) return null;
    final meta = (result.first as Map)['meta'];
    final p = meta is Map ? meta['regularMarketPrice'] : null;
    return p is num ? p.toDouble() : null;
  }

  static Future<double?> _spot(String symbol) async {
    final uri = Uri.parse('https://api.gold-api.com/price/$symbol');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final p = j['price'];
    return p is num ? p.toDouble() : null;
  }

  static Future<double?> _usdToEgp() async {
    final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = j['rates'];
    if (rates is Map && rates['EGP'] is num) {
      return (rates['EGP'] as num).toDouble();
    }
    return null;
  }
}
