// فهرس القرآن الموضوعى + أدعية القرآن — نفس المبدأ الآمن المتّبع فى القصص:
// مافيش نص مكتوب هنا، بس **إشارات لآيات** تُعرض بنصّها من المصحف المدمج
// (Tanzil) مع التفسير الميسّر عند الطلب.

import 'religious_stories.dart' show StoryPassage;

/// موضوع قرآنى = عنوان + آيات تخصّه.
class QuranTopic {
  final String name;
  final String emoji;
  final List<StoryPassage> passages;
  const QuranTopic(this.name, this.emoji, this.passages);
}

/// فهرس موضوعى — «آيات عن…» لمواقف الحياة.
const List<QuranTopic> kQuranTopics = [
  QuranTopic('الصبر', '🕊️', [
    StoryPassage(2, 153, 157, 'الصبر والاستعانة والبشرى'),
    StoryPassage(3, 200, 200, 'اصبروا وصابروا'),
    StoryPassage(39, 10, 10, 'أجر الصابرين بغير حساب'),
    StoryPassage(103, 1, 3, 'التواصى بالصبر'),
  ]),
  QuranTopic('الرزق والتوكّل', '🌾', [
    StoryPassage(65, 2, 3, 'ومن يتق الله يجعل له مخرجًا'),
    StoryPassage(11, 6, 6, 'وما من دابة إلا على الله رزقها'),
    StoryPassage(29, 60, 62, 'بسط الرزق وقدره'),
    StoryPassage(51, 22, 23, 'وفى السماء رزقكم'),
  ]),
  QuranTopic('بر الوالدين', '🤲', [
    StoryPassage(17, 23, 24, 'وبالوالدين إحسانًا'),
    StoryPassage(31, 14, 15, 'وصّينا الإنسان بوالديه'),
    StoryPassage(46, 15, 15, 'الإحسان والدعاء لهما'),
  ]),
  QuranTopic('التوبة والمغفرة', '🌅', [
    StoryPassage(39, 53, 55, 'لا تقنطوا من رحمة الله'),
    StoryPassage(66, 8, 8, 'توبوا إلى الله توبة نصوحًا'),
    StoryPassage(3, 135, 136, 'المستغفرون للذنوب'),
    StoryPassage(25, 68, 71, 'من تاب وآمن وعمل صالحًا'),
  ]),
  QuranTopic('الفرج بعد الشدّة', '🌤️', [
    StoryPassage(94, 1, 8, 'فإن مع العسر يسرًا'),
    StoryPassage(65, 7, 7, 'سيجعل الله بعد عسر يسرًا'),
    StoryPassage(2, 214, 214, 'ألا إن نصر الله قريب'),
  ]),
  QuranTopic('الدعاء وقربه سبحانه', '🤍', [
    StoryPassage(2, 186, 186, 'وإذا سألك عبادى عنى فإنى قريب'),
    StoryPassage(40, 60, 60, 'ادعونى أستجب لكم'),
    StoryPassage(27, 62, 62, 'أمّن يجيب المضطر'),
  ]),
  QuranTopic('الإنفاق والصدقة', '💚', [
    StoryPassage(2, 261, 265, 'مثل الذين ينفقون أموالهم'),
    StoryPassage(2, 271, 274, 'آداب الصدقة وأجرها'),
    StoryPassage(63, 10, 10, 'وأنفقوا من ما رزقناكم'),
  ]),
  QuranTopic('الظلم وعاقبته', '⚖️', [
    StoryPassage(14, 42, 43, 'ولا تحسبنّ الله غافلًا'),
    StoryPassage(11, 102, 102, 'أخذ الله للقرى الظالمة'),
    StoryPassage(42, 40, 43, 'العفو والانتصار بالحق'),
  ]),
  QuranTopic('الأخلاق وحسن المعاملة', '🕌', [
    StoryPassage(49, 11, 13, 'آداب المجتمع المسلم'),
    StoryPassage(17, 53, 53, 'وقل لعبادى يقولوا التى هى أحسن'),
    StoryPassage(41, 34, 35, 'ادفع بالتى هى أحسن'),
    StoryPassage(31, 18, 19, 'وصايا لقمان فى الخلق'),
  ]),
  QuranTopic('العلم والتفكّر', '📚', [
    StoryPassage(3, 190, 191, 'إن فى خلق السماوات والأرض'),
    StoryPassage(39, 9, 9, 'هل يستوى الذين يعلمون'),
    StoryPassage(20, 114, 114, 'وقل ربّ زدنى علمًا'),
    StoryPassage(96, 1, 5, 'اقرأ — أول ما نزل'),
  ]),
  QuranTopic('الموت والآخرة', '🌌', [
    StoryPassage(3, 185, 185, 'كل نفس ذائقة الموت'),
    StoryPassage(99, 1, 8, 'سورة الزلزلة'),
    StoryPassage(23, 99, 100, 'ربّ ارجعون'),
  ]),
  QuranTopic('الجنة ونعيمها', '🌳', [
    StoryPassage(55, 46, 78, 'جنّتان ومن دونهما جنّتان'),
    StoryPassage(76, 5, 22, 'نعيم الأبرار'),
    StoryPassage(56, 10, 40, 'السابقون وأصحاب اليمين'),
  ]),
  QuranTopic('الرحمة وسعة المغفرة', '💫', [
    StoryPassage(7, 156, 156, 'ورحمتى وسعت كل شىء'),
    StoryPassage(6, 54, 54, 'كتب على نفسه الرحمة'),
    StoryPassage(21, 107, 107, 'وما أرسلناك إلا رحمة'),
  ]),
  QuranTopic('الأمانة والصدق', '🤝', [
    StoryPassage(4, 58, 58, 'أن تؤدّوا الأمانات'),
    StoryPassage(9, 119, 119, 'وكونوا مع الصادقين'),
    StoryPassage(33, 70, 71, 'وقولوا قولًا سديدًا'),
  ]),
  QuranTopic('القرآن وفضله', '📖', [
    StoryPassage(17, 9, 9, 'إن هذا القرآن يهدى للتى هى أقوم'),
    StoryPassage(10, 57, 58, 'موعظة وشفاء ورحمة'),
    StoryPassage(59, 21, 21, 'لو أنزلنا هذا القرآن على جبل'),
  ]),
];

