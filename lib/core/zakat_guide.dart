// محتوى «دليل الزكاة» — بيانات محلية تعريفية مبسّطة (عربى/إنجليزى).
// شرح عام لبنود الزكاة ومصارفها الثمانية وشروط وجوبها. للمسائل الخاصة
// بحالة المستخدم: يُستفتى أهل العلم الموثوقون.

/// أحد مصارف الزكاة الثمانية (سورة التوبة: 60).
class ZakatRecipient {
  final int number;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  const ZakatRecipient(
      this.number, this.titleAr, this.titleEn, this.descAr, this.descEn);
}

/// قسم قابل للطى فى صفحة الدليل.
class ZakatGuideSection {
  final String emoji;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  const ZakatGuideSection(
      this.emoji, this.titleAr, this.titleEn, this.bodyAr, this.bodyEn);
}

/// مصارف الزكاة الثمانية.
const List<ZakatRecipient> kZakatRecipients = [
  ZakatRecipient(1, 'الفقراء', 'The poor (al-fuqarā)',
      'من لا يجدون كفايتهم ولا يملكون ما يسدّ حاجتهم الأساسية.',
      'Those who have almost nothing and cannot meet their basic needs.'),
  ZakatRecipient(2, 'المساكين', 'The needy (al-masākīn)',
      'من عندهم بعض الكفاية لكنها لا تكفيهم؛ حالهم أخفّ من الفقير.',
      'Those with some income that still falls short of their needs.'),
  ZakatRecipient(3, 'العاملون عليها', 'Zakat workers',
      'جُباة الزكاة والقائمون على جمعها وتوزيعها، يأخذون أجرهم منها.',
      'Those appointed to collect and distribute zakat; paid from it.'),
  ZakatRecipient(4, 'المؤلَّفة قلوبهم', 'Those whose hearts are reconciled',
      'من يُعطَون تأليفًا لقلوبهم على الإسلام أو تثبيتًا لإيمانهم.',
      'Given to soften hearts toward Islam or strengthen new faith.'),
  ZakatRecipient(5, 'فى الرِّقاب', 'Freeing captives',
      'فى عتق الأرقّاء وفكّ الأسرى والمكاتَبين.',
      'Freeing slaves and ransoming captives.'),
  ZakatRecipient(6, 'الغارمون', 'The debt-burdened',
      'المدينون العاجزون عن سداد ديونهم (لغير معصية).',
      'People overwhelmed by debt they cannot repay.'),
  ZakatRecipient(7, 'فى سبيل الله', 'In the cause of Allah',
      'الجهاد فى سبيل الله وما يُلحق به من وجوه الخير العامة (فيه سعة وخلاف).',
      'Striving in Allah’s cause and related public good (scholars differ on its breadth).'),
  ZakatRecipient(8, 'ابن السبيل', 'The stranded traveler',
      'المسافر المنقطع الذى نفد ماله وإن كان غنيًا فى بلده.',
      'A traveler stranded and out of funds, even if wealthy back home.'),
];

