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
}

const String kHomeLayoutSetting = 'home_layout';

HomeLayout homeLayoutFromKey(String? key) => switch (key) {
      'timeline' => HomeLayout.timeline,
      'one_screen' => HomeLayout.oneScreen,
      'two_layer' => HomeLayout.twoLayer,
      _ => HomeLayout.classic,
    };

String homeLayoutKey(HomeLayout l) => switch (l) {
      HomeLayout.timeline => 'timeline',
      HomeLayout.oneScreen => 'one_screen',
      HomeLayout.twoLayer => 'two_layer',
      HomeLayout.classic => 'classic',
    };

String homeLayoutLabel(HomeLayout l) => switch (l) {
      HomeLayout.classic => tr('القديم', 'Classic'),
      HomeLayout.timeline => tr('خط اليوم', 'Timeline'),
      HomeLayout.oneScreen => tr('شاشة واحدة', 'One screen'),
      HomeLayout.twoLayer => tr('دلوقتى / اليوم', 'Now / Today'),
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
    };
