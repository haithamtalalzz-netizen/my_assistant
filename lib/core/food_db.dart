import 'dart:convert';
import 'log.dart';

import 'package:http/http.dart' as http;

import 'app_state.dart';
import 'l10n.dart';

/// صنف أكل/شرب بقيمه الغذائية لكل 100 جم (أو 100 مل للمشروبات).
class FoodItem {
  final String ar;
  final String en;

  /// القيم لكل 100 جم / 100 مل.
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// وحدة القياس المعروضة: «جم» أو «مل».
  final String unit;

  /// الحصة الافتراضية بالجرام/المل (اللي بتظهر أول ما تختار الصنف).
  final double portion;

  /// تصنيف مبسّط للتجميع في الواجهة.
  final String group;

  const FoodItem(
    this.ar,
    this.en,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat, {
    this.unit = 'جم',
    this.portion = 100,
    this.group = '',
  });

  String get name => AppState.isEnglish ? en : ar;

  /// حساب القيم لكمية معيّنة (بالجرام/المل).
  Nutrients forQty(double qty) {
    final f = qty / 100.0;
    return Nutrients(
      kcal: kcal * f,
      protein: protein * f,
      carbs: carbs * f,
      fat: fat * f,
    );
  }
}

/// قيم غذائية محسوبة (لكمية أو إجمالي يوم).
class Nutrients {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  const Nutrients({
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  Nutrients operator +(Nutrients o) => Nutrients(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fat: fat + o.fat,
      );

  bool get isEmpty => kcal == 0 && protein == 0 && carbs == 0 && fat == 0;
}

/// تطبيع عربي بسيط للبحث (يشيل التشكيل ويوحّد الهمزات والتاء المربوطة).
String foodNorm(String s) {
  var out = s.toLowerCase().trim();
  const tashkeel = ['ً', 'ٌ', 'ٍ', 'َ', 'ُ', 'ِ', 'ّ', 'ْ', 'ـ'];
  for (final t in tashkeel) {
    out = out.replaceAll(t, '');
  }
  out = out
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  return out;
}

// تصنيفات للتجميع في شاشة البحث.
const String _grain = 'نشويات';
const String _protein = 'بروتين';
const String _dairy = 'ألبان';
const String _fruit = 'فواكه';
const String _veg = 'خضار';
const String _fat = 'دهون ومكسرات';
const String _dish = 'أكلات مصرية';
const String _fast = 'وجبات سريعة';
const String _sweet = 'حلويات وسناكس';
const String _drink = 'مشروبات';

/// قاعدة بيانات أكل ومشروبات جاهزة (قيم لكل 100 جم/مل، تقريبية معتمدة).
/// دي بتغطي الأصناف الشائعة أوفلاين؛ وأي حاجة تانية بتتلقّط من Open Food Facts.
const List<FoodItem> kFoods = [
  // ---- نشويات وخبز ----
  FoodItem('عيش بلدي', 'Baladi bread', 246, 8.5, 50, 1.3, portion: 90, group: _grain),
  FoodItem('عيش فينو / توست', 'White bread', 265, 9, 49, 3.2, portion: 60, group: _grain),
  FoodItem('عيش سن / أسمر', 'Whole-wheat bread', 247, 13, 41, 3.4, portion: 90, group: _grain),
  FoodItem('رز أبيض مطبوخ', 'White rice (cooked)', 130, 2.7, 28, 0.3, portion: 150, group: _grain),
  FoodItem('رز بسمتي مطبوخ', 'Basmati rice (cooked)', 121, 3, 25, 0.4, portion: 150, group: _grain),
  FoodItem('مكرونة مطبوخة', 'Pasta (cooked)', 158, 5.8, 31, 0.9, portion: 180, group: _grain),
  FoodItem('بطاطس مسلوقة', 'Boiled potato', 87, 1.9, 20, 0.1, portion: 150, group: _grain),
  FoodItem('بطاطس محمرة', 'Fried potato', 312, 3.4, 41, 15, portion: 120, group: _grain),
  FoodItem('شوفان', 'Oats (dry)', 389, 17, 66, 7, portion: 40, group: _grain),
  FoodItem('كورن فليكس', 'Corn flakes', 357, 8, 84, 0.9, portion: 30, group: _grain),
  FoodItem('بليلة / قمح', 'Wheat porridge', 120, 4, 25, 0.8, portion: 200, group: _grain),

  // ---- بروتين (لحوم / فراخ / سمك / بيض / بقوليات) ----
  FoodItem('صدور فراخ مشوية', 'Grilled chicken breast', 165, 31, 0, 3.6, portion: 150, group: _protein),
  FoodItem('فراخ بالجلد', 'Chicken with skin', 239, 27, 0, 14, portion: 150, group: _protein),
  FoodItem('لحمة بقري', 'Beef (lean)', 250, 26, 0, 15, portion: 150, group: _protein),
  FoodItem('لحمة ضاني', 'Lamb', 294, 25, 0, 21, portion: 150, group: _protein),
  FoodItem('كبدة', 'Liver', 175, 27, 4, 5, portion: 120, group: _protein),
  FoodItem('سمك مشوي', 'Grilled fish', 128, 26, 0, 2.7, portion: 150, group: _protein),
  FoodItem('سمك بلطي مقلي', 'Fried tilapia', 200, 26, 2, 10, portion: 150, group: _protein),
  FoodItem('جمبري', 'Shrimp', 99, 24, 0.2, 0.3, portion: 120, group: _protein),
  FoodItem('تونة (مصفّاة)', 'Tuna (drained)', 116, 26, 0, 1, portion: 100, group: _protein),
  FoodItem('بيض مسلوق', 'Boiled egg', 155, 13, 1.1, 11, unit: 'جم', portion: 50, group: _protein),
  FoodItem('بيض مقلي', 'Fried egg', 196, 14, 0.8, 15, portion: 55, group: _protein),
  FoodItem('فول مدمس', 'Foul (fava beans)', 110, 7.6, 15, 1.5, portion: 200, group: _protein),
  FoodItem('عدس', 'Lentils (cooked)', 116, 9, 20, 0.4, portion: 200, group: _protein),
  FoodItem('حمص', 'Chickpeas (cooked)', 164, 9, 27, 2.6, portion: 150, group: _protein),
  FoodItem('فاصوليا بيضا', 'White beans', 139, 9, 25, 0.5, portion: 200, group: _protein),

  // ---- ألبان ----
  FoodItem('لبن كامل الدسم', 'Whole milk', 61, 3.2, 4.8, 3.3, unit: 'مل', portion: 250, group: _dairy),
  FoodItem('لبن خالي الدسم', 'Skim milk', 34, 3.4, 5, 0.1, unit: 'مل', portion: 250, group: _dairy),
  FoodItem('زبادي', 'Yogurt', 61, 3.5, 4.7, 3.3, portion: 170, group: _dairy),
  FoodItem('زبادي يوناني', 'Greek yogurt', 97, 9, 3.6, 5, portion: 170, group: _dairy),
  FoodItem('جبنة قريش', 'Cottage cheese', 98, 11, 3.4, 4.3, portion: 60, group: _dairy),
  FoodItem('جبنة بيضة', 'White cheese', 264, 14, 4, 21, portion: 40, group: _dairy),
  FoodItem('جبنة رومي', 'Roumy cheese', 357, 25, 2, 28, portion: 40, group: _dairy),
  FoodItem('جبنة موتزاريلا', 'Mozzarella', 280, 28, 3, 17, portion: 40, group: _dairy),

  // ---- فواكه ----
  FoodItem('موز', 'Banana', 89, 1.1, 23, 0.3, portion: 120, group: _fruit),
  FoodItem('تفاح', 'Apple', 52, 0.3, 14, 0.2, portion: 150, group: _fruit),
  FoodItem('برتقان', 'Orange', 47, 0.9, 12, 0.1, portion: 150, group: _fruit),
  FoodItem('عنب', 'Grapes', 69, 0.7, 18, 0.2, portion: 120, group: _fruit),
  FoodItem('مانجو', 'Mango', 60, 0.8, 15, 0.4, portion: 150, group: _fruit),
  FoodItem('بطيخ', 'Watermelon', 30, 0.6, 8, 0.2, portion: 200, group: _fruit),
  FoodItem('بلح', 'Dates', 282, 2.5, 75, 0.4, portion: 40, group: _fruit),
  FoodItem('فراولة', 'Strawberry', 32, 0.7, 7.7, 0.3, portion: 150, group: _fruit),
  FoodItem('تين', 'Figs', 74, 0.8, 19, 0.3, portion: 100, group: _fruit),
  FoodItem('جوافة', 'Guava', 68, 2.6, 14, 1, portion: 120, group: _fruit),

  // ---- خضار ----
  FoodItem('سلطة خضرا', 'Green salad', 20, 1.2, 4, 0.2, portion: 150, group: _veg),
  FoodItem('طماطم', 'Tomato', 18, 0.9, 3.9, 0.2, portion: 100, group: _veg),
  FoodItem('خيار', 'Cucumber', 15, 0.7, 3.6, 0.1, portion: 100, group: _veg),
  FoodItem('جزر', 'Carrot', 41, 0.9, 10, 0.2, portion: 80, group: _veg),
  FoodItem('بصل', 'Onion', 40, 1.1, 9, 0.1, portion: 50, group: _veg),
  FoodItem('باذنجان مطبوخ', 'Cooked eggplant', 35, 0.8, 8.7, 0.2, portion: 150, group: _veg),
  FoodItem('كوسة مطبوخة', 'Cooked zucchini', 17, 1.2, 3.1, 0.3, portion: 150, group: _veg),
  FoodItem('بامية', 'Okra', 33, 1.9, 7, 0.2, portion: 150, group: _veg),

  // ---- دهون ومكسرات ----
  FoodItem('زيت زيتون', 'Olive oil', 884, 0, 0, 100, unit: 'مل', portion: 15, group: _fat),
  FoodItem('زبدة', 'Butter', 717, 0.9, 0.1, 81, portion: 15, group: _fat),
  FoodItem('سمنة', 'Ghee', 900, 0, 0, 100, portion: 15, group: _fat),
  FoodItem('لوز', 'Almonds', 579, 21, 22, 50, portion: 30, group: _fat),
  FoodItem('عين جمل', 'Walnuts', 654, 15, 14, 65, portion: 30, group: _fat),
  FoodItem('فول سوداني', 'Peanuts', 567, 26, 16, 49, portion: 30, group: _fat),
  FoodItem('طحينة', 'Tahini', 595, 17, 21, 54, portion: 20, group: _fat),
  FoodItem('زبدة فول سوداني', 'Peanut butter', 588, 25, 20, 50, portion: 20, group: _fat),
  FoodItem('أفوكادو', 'Avocado', 160, 2, 9, 15, portion: 100, group: _fat),

  // ---- أكلات مصرية ----
  FoodItem('كشري', 'Koshari', 150, 4.5, 27, 3, portion: 300, group: _dish),
  FoodItem('طعمية / فلافل', 'Falafel', 333, 13, 32, 18, portion: 60, group: _dish),
  FoodItem('ملوخية', 'Molokhia', 60, 4, 6, 2.5, portion: 200, group: _dish),
  FoodItem('محشي', 'Stuffed veg (mahshi)', 160, 3.5, 25, 5.5, portion: 200, group: _dish),
  FoodItem('رز معمر', 'Baked rice', 190, 5, 24, 8, portion: 200, group: _dish),
  FoodItem('بطاطس بالصلصة', 'Potato in tomato', 90, 2, 15, 2.5, portion: 200, group: _dish),
  FoodItem('شكشوكة', 'Shakshuka', 118, 6, 5, 8, portion: 200, group: _dish),
  FoodItem('كبيبة / كفتة', 'Kofta', 280, 17, 6, 20, portion: 150, group: _dish),
  FoodItem('حواوشي', 'Hawawshi', 300, 15, 25, 16, portion: 200, group: _dish),
  FoodItem('مكرونة بشاميل', 'Pasta béchamel', 210, 8, 22, 10, portion: 250, group: _dish),

  // ---- وجبات سريعة ----
  FoodItem('ساندويتش شاورما', 'Shawarma sandwich', 250, 14, 24, 11, portion: 250, group: _fast),
  FoodItem('برجر', 'Burger', 254, 13, 30, 9, portion: 200, group: _fast),
  FoodItem('بيتزا', 'Pizza', 266, 11, 33, 10, portion: 150, group: _fast),
  FoodItem('فراخ بروستد', 'Fried chicken', 246, 19, 8, 15, portion: 150, group: _fast),
  FoodItem('ساندويتش فول', 'Foul sandwich', 190, 7, 30, 4, portion: 150, group: _fast),
  FoodItem('ساندويتش طعمية', 'Falafel sandwich', 260, 9, 34, 10, portion: 150, group: _fast),
  FoodItem('هوت دوج', 'Hot dog', 290, 10, 24, 17, portion: 120, group: _fast),

  // ---- حلويات وسناكس ----
  FoodItem('شيكولاتة', 'Chocolate', 546, 4.9, 61, 31, portion: 40, group: _sweet),
  FoodItem('بسكويت', 'Biscuits', 480, 6, 65, 21, portion: 30, group: _sweet),
  FoodItem('كيك', 'Cake', 350, 5, 50, 15, portion: 80, group: _sweet),
  FoodItem('آيس كريم', 'Ice cream', 207, 3.5, 24, 11, portion: 100, group: _sweet),
  FoodItem('بسبوسة', 'Basbousa', 340, 4, 55, 12, portion: 100, group: _sweet),
  FoodItem('كنافة', 'Kunafa', 380, 6, 50, 17, portion: 120, group: _sweet),
  FoodItem('أرز باللبن', 'Rice pudding', 130, 3.5, 22, 3, portion: 200, group: _sweet),
  FoodItem('عسل نحل', 'Honey', 304, 0.3, 82, 0, portion: 20, group: _sweet),
  FoodItem('شيبسي', 'Potato chips', 536, 7, 53, 34, portion: 30, group: _sweet),
  FoodItem('مكسرات مشكّلة', 'Mixed nuts', 607, 20, 20, 54, portion: 30, group: _sweet),

  // ---- مشروبات ----
  FoodItem('مياه', 'Water', 0, 0, 0, 0, unit: 'مل', portion: 250, group: _drink),
  FoodItem('شاي بسكر', 'Tea with sugar', 30, 0, 8, 0, unit: 'مل', portion: 200, group: _drink),
  FoodItem('شاي بدون سكر', 'Tea (no sugar)', 1, 0, 0.2, 0, unit: 'مل', portion: 200, group: _drink),
  FoodItem('قهوة بدون سكر', 'Coffee (no sugar)', 2, 0.1, 0, 0, unit: 'مل', portion: 150, group: _drink),
  FoodItem('نسكافيه بلبن وسكر', 'Nescafé w/ milk', 60, 1.5, 9, 1.8, unit: 'مل', portion: 200, group: _drink),
  FoodItem('عصير برتقان', 'Orange juice', 45, 0.7, 10, 0.2, unit: 'مل', portion: 250, group: _drink),
  FoodItem('عصير مانجو', 'Mango juice', 54, 0.3, 13, 0.1, unit: 'مل', portion: 250, group: _drink),
  FoodItem('مشروب غازي', 'Soda', 42, 0, 11, 0, unit: 'مل', portion: 330, group: _drink),
  FoodItem('مشروب غازي دايت', 'Diet soda', 1, 0, 0, 0, unit: 'مل', portion: 330, group: _drink),
  FoodItem('مشروب طاقة', 'Energy drink', 45, 0, 11, 0, unit: 'مل', portion: 250, group: _drink),
  FoodItem('عصير قصب', 'Sugarcane juice', 74, 0.2, 18, 0, unit: 'مل', portion: 300, group: _drink),
  FoodItem('لبن رايب', 'Buttermilk', 40, 3.3, 4.8, 0.9, unit: 'مل', portion: 250, group: _drink),
  FoodItem('بروتين واي (سكوب)', 'Whey protein (scoop)', 400, 80, 8, 6, portion: 30, group: _drink),
];

/// كل التصنيفات بالترتيب المعروض.
const List<String> kFoodGroups = [
  _grain,
  _protein,
  _dairy,
  _fruit,
  _veg,
  _fat,
  _dish,
  _fast,
  _sweet,
  _drink,
];

/// بحث أوفلاين في القاعدة المدمجة (عربي/إنجليزي، غير حسّاس للهمزات).
List<FoodItem> searchFoods(String query) {
  final q = foodNorm(query);
  if (q.isEmpty) return kFoods;
  final starts = <FoodItem>[];
  final contains = <FoodItem>[];
  for (final f in kFoods) {
    final ar = foodNorm(f.ar);
    final en = f.en.toLowerCase();
    if (ar.startsWith(q) || en.startsWith(q)) {
      starts.add(f);
    } else if (ar.contains(q) || en.contains(q)) {
      contains.add(f);
    }
  }
  return [...starts, ...contains];
}

/// بحث أونلاين في Open Food Facts (مجاني، بدون مفتاح) — للأصناف المعلّبة/الماركات.
/// بيرجّع القيم لكل 100 جم. لو النت مقطوع بيرجّع قائمة فاضية.
Future<List<FoodItem>> searchOpenFoodFacts(String query) async {
  final q = query.trim();
  if (q.length < 2) return [];
  try {
    final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeQueryComponent(q)}'
        '&search_simple=1&action=process&json=1&page_size=20'
        '&fields=product_name,product_name_ar,brands,nutriments');
    final res = await http
        .get(uri, headers: {'User-Agent': 'MyAssistant/1.0 (offline personal app)'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final products = json['products'] as List?;
    if (products == null) return [];
    final out = <FoodItem>[];
    for (final p in products.cast<Map<String, dynamic>>()) {
      final n = p['nutriments'] as Map<String, dynamic>?;
      if (n == null) continue;
      final kcal = _num(n['energy-kcal_100g']);
      if (kcal == null || kcal <= 0) continue;
      final nameAr = (p['product_name_ar'] ?? '').toString().trim();
      final nameEn = (p['product_name'] ?? '').toString().trim();
      final brand = (p['brands'] ?? '').toString().split(',').first.trim();
      var display = nameEn.isNotEmpty ? nameEn : nameAr;
      if (display.isEmpty) continue;
      if (brand.isNotEmpty && !display.toLowerCase().contains(brand.toLowerCase())) {
        display = '$display ($brand)';
      }
      out.add(FoodItem(
        nameAr.isNotEmpty ? nameAr : display,
        display,
        kcal,
        _num(n['proteins_100g']) ?? 0,
        _num(n['carbohydrates_100g']) ?? 0,
        _num(n['fat_100g']) ?? 0,
        group: tr('من الإنترنت', 'Online'),
      ));
    }
    return out;
  } on Exception catch (e) {
    logError('فشل بحث Open Food Facts', e);
    return [];
  }
}

/// يجيب منتج من Open Food Facts برقم الباركود (مجانى، بدون مفتاح).
Future<FoodItem?> lookupBarcode(String barcode) async {
  final code = barcode.trim();
  if (code.length < 6) return null;
  try {
    final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/'
        '$code.json?fields=product_name,product_name_ar,brands,nutriments');
    final res = await http.get(uri, headers: {
      'User-Agent': 'MyAssistant/1.0 (offline personal app)'
    }).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null; // مش موجود
    final p = json['product'] as Map<String, dynamic>?;
    final n = p?['nutriments'] as Map<String, dynamic>?;
    if (p == null || n == null) return null;
    final kcal = _num(n['energy-kcal_100g']);
    if (kcal == null || kcal <= 0) return null;
    final nameAr = (p['product_name_ar'] ?? '').toString().trim();
    final nameEn = (p['product_name'] ?? '').toString().trim();
    final brand = (p['brands'] ?? '').toString().split(',').first.trim();
    var display = nameEn.isNotEmpty ? nameEn : nameAr;
    if (display.isEmpty) display = code;
    if (brand.isNotEmpty && !display.toLowerCase().contains(brand.toLowerCase())) {
      display = '$display ($brand)';
    }
    return FoodItem(
      nameAr.isNotEmpty ? nameAr : display,
      display,
      kcal,
      _num(n['proteins_100g']) ?? 0,
      _num(n['carbohydrates_100g']) ?? 0,
      _num(n['fat_100g']) ?? 0,
      group: tr('من الباركود', 'From barcode'),
    );
  } on Exception catch (_) {
    return null;
  }
}

double? _num(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
