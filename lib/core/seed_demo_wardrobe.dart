import '../data/wardrobe_repo.dart';
import '../models/models.dart';
import 'app_images.dart';
import 'ar.dart';
import 'demo_images.dart';

/// ملابس تجريبية لبند «ملابسى» — ٢١ قطعة بصور **مرسومة** (قميص · جينز ·
/// جاكيت · كوتشى · ساعة …) تغطى كل فئة × موسم × رسمية، عشان الفلاتر
/// و«ألبس إيه النهارده» وسلة الغسيل يتجرّبوا كلهم.
///
/// مستقلّ عن البذّار الكبير عشان يتقدر يتضاف **ويتشال** من شاشة ملابسى
/// نفسها من غير ما يلمس باقى بيانات المستخدم.
///
/// (kind, category, name, color, season, formality) — الفئة/الموسم/الرسمية
/// لازم تكون المفاتيح المخزّنة (top/summer/formal…) مش أسماء عربية.
const List<(String, String, String, String, String, String)> kDemoClothes = [
  // top × كل موسم × كل رسمية
  ('shirt', 'top', 'قميص أبيض كلاسيك', 'أبيض', 'all', 'formal'),
  ('tshirt', 'top', 'تيشيرت قطن رمادى', 'رمادى', 'summer', 'casual'),
  ('tshirt', 'top', 'تيشيرت رياضى', 'كحلى', 'summer', 'sport'),
  ('checkShirt', 'top', 'قميص كاروهات', 'أحمر', 'winter', 'casual'),
  ('sweater', 'top', 'بلوفر صوف', 'بيج', 'winter', 'casual'),
  ('polo', 'top', 'بولو', 'أخضر', 'all', 'casual'),
  // bottom
  ('jeans', 'bottom', 'بنطلون جينز', 'أزرق', 'all', 'casual'),
  ('trousers', 'bottom', 'بنطلون قماش رسمى', 'أسود', 'all', 'formal'),
  ('shorts', 'bottom', 'شورت رياضى', 'رمادى', 'summer', 'sport'),
  ('trousers', 'bottom', 'بنطلون صوف', 'بنى', 'winter', 'casual'),
  // outer
  ('jacket', 'outer', 'جاكيت جينز', 'أزرق فاتح', 'all', 'casual'),
  ('coat', 'outer', 'بالطو شتوى', 'أسود', 'winter', 'formal'),
  ('hoodie', 'outer', 'جاكيت رياضى', 'كحلى', 'winter', 'sport'),
  // shoes
  ('shoe', 'shoes', 'حذاء كلاسيك جلد', 'أسود', 'all', 'formal'),
  ('sneaker', 'shoes', 'كوتشى أبيض', 'أبيض', 'all', 'casual'),
  ('sneaker', 'shoes', 'حذاء جرى', 'رمادى', 'summer', 'sport'),
  ('boot', 'shoes', 'بوت شتوى', 'بنى', 'winter', 'casual'),
  // accessory
  ('watch', 'accessory', 'ساعة يد', 'فضى', 'all', 'formal'),
  ('cap', 'accessory', 'كاب رياضى', 'أسود', 'summer', 'sport'),
  ('scarf', 'accessory', 'كوفية صوف', 'رمادى', 'winter', 'casual'),
  ('belt', 'accessory', 'حزام جلد', 'بنى', 'all', 'formal'),
];

/// بادئة مفتاح صورة القطعة التجريبية — بيها بنعرف القطع اللى إحنا ضفناها
/// عشان «امسح الملابس التجريبية» ماتلمسش قطعة المستخدم الحقيقية أبدًا.
const String kDemoClothPhotoPrefix = '${AppImages.prefix}demo_cloth_';

bool isDemoClothing(ClothingItem c) =>
    c.photo.startsWith(kDemoClothPhotoPrefix);

/// بيضيف الـ٢١ قطعة بصورها. بيرجّع عدد اللى اتضاف.
/// (بيضيف من غير ما يمسح — [removeDemoWardrobe] هى اللى بتشيل.)
Future<int> seedDemoWardrobe({DateTime? now}) async {
  final today = now ?? DateTime.now();
  String d([int back = 0]) => dayKey(today.subtract(Duration(days: back)));
  final repo = WardrobeRepo();
  var n = 0;
  for (final (i, c) in kDemoClothes.indexed) {
    final (kind, category, name, color, season, formality) = c;
    // الصورة بتتخزّن جوه القاعدة زى أى صورة، فبتشتغل على الموبايل والويب
    // وبتسافر مع النسخة الاحتياطية.
    final photo = await AppImages.storeBytes(demoClothingPng(kind, color),
        mime: 'image/png', namePrefix: 'demo_cloth');
    await repo.save(ClothingItem(
        name: name, category: category, color: color, season: season,
        formality: formality, photo: photo,
        // بعضها متلبِس مؤخرًا، بعضها من زمان، وبعضها لسه.
        lastWorn: i % 3 == 0 ? d(i * 2) : null,
        // مفضّلة متنوّعة عبر الفئات.
        favorite: i % 5 == 0,
        // شوية محتاجة غسيل (عشان بند «الغسيل» يبان).
        needsWash: i % 6 == 2));
    n++;
  }
  return n;
}

/// عدد القطع التجريبية الموجودة حاليًا.
Future<int> demoWardrobeCount() async =>
    (await WardrobeRepo().all_()).where(isDemoClothing).length;

/// بيشيل القطع التجريبية **بس** (بصورها) ويرجّع عددها. قطع المستخدم
/// الحقيقية — حتى اللى من غير صورة — ماتتلمسش.
Future<int> removeDemoWardrobe() async {
  final repo = WardrobeRepo();
  var n = 0;
  for (final c in await repo.all_()) {
    if (!isDemoClothing(c)) continue;
    await AppImages.remove(c.photo);
    await repo.delete(c.id!);
    n++;
  }
  return n;
}
