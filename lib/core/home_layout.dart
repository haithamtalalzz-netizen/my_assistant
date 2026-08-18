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
  if (picked.isEmpty) return List<String>.from(all);
  // استثناء مقصود: كروت رجعت/اتضافت بطلب صريح من المستخدم — بتتحقن فى
  // اختياره القديم مرة واحدة، وإلا ماكانش هيشوفها أبدًا. لو شالها بإيده
  // مش هترجع (`kHomeCardsSetting` بيتخزّن من غيرها).
  for (final k in kForcedHomeCards) {
    if (all.contains(k) && !picked.contains(k)) picked.insert(0, k);
  }
  return picked;
}

/// كروت لازم تظهر حتى لو المستخدم عامل اختيار قديم مش فيه (طلب صريح منه).
const List<String> kForcedHomeCards = ['tasks', 'cycle'];
