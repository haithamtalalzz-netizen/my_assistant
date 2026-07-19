import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/settings_repo.dart';
import 'ar.dart';
import 'log.dart';

/// يفكّ رد Frankfurter → سعر الجنيه مقابل الدولار (كام جنيه فى الدولار).
/// خالص/متغطّى بتست. بيرجّع null لو الرد تالف أو مفيهوش EGP.
double? parseUsdEgp(String body) {
  try {
    final j = jsonDecode(body);
    if (j is Map && j['rates'] is Map && j['rates']['EGP'] != null) {
      final v = (j['rates']['EGP'] as num).toDouble();
      return v > 0 ? v : null;
    }
  } catch (_) {/* رد تالف */}
  return null;
}

/// سعر الدولار مقابل الجنيه عبر Frankfurter — **API مجانى بدون مفتاح** (زى الطقس).
/// بيتكاش مرة فى اليوم عشان مانستهلكش الشبكة، وبيرجع للمكاش لو النت وقع.
class FxRate {
  static const _valueKey = 'fx_usd_egp';
  static const _dateKey = 'fx_usd_egp_date';

  static Future<double?> cached() async {
    final v = await SettingsRepo().get(_valueKey);
    return v == null ? null : double.tryParse(v);
  }

  static Future<String?> cachedDate() => SettingsRepo().get(_dateKey);

  /// يجيب أحدث سعر (أو المكاش لو اتجاب النهاردة أو النت وقع).
  static Future<double?> latest({http.Client? client}) async {
    final s = SettingsRepo();
    final today = dayKey(DateTime.now());
    if (await s.get(_dateKey) == today) return cached();

    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('https://api.frankfurter.app/latest?from=USD&to=EGP'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final rate = parseUsdEgp(res.body);
        if (rate != null) {
          await s.set(_valueKey, rate.toStringAsFixed(2));
          await s.set(_dateKey, today);
          return rate;
        }
      }
    } catch (e) {
      logError('فشل جلب سعر الدولار', e);
    } finally {
      if (client == null) c.close();
    }
    return cached(); // fallback للمكاش المخزّن
  }
}