/// أقسام الدليل التفصيلية.
const List<ZakatGuideSection> kZakatGuideSections = [
  ZakatGuideSection(
    '📖',
    'ما هى الزكاة؟',
    'What is Zakat?',
    'الزكاة ثالث أركان الإسلام، وفريضة مالية بمقدار محدَّد يُخرجها المسلم '
        'لمستحقّين محدَّدين. سُمّيت زكاة لأنها تُطهِّر المال وتُنمّيه وتُزكّى '
        'صاحبها.\n\nقال تعالى: «خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ '
        'وَتُزَكِّيهِم بِهَا». وهى قرينة الصلاة فى مواضع كثيرة من القرآن.',
    'Zakat is the third pillar of Islam: an obligatory, fixed-rate charity paid '
        'to specific recipients. It purifies and grows one’s wealth.\n\n'
        'The Qur’an says: “Take from their wealth a charity by which you '
        'purify them.” It is paired with prayer throughout the Qur’an.',
  ),
  ZakatGuideSection(
    '✅',
    'على مَن تجب؟ (الملزمون بها)',
    'Who must pay it?',
    'تجب الزكاة بشروط مجتمعة:\n\n'
        '• الإسلام — فهى عبادة لا تُقبل من غير مسلم.\n'
        '• الحرية — على المالك الحرّ.\n'
        '• المِلك التام — أن يملك المال ملكًا مستقرًّا يتصرّف فيه.\n'
        '• بلوغ النصاب — أن يبلغ المال الحدّ الأدنى (نصاب الذهب 85جم أو الفضة 595جم).\n'
        '• حولان الحول — مرور سنة هجرية على المال (للنقود والذهب والتجارة).\n'
        '• النماء — أن يكون المال ناميًا أو قابلًا للنماء.\n\n'
        'ولا تجب على الفقير الذى لا يملك النصاب.',
    'Zakat becomes obligatory when these conditions combine:\n\n'
        '• Islam — it is an act of worship.\n'
        '• Freedom.\n'
        '• Full ownership of the wealth.\n'
        '• Reaching the nisab (85g gold or 595g silver).\n'
        '• A full lunar year passing (for cash, gold, trade goods).\n'
        '• The wealth being of a growing kind.\n\n'
        'It is not due on a poor person below the nisab.',
  ),
  ZakatGuideSection(
    '💰',
    'الأموال التى تجب فيها الزكاة (بنودها)',
    'Which assets are zakatable?',
    '• النقود: الكاش والأرصدة البنكية والمدّخرات.\n'
        '• الذهب والفضة: نصاب الذهب 85جم، والفضة 595جم. وحُلىّ المرأة للاستعمال '
        'فيه خلاف، والأحوط إخراج زكاته.\n'
        '• عروض التجارة: البضائع بقيمتها السوقية يوم وجوب الزكاة.\n'
        '• الأسهم والاستثمارات: إن كانت للمتاجرة فبقيمتها السوقية؛ وإن كانت '
        'للاستثمار طويل الأجل فتُزكّى بحسب تفصيل أهل العلم.\n'
        '• الأنعام السائمة: الإبل والبقر والغنم لها أنصبة خاصة.\n'
        '• الزروع والثمار: العُشر (سُقى بلا كلفة) أو نصف العُشر (سُقى بكلفة) عند '
        'الحصاد — ولا يُشترط لها حول.\n'
        '• الركاز والمعادن: فى الركاز الخُمس.\n'
        '• الديون المرجوّة لك: تُزكّى مع مالك ما دام يغلب رجوعها.',
    '• Cash: money in hand, bank balances, savings.\n'
        '• Gold & silver: nisab 85g gold / 595g silver. Women’s worn jewelry '
        'is debated; paying is safer.\n'
        '• Trade goods: at market value on the due date.\n'
        '• Shares & investments: trading stock at market value; long-term '
        'holdings per detailed scholarly rulings.\n'
        '• Grazing livestock: camels, cattle, sheep have their own thresholds.\n'
        '• Crops & fruits: 10% (rain-fed) or 5% (irrigated at cost) at harvest — '
        'no lunar-year condition.\n'
        '• Buried treasure & minerals: 20% on rikāz.\n'
        '• Recoverable debts owed to you: zakated with your wealth.',
  ),
  ZakatGuideSection(
    '🚫',
    'من لا تُدفع لهم الزكاة',
    'Who cannot receive it',
    '• الأصول: الآباء والأمهات والأجداد — لأن نفقتهم قد تلزمك.\n'
        '• الفروع: الأبناء والأحفاد.\n'
        '• الزوجة: نفقتها على زوجها (ويجوز للزوجة إعطاء زوجها الفقير على قول).\n'
        '• الأغنياء ومَن تلزمك نفقتهم.\n'
        '• آل بيت النبى ﷺ (بنو هاشم) على قول الجمهور.\n'
        '• غير المسلم من زكاة المال (تجوز له صدقة التطوّع)، إلا سهم المؤلَّفة قلوبهم.',
    '• Ascendants: parents and grandparents (you may owe their upkeep).\n'
        '• Descendants: children and grandchildren.\n'
        '• A wife (her upkeep is on the husband).\n'
        '• The wealthy and anyone whose support you already owe.\n'
        '• The Prophet’s family (Banū Hāshim), per the majority.\n'
        '• Non-Muslims from obligatory zakat (voluntary charity is fine).',
  ),
  ZakatGuideSection(
    '🌙',
    'زكاة الفطر',
    'Zakat al-Fitr',
    'صاعٌ من غالب قوت البلد (نحو 2.5 كجم) عن كل فرد فى البيت — كبيرًا كان أو '
        'صغيرًا — تُخرَج قبل صلاة عيد الفطر. ويجوز إخراجها قيمةً (نقودًا) عند '
        'بعض الفقهاء لتيسير حاجة الفقير.',
    'One sā’ of the region’s staple food (~2.5 kg) per household member — '
        'young or old — given before the Eid al-Fitr prayer. Some scholars permit '
        'paying its cash value.',
  ),
  ZakatGuideSection(
    '⚠️',
    'تنبيهات وأخطاء شائعة',
    'Notes & common mistakes',
    '• الحول شرطٌ للنقود والذهب والتجارة، وليس للزروع والثمار.\n'
        '• المقدار 2.5% (ربع العُشر) من صافى المال بعد خصم الديون الحالّة عليك.\n'
        '• إن نقص المال أثناء الحول عن النصاب ثم عاد، يُبتدأ الحول من جديد على '
        'القول المشهور.\n'
        '• الأفضل تحرّى إخراجها فى وقتها، ويجوز تعجيلها.\n\n'
        'هذا شرحٌ تعريفى مبسّط؛ ولمسائل حالتك الخاصة استفتِ أهل العلم الموثوقين.',
    '• The lunar-year condition applies to cash, gold and trade — not crops.\n'
        '• The rate is 2.5% of net wealth after deducting due debts.\n'
        '• If wealth drops below nisab mid-year then recovers, the year restarts '
        '(well-known view).\n'
        '• Pay it on time; paying early is allowed.\n\n'
        'This is a simplified overview — consult trusted scholars for your case.',
  ),
];
