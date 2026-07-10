import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../data/settings_repo.dart';
import 'l10n.dart';
import 'prayers.dart';

class WeatherToday {
  final double maxTemp;
  final double minTemp;
  final int code;

  const WeatherToday(this.maxTemp, this.minTemp, this.code);

  String get condition {
    if (code == 0) return tr('صافي', 'Clear');
    if (code <= 3) return tr('غيوم خفيفة', 'Partly cloudy');
    if (code <= 48) return tr('شبورة', 'Fog');
    if (code <= 67) return tr('مطر', 'Rain');
    if (code <= 77) return tr('تلج', 'Snow');
    if (code <= 82) return tr('زخات مطر', 'Showers');
    if (code <= 99) return tr('رعد', 'Thunderstorm');
    return '';
  }

  /// جملة للملخص الصباحي مع نصيحة عملية.
  String summaryLine() {
    final maxR = maxTemp.round();
    final base = tr('الجو $condition، الحرارة العظمى $maxR°',
        '$condition, high $maxR°');
    if (maxR >= 40) {
      return tr('$base — حر شديد، زوّد المياه وقلل الخروج الضهر.',
          '$base — very hot, drink more water and limit midday outings.');
    }
    if (maxR >= 33) {
      return tr('$base — الجو حر، خد بالك من المياه.',
          '$base — hot, stay hydrated.');
    }
    if (code >= 51 && code <= 82) {
      return tr('$base — خد شمسية معاك.', '$base — take an umbrella.');
    }
    if (maxR <= 12) {
      return tr('$base — الجو برد، لبس تقيل.', '$base — cold, dress warm.');
    }
    return '$base.';
  }
}

/// طقس النهارده عبر open-meteo (مجاني تمامًا، من غير مفتاح) —
/// باستخدام إحداثيات محافظة المستخدم المسجلة (من غير إذن موقع).
/// النتيجة بتتكاش يوم كامل عشان مانستهلكش الشبكة كل فتحة.
class WeatherService {
  static Future<WeatherToday?> today() async {
    final settings = SettingsRepo();
    final todayKey = _todayKey();
    final cached = await settings.get('weather_cache');
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        if (map['day'] == todayKey) {
          return WeatherToday((map['max'] as num).toDouble(),
              (map['min'] as num).toDouble(), map['code'] as int);
        }
      } on Exception catch (_) {
        // كاش تالف — نتجاهله ونجيب من جديد.
      }
    }
    return _fetch(settings, todayKey);
  }

  static Future<WeatherToday?> _fetch(
      SettingsRepo settings, String todayKey) async {
    try {
      final gov = governorateByName(await settings.governorateName());
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=${gov.lat}&longitude=${gov.lng}'
          '&daily=temperature_2m_max,temperature_2m_min,weather_code'
          '&timezone=auto&forecast_days=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>;
      final max = (daily['temperature_2m_max'] as List).first as num;
      final min = (daily['temperature_2m_min'] as List).first as num;
      final code = (daily['weather_code'] as List).first as num;
      await settings.set(
          'weather_cache',
          jsonEncode({
            'day': todayKey,
            'max': max,
            'min': min,
            'code': code.toInt(),
          }));
      return WeatherToday(max.toDouble(), min.toDouble(), code.toInt());
    } on Exception catch (e) {
      dev.log('فشل جلب الطقس', error: e);
      return null;
    }
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}
