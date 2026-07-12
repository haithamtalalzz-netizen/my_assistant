import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// مكان (مدينة) من نتائج البحث الجغرافي.
class GeoPlace {
  final String name;
  final String country;
  final String admin1; // المحافظة/الولاية
  final String countryCode; // كود ISO حرفين
  final double lat;
  final double lng;

  const GeoPlace({
    required this.name,
    required this.country,
    required this.admin1,
    this.countryCode = '',
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

/// بحث عن مدينة عبر Open-Meteo Geocoding (مجاني، بدون مفتاح).
/// لو اتحدد [countryCode] بيفلتر النتائج على الدولة دي بس.
Future<List<GeoPlace>> searchCities(String query,
    {String language = 'ar', String? countryCode}) async {
  final q = query.trim();
  if (q.length < 2) return [];
  try {
    final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeQueryComponent(q)}'
        '&count=30&language=$language&format=json');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = json['results'] as List?;
    if (results == null) return [];
    final wanted = countryCode?.toUpperCase();
    final out = <GeoPlace>[];
    for (final r in results.cast<Map<String, dynamic>>()) {
      final cc = (r['country_code'] ?? '').toString().toUpperCase();
      if (wanted != null && wanted.isNotEmpty && cc != wanted) continue;
      out.add(GeoPlace(
        name: (r['name'] ?? '').toString(),
        country: (r['country'] ?? '').toString(),
        admin1: (r['admin1'] ?? '').toString(),
        countryCode: cc,
        lat: (r['latitude'] as num).toDouble(),
        lng: (r['longitude'] as num).toDouble(),
      ));
    }
    return out;
  } on Exception catch (e) {
    dev.log('فشل البحث الجغرافي', error: e);
    return [];
  }
}

/// عكس الإحداثيات لاسم مكان (من الـGPS) عبر BigDataCloud المجاني (بدون مفتاح).
Future<GeoPlace?> reverseGeocode(double lat, double lng,
    {String language = 'ar'}) async {
  try {
    final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lng&localityLanguage=$language');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final city = (j['city'] ?? j['locality'] ?? '').toString();
    final admin1 = (j['principalSubdivision'] ?? '').toString();
    return GeoPlace(
      name: city.isNotEmpty ? city : admin1,
      country: (j['countryName'] ?? '').toString(),
      admin1: admin1,
      countryCode: (j['countryCode'] ?? '').toString().toUpperCase(),
      lat: lat,
      lng: lng,
    );
  } on Exception catch (e) {
    dev.log('فشل عكس الإحداثيات', error: e);
    return null;
  }
}

/// كل مدن دولة بالاسم عبر countriesnow.space (مجاني، بدون مفتاح).
/// [countryEnglishName] لازم بالإنجليزي (زي «Egypt»/«Canada»).
Future<List<String>> fetchCountryCities(String countryEnglishName) async {
  if (countryEnglishName.trim().isEmpty) return [];
  try {
    final uri =
        Uri.parse('https://countriesnow.space/api/v0.1/countries/cities');
    final res = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'country': countryEnglishName}))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['error'] == true) return [];
    final data = j['data'] as List?;
    if (data == null) return [];
    final out = data
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    out.sort();
    return out;
  } on Exception catch (e) {
    dev.log('فشل جلب مدن الدولة', error: e);
    return [];
  }
}

/// يحوّل اسم مدينة لإحداثيات عبر Open-Meteo (للمواعيد والطقس). null لو مالقاش.
Future<GeoPlace?> resolveCity(String name, {String? countryCode}) async {
  final inCountry = await searchCities(name, countryCode: countryCode);
  if (inCountry.isNotEmpty) return inCountry.first;
  final anywhere = await searchCities(name);
  return anywhere.isNotEmpty ? anywhere.first : null;
}
