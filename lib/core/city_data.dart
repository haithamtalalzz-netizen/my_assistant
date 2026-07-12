/// مدينة مدمجة (اسم عربي/إنجليزي + إحداثيات) — عشان تظهر ليست فورًا بعد اختيار الدولة.
class CityEntry {
  final String ar;
  final String en;
  final double lat;
  final double lng;
  const CityEntry(this.ar, this.en, this.lat, this.lng);
}

/// أهم مدن كل دولة (مفتاح = كود ISO). الدول العربية مفصّلة، والباقي عواصم وكبرى.
/// أي مدينة مش هنا المستخدم بيلاقيها بالبحث (Open-Meteo).
const Map<String, List<CityEntry>> kCitiesByCountry = {
  'EG': [
    CityEntry('القاهرة', 'Cairo', 30.0444, 31.2357),
    CityEntry('الجيزة', 'Giza', 30.0131, 31.2089),
    CityEntry('الإسكندرية', 'Alexandria', 31.2001, 29.9187),
    CityEntry('الغردقة', 'Hurghada', 27.2579, 33.8116),
    CityEntry('شرم الشيخ', 'Sharm El-Sheikh', 27.9158, 34.3300),
    CityEntry('المنصورة', 'Mansoura', 31.0409, 31.3785),
    CityEntry('طنطا', 'Tanta', 30.7865, 31.0004),
    CityEntry('الفيوم', 'Faiyum', 29.3084, 30.8428),
    CityEntry('الإسماعيلية', 'Ismailia', 30.6043, 32.2723),
    CityEntry('بورسعيد', 'Port Said', 31.2653, 32.3019),
    CityEntry('السويس', 'Suez', 29.9668, 32.5498),
    CityEntry('أسيوط', 'Asyut', 27.1809, 31.1837),
    CityEntry('سوهاج', 'Sohag', 26.5569, 31.6948),
    CityEntry('قنا', 'Qena', 26.1642, 32.7267),
    CityEntry('الأقصر', 'Luxor', 25.6872, 32.6396),
    CityEntry('أسوان', 'Aswan', 24.0889, 32.8998),
    CityEntry('المنيا', 'Minya', 28.1099, 30.7503),
    CityEntry('بني سويف', 'Beni Suef', 29.0661, 31.0994),
    CityEntry('دمياط', 'Damietta', 31.4165, 31.8133),
    CityEntry('الزقازيق', 'Zagazig', 30.5877, 31.5020),
    CityEntry('دمنهور', 'Damanhur', 31.0341, 30.4682),
    CityEntry('كفر الشيخ', 'Kafr El-Sheikh', 31.1117, 30.9398),
    CityEntry('مرسى مطروح', 'Marsa Matruh', 31.3543, 27.2373),
  ],
  'SA': [
    CityEntry('الرياض', 'Riyadh', 24.7136, 46.6753),
    CityEntry('جدة', 'Jeddah', 21.4858, 39.1925),
    CityEntry('مكة المكرمة', 'Mecca', 21.3891, 39.8579),
    CityEntry('المدينة المنورة', 'Medina', 24.5247, 39.5692),
    CityEntry('الدمام', 'Dammam', 26.4207, 50.0888),
    CityEntry('الخبر', 'Khobar', 26.2794, 50.2083),
    CityEntry('الطائف', 'Taif', 21.2703, 40.4158),
    CityEntry('تبوك', 'Tabuk', 28.3835, 36.5662),
    CityEntry('أبها', 'Abha', 18.2465, 42.5117),
    CityEntry('بريدة', 'Buraydah', 26.3260, 43.9750),
    CityEntry('حائل', 'Hail', 27.5114, 41.7208),
  ],
  'AE': [
    CityEntry('دبي', 'Dubai', 25.2048, 55.2708),
    CityEntry('أبو ظبي', 'Abu Dhabi', 24.4539, 54.3773),
    CityEntry('الشارقة', 'Sharjah', 25.3463, 55.4209),
    CityEntry('العين', 'Al Ain', 24.1917, 55.7605),
    CityEntry('عجمان', 'Ajman', 25.4052, 55.5136),
    CityEntry('رأس الخيمة', 'Ras Al Khaimah', 25.8007, 55.9762),
    CityEntry('الفجيرة', 'Fujairah', 25.1288, 56.3265),
  ],
  'KW': [
    CityEntry('مدينة الكويت', 'Kuwait City', 29.3759, 47.9774),
    CityEntry('حولي', 'Hawalli', 29.3328, 48.0286),
    CityEntry('الأحمدي', 'Al Ahmadi', 29.0769, 48.0838),
    CityEntry('الجهراء', 'Al Jahra', 29.3375, 47.6581),
  ],
  'QA': [
    CityEntry('الدوحة', 'Doha', 25.2854, 51.5310),
    CityEntry('الريان', 'Al Rayyan', 25.2919, 51.4244),
    CityEntry('الوكرة', 'Al Wakrah', 25.1715, 51.6034),
  ],
  'BH': [
    CityEntry('المنامة', 'Manama', 26.2285, 50.5860),
    CityEntry('المحرق', 'Muharraq', 26.2572, 50.6119),
    CityEntry('الرفاع', 'Riffa', 26.1300, 50.5550),
  ],
  'OM': [
    CityEntry('مسقط', 'Muscat', 23.5880, 58.3829),
    CityEntry('صلالة', 'Salalah', 17.0151, 54.0924),
    CityEntry('صحار', 'Sohar', 24.3470, 56.7091),
    CityEntry('نزوى', 'Nizwa', 22.9333, 57.5333),
  ],
  'JO': [
    CityEntry('عمّان', 'Amman', 31.9454, 35.9284),
    CityEntry('الزرقاء', 'Zarqa', 32.0728, 36.0880),
    CityEntry('إربد', 'Irbid', 32.5556, 35.8500),
    CityEntry('العقبة', 'Aqaba', 29.5320, 35.0060),
  ],
  'LB': [
    CityEntry('بيروت', 'Beirut', 33.8938, 35.5018),
    CityEntry('طرابلس', 'Tripoli', 34.4367, 35.8497),
    CityEntry('صيدا', 'Sidon', 33.5571, 35.3729),
    CityEntry('صور', 'Tyre', 33.2705, 35.2038),
  ],
  'SY': [
    CityEntry('دمشق', 'Damascus', 33.5138, 36.2765),
    CityEntry('حلب', 'Aleppo', 36.2021, 37.1343),
    CityEntry('حمص', 'Homs', 34.7324, 36.7137),
    CityEntry('اللاذقية', 'Latakia', 35.5317, 35.7915),
    CityEntry('حماة', 'Hama', 35.1318, 36.7578),
  ],
  'IQ': [
    CityEntry('بغداد', 'Baghdad', 33.3152, 44.3661),
    CityEntry('البصرة', 'Basra', 30.5085, 47.7835),
    CityEntry('الموصل', 'Mosul', 36.3350, 43.1189),
    CityEntry('أربيل', 'Erbil', 36.1901, 44.0092),
    CityEntry('النجف', 'Najaf', 32.0000, 44.3350),
    CityEntry('كربلاء', 'Karbala', 32.6160, 44.0249),
  ],
  'PS': [
    CityEntry('القدس', 'Jerusalem', 31.7683, 35.2137),
    CityEntry('غزة', 'Gaza', 31.5017, 34.4668),
    CityEntry('رام الله', 'Ramallah', 31.9038, 35.2034),
    CityEntry('الخليل', 'Hebron', 31.5326, 35.0998),
    CityEntry('نابلس', 'Nablus', 32.2211, 35.2544),
  ],
  'YE': [
    CityEntry('صنعاء', 'Sanaa', 15.3694, 44.1910),
    CityEntry('عدن', 'Aden', 12.7855, 45.0187),
    CityEntry('تعز', 'Taiz', 13.5789, 44.0219),
    CityEntry('الحديدة', 'Hodeidah', 14.7978, 42.9545),
  ],
  'SD': [
    CityEntry('الخرطوم', 'Khartoum', 15.5007, 32.5599),
    CityEntry('أم درمان', 'Omdurman', 15.6445, 32.4777),
    CityEntry('بورتسودان', 'Port Sudan', 19.6175, 37.2164),
  ],
  'LY': [
    CityEntry('طرابلس', 'Tripoli', 32.8872, 13.1913),
    CityEntry('بنغازي', 'Benghazi', 32.1167, 20.0686),
    CityEntry('مصراتة', 'Misrata', 32.3754, 15.0925),
  ],
  'TN': [
    CityEntry('تونس', 'Tunis', 36.8065, 10.1815),
    CityEntry('صفاقس', 'Sfax', 34.7406, 10.7603),
    CityEntry('سوسة', 'Sousse', 35.8256, 10.6084),
  ],
  'DZ': [
    CityEntry('الجزائر', 'Algiers', 36.7538, 3.0588),
    CityEntry('وهران', 'Oran', 35.6971, -0.6337),
    CityEntry('قسنطينة', 'Constantine', 36.3650, 6.6147),
    CityEntry('عنابة', 'Annaba', 36.9000, 7.7667),
  ],
  'MA': [
    CityEntry('الرباط', 'Rabat', 34.0209, -6.8416),
    CityEntry('الدار البيضاء', 'Casablanca', 33.5731, -7.5898),
    CityEntry('مراكش', 'Marrakesh', 31.6295, -7.9811),
    CityEntry('فاس', 'Fez', 34.0181, -5.0078),
    CityEntry('طنجة', 'Tangier', 35.7595, -5.8340),
    CityEntry('أكادير', 'Agadir', 30.4278, -9.5981),
  ],
  'MR': [CityEntry('نواكشوط', 'Nouakchott', 18.0735, -15.9582)],
  'SO': [CityEntry('مقديشو', 'Mogadishu', 2.0469, 45.3182)],
  'DJ': [CityEntry('جيبوتي', 'Djibouti', 11.5721, 43.1456)],
  // دول أخرى — عواصم وكبرى.
  'TR': [
    CityEntry('إسطنبول', 'Istanbul', 41.0082, 28.9784),
    CityEntry('أنقرة', 'Ankara', 39.9334, 32.8597),
    CityEntry('إزمير', 'Izmir', 38.4237, 27.1428),
    CityEntry('بورصة', 'Bursa', 40.1885, 29.0610),
    CityEntry('أنطاليا', 'Antalya', 36.8969, 30.7133),
  ],
  'GB': [
    CityEntry('لندن', 'London', 51.5074, -0.1278),
    CityEntry('مانشستر', 'Manchester', 53.4808, -2.2426),
    CityEntry('برمنغهام', 'Birmingham', 52.4862, -1.8904),
  ],
  'US': [
    CityEntry('نيويورك', 'New York', 40.7128, -74.0060),
    CityEntry('لوس أنجلوس', 'Los Angeles', 34.0522, -118.2437),
    CityEntry('شيكاغو', 'Chicago', 41.8781, -87.6298),
    CityEntry('هيوستن', 'Houston', 29.7604, -95.3698),
    CityEntry('واشنطن', 'Washington', 38.9072, -77.0369),
  ],
  'FR': [
    CityEntry('باريس', 'Paris', 48.8566, 2.3522),
    CityEntry('مرسيليا', 'Marseille', 43.2965, 5.3698),
    CityEntry('ليون', 'Lyon', 45.7640, 4.8357),
  ],
  'DE': [
    CityEntry('برلين', 'Berlin', 52.5200, 13.4050),
    CityEntry('ميونخ', 'Munich', 48.1351, 11.5820),
    CityEntry('فرانكفورت', 'Frankfurt', 50.1109, 8.6821),
  ],
  'CA': [
    CityEntry('تورنتو', 'Toronto', 43.6532, -79.3832),
    CityEntry('مونتريال', 'Montreal', 45.5017, -73.5673),
    CityEntry('فانكوفر', 'Vancouver', 49.2827, -123.1207),
  ],
  'IT': [
    CityEntry('روما', 'Rome', 41.9028, 12.4964),
    CityEntry('ميلانو', 'Milan', 45.4642, 9.1900),
  ],
  'ES': [
    CityEntry('مدريد', 'Madrid', 40.4168, -3.7038),
    CityEntry('برشلونة', 'Barcelona', 41.3874, 2.1686),
  ],
  'IN': [
    CityEntry('نيودلهي', 'New Delhi', 28.6139, 77.2090),
    CityEntry('مومباي', 'Mumbai', 19.0760, 72.8777),
  ],
  'PK': [
    CityEntry('إسلام آباد', 'Islamabad', 33.6844, 73.0479),
    CityEntry('كراتشي', 'Karachi', 24.8607, 67.0011),
    CityEntry('لاهور', 'Lahore', 31.5204, 74.3587),
  ],
  'ID': [CityEntry('جاكرتا', 'Jakarta', -6.2088, 106.8456)],
  'MY': [CityEntry('كوالالمبور', 'Kuala Lumpur', 3.1390, 101.6869)],
};

/// أهم مدن دولة (أو قائمة فاضية لو مش مبنّدة).
List<CityEntry> citiesForCountry(String? code) {
  if (code == null) return const [];
  return kCitiesByCountry[code.toUpperCase()] ?? const [];
}
