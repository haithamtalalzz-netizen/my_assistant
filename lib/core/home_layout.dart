/// إعداد كروت الصفحة الرئيسية.
///
/// الملف كان فيه ٩ أشكال للرئيسية كنا بنجرّبهم؛ المستخدم استقرّ على
/// «على مزاجك» فالباقى اتشال (شوف التاج `before-home-layouts-purge`).
library;

/// الكروت اللى المستخدم اختار يشوفها فى الرئيسية المخصّصة (مفاتيح مفصولة
/// بفاصلة). فاضى = **الكل** — عشان مستخدم لسه ماختارش يلاقى رئيسية
/// مليانة مش فاضية.
const String kHomeCardsSetting = 'home_cards';

/// بيرتّب كروت الرئيسية حسب اختيار المستخدم.
///
/// [all] كل مفاتيح الكروت المتاحة (بترتيبها الطبيعى)، و[saved] اختيار
/// المستخدم. أى كارت جديد يتضاف للتطبيق **مابيظهرش** تلقائيًا لو
/// المستخدم عامل اختيار — عشان اختياره ما يتخرقش من ورا ضهره.
List<String> selectedHomeCards(List<String> all, String? saved) {
  final raw = (saved ?? '').split(',').where((e) => e.trim().isNotEmpty);
  final picked = [
    for (final k in raw)
      if (all.contains(k)) k,
  ];
  return picked.isEmpty ? List<String>.from(all) : picked;
}