/// دعاء من القرآن (الآية نفسها هى الدعاء).
class QuranDua {
  final String title;
  final StoryPassage passage;
  const QuranDua(this.title, this.passage);
}

/// أدعية وردت فى القرآن — على لسان الأنبياء والمؤمنين.
const List<QuranDua> kQuranDuas = [
  QuranDua('ربّنا آتنا فى الدنيا حسنة', StoryPassage(2, 201, 201)),
  QuranDua('ربّنا لا تؤاخذنا إن نسينا', StoryPassage(2, 286, 286)),
  QuranDua('ربّنا لا تزغ قلوبنا', StoryPassage(3, 8, 8)),
  QuranDua('ربّنا اغفر لنا ذنوبنا', StoryPassage(3, 16, 16)),
  QuranDua('دعاء أولى الألباب', StoryPassage(3, 191, 194)),
  QuranDua('حسبنا الله ونعم الوكيل', StoryPassage(3, 173, 173)),
  QuranDua('دعاء آدم عليه السلام', StoryPassage(7, 23, 23)),
  QuranDua('دعاء نوح عليه السلام', StoryPassage(23, 26, 29)),
  QuranDua('دعاء إبراهيم لوالديه وذريته', StoryPassage(14, 35, 41)),
  QuranDua('دعاء يوسف عليه السلام', StoryPassage(12, 101, 101)),
  QuranDua('دعاء موسى: ربّ اشرح لى صدرى', StoryPassage(20, 25, 28)),
  QuranDua('دعاء موسى: ربّ إنى لما أنزلت', StoryPassage(28, 24, 24)),
  QuranDua('دعاء أيوب عليه السلام', StoryPassage(21, 83, 83)),
  QuranDua('دعاء يونس فى الظلمات', StoryPassage(21, 87, 87)),
  QuranDua('دعاء زكريا عليه السلام', StoryPassage(19, 4, 6)),
  QuranDua('دعاء زكريا: ربّ هب لى', StoryPassage(3, 38, 38)),
  QuranDua('دعاء سليمان: ربّ أوزعنى', StoryPassage(27, 19, 19)),
  QuranDua('دعاء أصحاب الكهف', StoryPassage(18, 10, 10)),
  QuranDua('دعاء عباد الرحمن', StoryPassage(25, 74, 74)),
  QuranDua('ربّ زدنى علمًا', StoryPassage(20, 114, 114)),
  QuranDua('ربّ اجعلنى مقيم الصلاة', StoryPassage(14, 40, 41)),
  QuranDua('ربّنا أفرغ علينا صبرًا', StoryPassage(2, 250, 250)),
  QuranDua('ربّنا لا تجعلنا فتنة', StoryPassage(60, 5, 5)),
  QuranDua('دعاء المؤمنين لإخوانهم', StoryPassage(59, 10, 10)),
];
