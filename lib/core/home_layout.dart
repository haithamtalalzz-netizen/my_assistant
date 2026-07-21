import 'l10n.dart';

/// شكل الصفحة الرئيسية.
///
/// إحنا بنعيد بناء الرئيسية، والأشكال دى معروضة كلها فى نفس البناء عشان
/// المستخدم يقلّب بينهم على بياناته الحقيقية ويختار — بدل ما نوصفها بالكلام.
enum HomeLayout {
  /// الشكل القديم: ١٥ قسم ورا بعض (البند ممكن يتكرّر فى «محتاج منك دلوقتي»).
  classic,

  /// يومك مرتّب بالوقت فى قايمة واحدة — كل حاجة مرة واحدة بس.
  timeline,

  /// شاشة واحدة من غير تمرير: الحلقات + المهم + الأزرار السريعة.
  oneScreen,

  /// طبقتين: كارت «دلوقتى» فوق، و«اليوم» تحته مضغوط.
  twoLayer,

  /// شبكة مربعات بأحجام مختلفة — الأهم أكبر.
  bento,

  /// كارت واحد بس: تسحب يمين = تم، شمال = بعدين.
  deck,

  /// دايرة زى الساعة، بنودك متوزّعة حواليها بمواعيدها.
  ring,

  /// ٣ شرايح تتسحب أفقى: يومك · صحتك · أقسامك.
  stories,

  /// المستخدم بيبنيها بنفسه: ترحيب + إجراءات سريعة يختارها + كروت يختارها.
  custom,
}

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

const String kHomeLayoutSetting = 'home_layout';

HomeLayout homeLayoutFromKey(String? key) => switch (key) {
      'timeline' => HomeLayout.timeline,
      'one_screen' => HomeLayout.oneScreen,
      'two_layer' => HomeLayout.twoLayer,
      'bento' => HomeLayout.bento,
      'deck' => HomeLayout.deck,
      'ring' => HomeLayout.ring,
      'stories' => HomeLayout.stories,
      'custom' => HomeLayout.custom,
      _ => HomeLayout.classic,
    };

String homeLayoutKey(HomeLayout l) => switch (l) {
      HomeLayout.timeline => 'timeline',
      HomeLayout.oneScreen => 'one_screen',
      HomeLayout.twoLayer => 'two_layer',
      HomeLayout.bento => 'bento',
      HomeLayout.deck => 'deck',
      HomeLayout.ring => 'ring',
      HomeLayout.stories => 'stories',
      HomeLayout.custom => 'custom',
      HomeLayout.classic => 'classic',
    };

String homeLayoutLabel(HomeLayout l) => switch (l) {
      HomeLayout.classic => tr('القديم', 'Classic'),
      HomeLayout.timeline => tr('خط اليوم', 'Timeline'),
      HomeLayout.oneScreen => tr('شاشة واحدة', 'One screen'),
      HomeLayout.twoLayer => tr('دلوقتى / اليوم', 'Now / Today'),
      HomeLayout.bento => tr('بينتو', 'Bento'),
      HomeLayout.deck => tr('كارت واحد', 'One card'),
      HomeLayout.ring => tr('حلقة اليوم', 'Day ring'),
      HomeLayout.stories => tr('شرايح', 'Slides'),
      HomeLayout.custom => tr('على مزاجك', 'Yours'),
    };

String homeLayoutDescription(HomeLayout l) => switch (l) {
      HomeLayout.classic =>
        tr('كل الأقسام ورا بعض زى ما كانت.', 'All sections stacked, as before.'),
      HomeLayout.timeline => tr(
          'يومك مرتّب بالساعة فى قايمة واحدة — الصلاة والموعد والدوا والأكل، كل حاجة مرة واحدة.',
          'Your day in one time-ordered list — each item appears once.'),
      HomeLayout.oneScreen => tr(
          'كل المهم فى شاشة واحدة من غير تمرير، والتفاصيل فى الأقسام.',
          'Everything important on one screen, details live in sections.'),
      HomeLayout.twoLayer => tr(
          'كارت «دلوقتى» فيه أهم ٣ حاجات، وتحته ملخص اليوم مضغوط.',
          'A "now" card with your top 3, then a compact day summary.'),
      HomeLayout.bento => tr(
          'مربعات بأحجام مختلفة — الأهم أكبر، والأرقام صغيرة جنبه.',
          'Tiles of different sizes — the important one is the biggest.'),
      HomeLayout.deck => tr(
          'حاجة واحدة بس قدّامك: اسحب يمين = تم، شمال = بعدين.',
          'One thing at a time: swipe right = done, left = later.'),
      HomeLayout.ring => tr(
          'دايرة زى الساعة، بنودك حواليها بمواعيدها، وفى النص اللى جاى.',
          'A clock-like ring with your day around it, next up in the middle.'),
      HomeLayout.stories => tr(
          'اسحب أفقى بين ٣ شرايح: يومك · صحتك · أقسامك.',
          'Swipe between 3 slides: your day · health · sections.'),
      HomeLayout.custom => tr(
          'ترحيب + إجراءات سريعة تختارها + كروت تختارها. دوس ＋ لأى منهم.',
          'Greeting + quick actions you pick + cards you pick. Tap ＋ on either.'),
    };
