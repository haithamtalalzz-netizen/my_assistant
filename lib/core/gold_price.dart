import 'dart:convert';

import 'package:http/http.dart' as http;

import 'log.dart';

/// جلب سعر الذهب والفضة من البورصة العالمية (مجانى تمامًا، بدون مفتاح):
///   • السعر الفورى (spot) للأونصة بالدولار من gold-api.com (XAU/XAG).
///   • سعر صرف الدولار→جنيه من open.er-api.com.
/// ثم تحويله لجنيه مصرى لكل جرام. كله قراءة فقط ولا يُخزَّن على أى سيرفر.
///
/// ملاحظة: هذا **السعر العالمى الاسترشادى** (قيمة المعدن)، وقد يختلف قليلًا عن
/// سعر جرام الذهب فى السوق المحلى — فالمستخدم يعدّله يدويًا عند اللزوم.

/// جرامات الأونصة الترويسية.
const double kGramsPerTroyOz = 31.1034768;

/// يحوّل سعر الأونصة بالدولار + سعر الصرف إلى جنيه/جرام (عيار 24). نقى للاختبار.
double egpPerGram24(double usdPerOz, double usdToEgp) =>
    usdPerOz * usdToEgp / kGramsPerTroyOz;

/// أسعار لحظية محسوبة بالجنيه/جرام.
class GoldPrices {
  final double gold24EgpPerGram; // عيار 24
  final double silverEgpPerGram;
  final double usdPerOzGold; // للعرض الاسترشادى
  final double usdToEgp;

  const GoldPrices({
    required this.gold24EgpPerGram,
    required this.silverEgpPerGram,
    required this.usdPerOzGold,
    required this.usdToEgp,
  });
}

class GoldPriceService {
  /// يجيب الأسعار الحيّة، أو `null` لو فشلت الشبكة (فيرجع المستخدم للإدخال اليدوى).
  static Future<GoldPrices?> fetch() async {
    try {
      final gold = await _spot('XAU');
      final silver = await _spot('XAG');
      final fx = await _usdToEgp();
      if (gold == null || fx == null) return null;
      return GoldPrices(
        gold24EgpPerGram: egpPerGram24(gold, fx),
        silverEgpPerGram: silver == null ? 0 : egpPerGram24(silver, fx),
        usdPerOzGold: gold,
        usdToEgp: fx,
      );
    } on Exception catch (e) {
      logError('فشل جلب سعر الذهب العالمى', e);
      return null;
    }
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
