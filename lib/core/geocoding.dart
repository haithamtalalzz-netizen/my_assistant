import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// مكان (مدينة) من نتائج البحث الجغرافي.
class GeoPlace {
  final String name;
  final String country;
  final String admin1; // المحافظة/الولاية
  final double lat;
  final double lng;

  const GeoPlace({
    required this.name,
    required this.country,
    required this.admin1,
    required this.lat,
    required this.lng,
  });

  /// عنوان معروض: «المدينة، المنطقة، الدولة».
  String get label => [
        name,
        if (admin1.isNotEmpty && admin1 != name) admin1,
        if (country.isNotEmpty) country,
      ].join('، ');
}

/// بحث عن أي مدينة في العالم عبر Open-Meteo Geocoding (مجاني، بدون مفتاح).
/// بيرجّع الإحداثيات المستخدمة في مواعيد الصلاة والطقس.
Future<List<GeoPlace>> searchCities(String query, {String language = 'ar'}) async {
  final q = query.trim();
  if (q.length < 2) return [];
  try {
    final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeQueryComponent(q)}'
        '&count=10&language=$language&format=json');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = json['results'] as List?;
    if (results == null) return [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        GeoPlace(
          name: (r['name'] ?? '').toString(),
          country: (r['country'] ?? '').toString(),
          admin1: (r['admin1'] ?? '').toString(),
          lat: (r['latitude'] as num).toDouble(),
          lng: (r['longitude'] as num).toDouble(),
        ),
    ];
  } on Exception catch (e) {
    dev.log('فشل البحث الجغرافي', error: e);
    return [];
  }
}
