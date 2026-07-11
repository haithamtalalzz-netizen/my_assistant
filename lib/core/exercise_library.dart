import 'app_state.dart';
import 'l10n.dart';

/// تمرين مفرد في المكتبة — مع طريقة الأداء والعضلة والمعدّات.
class Exercise {
  final String ar;
  final String en;

  /// مفتاح العضلة المستهدفة (من [kMuscles]).
  final String muscle;

  /// مفتاح المعدّات (من [kEquipment]).
  final String equipment;

  /// طريقة الأداء (سطر مختصر).
  final String howToAr;
  final String howToEn;

  /// اقتراح المجموعات والتكرارات.
  final String reps;

  const Exercise(
    this.ar,
    this.en, {
    required this.muscle,
    required this.equipment,
    required this.howToAr,
    required this.howToEn,
    this.reps = '3 × 12',
  });

  String get name => AppState.isEnglish ? en : ar;
  String get howTo => AppState.isEnglish ? howToEn : howToAr;
}

// ---- العضلات ----
const String mChest = 'chest';
const String mBack = 'back';
const String mLegs = 'legs';
const String mShoulders = 'shoulders';
const String mArms = 'arms';
const String mCore = 'core';
const String mGlutes = 'glutes';
const String mCardio = 'cardio';

const List<String> kMuscles = [
  mChest,
  mBack,
  mLegs,
  mGlutes,
  mShoulders,
  mArms,
  mCore,
  mCardio,
];

String muscleLabel(String m) => switch (m) {
      mChest => tr('صدر', 'Chest'),
      mBack => tr('ظهر', 'Back'),
      mLegs => tr('أرجل', 'Legs'),
      mGlutes => tr('مؤخرة', 'Glutes'),
      mShoulders => tr('أكتاف', 'Shoulders'),
      mArms => tr('ذراعين', 'Arms'),
      mCore => tr('بطن', 'Core'),
      mCardio => tr('كارديو', 'Cardio'),
      _ => m,
    };

String muscleEmoji(String m) => switch (m) {
      mChest => '💪',
      mBack => '🔙',
      mLegs => '🦵',
      mGlutes => '🍑',
      mShoulders => '🙆',
      mArms => '💪',
      mCore => '🎯',
      mCardio => '🏃',
      _ => '🏋️',
    };

// ---- المعدّات ----
const String eBody = 'bodyweight';
const String eDumbbell = 'dumbbell';
const String eBarbell = 'barbell';
const String eMachine = 'machine';
const String eBand = 'band';

const List<String> kEquipment = [eBody, eDumbbell, eBarbell, eMachine, eBand];

String equipmentLabel(String e) => switch (e) {
      eBody => tr('وزن الجسم', 'Bodyweight'),
      eDumbbell => tr('دمبل', 'Dumbbell'),
      eBarbell => tr('بار', 'Barbell'),
      eMachine => tr('جهاز', 'Machine'),
      eBand => tr('أستك مقاومة', 'Band'),
      _ => e,
    };

bool equipmentNeedsGear(String e) => e != eBody;

/// مكتبة تمارين شاملة — بوزن الجسم وبالأجهزة والمعدّات، مقسّمة بالعضلات.
const List<Exercise> kExercises = [
  // ===== صدر =====
  Exercise('ضغط (بوش أب)', 'Push-up',
      muscle: mChest, equipment: eBody,
      howToAr: 'إيدك أوسع من كتفك، نزّل صدرك للأرض وارفع مع شد البطن.',
      howToEn: 'Hands wider than shoulders, lower chest to floor, push up with tight core.',
      reps: '3 × 12-20'),
  Exercise('ضغط ماسي', 'Diamond push-up',
      muscle: mChest, equipment: eBody,
      howToAr: 'خلي إيديك تحت صدرك على شكل معيّن — بيركّز على التراي والصدر الداخلي.',
      howToEn: 'Hands under chest forming a diamond — hits triceps and inner chest.',
      reps: '3 × 10-15'),
  Exercise('بنش برس بار', 'Barbell bench press',
      muscle: mChest, equipment: eBarbell,
      howToAr: 'استلقِ على البنش، نزّل البار لمنتصف صدرك وادفع لأعلى.',
      howToEn: 'Lie on bench, lower bar to mid-chest, press up.',
      reps: '4 × 8-12'),
  Exercise('بنش برس دمبل', 'Dumbbell bench press',
      muscle: mChest, equipment: eDumbbell,
      howToAr: 'دمبل في كل إيد فوق صدرك، نزّل بتحكّم وادفع لأعلى.',
      howToEn: 'A dumbbell in each hand over chest, lower with control and press.',
      reps: '4 × 10-12'),
  Exercise('تفتيح دمبل', 'Dumbbell fly',
      muscle: mChest, equipment: eDumbbell,
      howToAr: 'افرد ذراعيك في قوس واسع لجانبك وارجعهم فوق صدرك.',
      howToEn: 'Open arms in a wide arc to the sides, bring back over chest.',
      reps: '3 × 12'),
  Exercise('بنش مائل جهاز', 'Incline chest press machine',
      muscle: mChest, equipment: eMachine,
      howToAr: 'اضبط الكرسي، ادفع المقابض لقدّام لحد فرد الذراعين.',
      howToEn: 'Set the seat, push the handles forward until arms extend.',
      reps: '4 × 10-12'),

  // ===== ظهر =====
  Exercise('عقلة (بول أب)', 'Pull-up',
      muscle: mBack, equipment: eBody,
      howToAr: 'امسك البار وارفع نفسك لحد ما دقنك يعدّي البار.',
      howToEn: 'Grab the bar and pull yourself up until chin passes the bar.',
      reps: '3 × 6-12'),
  Exercise('تجديف بار', 'Barbell row',
      muscle: mBack, equipment: eBarbell,
      howToAr: 'انحنِ من وسطك، اسحب البار لبطنك واعصر لوح الكتف.',
      howToEn: 'Hinge at hips, pull bar to belly, squeeze shoulder blades.',
      reps: '4 × 8-12'),
  Exercise('تجديف دمبل', 'Dumbbell row',
      muscle: mBack, equipment: eDumbbell,
      howToAr: 'ركبة وإيد على البنش، اسحب الدمبل لجنبك.',
      howToEn: 'Knee and hand on bench, pull dumbbell to your side.',
      reps: '3 × 10-12'),
  Exercise('سحب أمامي (لات بول)', 'Lat pulldown',
      muscle: mBack, equipment: eMachine,
      howToAr: 'اسحب البار لأعلى صدرك وأنت قاعد، وارجعه ببطء.',
      howToEn: 'Pull the bar to upper chest while seated, return slowly.',
      reps: '4 × 10-12'),
  Exercise('تجديف أستك', 'Band row',
      muscle: mBack, equipment: eBand,
      howToAr: 'ثبّت الأستك، اسحبه لبطنك مع شد لوح الكتف.',
      howToEn: 'Anchor the band, pull to belly squeezing shoulder blades.',
      reps: '3 × 15'),
  Exercise('سوبرمان', 'Superman',
      muscle: mBack, equipment: eBody,
      howToAr: 'نايم على بطنك، ارفع إيديك ورجليك مع بعض واعصر ظهرك.',
      howToEn: 'Lie face-down, raise arms and legs together, squeeze back.',
      reps: '3 × 15'),

  // ===== أرجل =====
  Exercise('قرفصاء (سكوات)', 'Bodyweight squat',
      muscle: mLegs, equipment: eBody,
      howToAr: 'رجلك بعرض الكتف، انزل كأنك بتقعد على كرسي وارجع.',
      howToEn: 'Feet shoulder-width, sit back like onto a chair, stand up.',
      reps: '3 × 15-20'),
  Exercise('اندفاع (لانجز)', 'Lunges',
      muscle: mLegs, equipment: eBody,
      howToAr: 'اخطُ خطوة لقدّام وانزل لحد ما ركبتك توصل قريب للأرض.',
      howToEn: 'Step forward and lower until the back knee nears the floor.',
      reps: '3 × 12 لكل رجل'),
  Exercise('سكوات بار', 'Barbell squat',
      muscle: mLegs, equipment: eBarbell,
      howToAr: 'البار على كتفك، انزل بظهر مفرود لحد ما فخذك يوازي الأرض.',
      howToEn: 'Bar on shoulders, descend with flat back until thighs parallel.',
      reps: '4 × 8-12'),
  Exercise('دفع أرجل جهاز', 'Leg press',
      muscle: mLegs, equipment: eMachine,
      howToAr: 'ادفع المنصّة برجلك لحد فرد الركبة من غير قفل.',
      howToEn: 'Push the platform with your legs until knees extend (no lock).',
      reps: '4 × 12'),
  Exercise('سمانة وقوف', 'Standing calf raise',
      muscle: mLegs, equipment: eBody,
      howToAr: 'قف وارفع كعبك لأعلى مسافة كاملة واعصر السمانة.',
      howToEn: 'Stand and raise heels fully, squeeze the calves.',
      reps: '4 × 20'),
  Exercise('قرفصاء بلغاري', 'Bulgarian split squat',
      muscle: mLegs, equipment: eDumbbell,
      howToAr: 'رجل خلفك على كرسي، انزل بالرجل الأمامية.',
      howToEn: 'Rear foot on a bench, lower on the front leg.',
      reps: '3 × 10 لكل رجل'),

  // ===== مؤخرة =====
  Exercise('جسر الحوض', 'Glute bridge',
      muscle: mGlutes, equipment: eBody,
      howToAr: 'نايم على ضهرك، ارفع حوضك لأعلى واعصر المؤخرة.',
      howToEn: 'Lie on back, lift hips up, squeeze glutes at top.',
      reps: '3 × 15-20'),
  Exercise('رفعة ميتة رومانية', 'Romanian deadlift',
      muscle: mGlutes, equipment: eBarbell,
      howToAr: 'نزّل البار على طول رجلك بظهر مفرود لحد ما تحس بشد الخلفية.',
      howToEn: 'Lower the bar along legs with flat back until hamstrings stretch.',
      reps: '4 × 10'),
  Exercise('ركلة مؤخرة أستك', 'Band kickback',
      muscle: mGlutes, equipment: eBand,
      howToAr: 'الأستك حوالين كاحلك، اركل رجلك للخلف واعصر.',
      howToEn: 'Band around ankle, kick leg back and squeeze.',
      reps: '3 × 15 لكل رجل'),

  // ===== أكتاف =====
  Exercise('ضغط كتف دمبل', 'Dumbbell shoulder press',
      muscle: mShoulders, equipment: eDumbbell,
      howToAr: 'ادفع الدمبل من مستوى كتفك لفوق راسك.',
      howToEn: 'Press dumbbells from shoulder level up overhead.',
      reps: '4 × 10-12'),
  Exercise('رفرفة جانبي', 'Lateral raise',
      muscle: mShoulders, equipment: eDumbbell,
      howToAr: 'ارفع الدمبل لجانبك لحد مستوى الكتف وأنزل ببطء.',
      howToEn: 'Raise dumbbells out to the sides to shoulder height, lower slowly.',
      reps: '3 × 15'),
  Exercise('ضغط بايك', 'Pike push-up',
      muscle: mShoulders, equipment: eBody,
      howToAr: 'اعمل شكل V مقلوب ونزّل راسك ناحية الأرض بين إيديك.',
      howToEn: 'Make an inverted V, lower your head toward the floor between hands.',
      reps: '3 × 10'),
  Exercise('ضغط كتف بار', 'Overhead barbell press',
      muscle: mShoulders, equipment: eBarbell,
      howToAr: 'ادفع البار من صدرك لفوق راسك واقف.',
      howToEn: 'Press the bar from chest to overhead while standing.',
      reps: '4 × 8-10'),

  // ===== ذراعين =====
  Exercise('مرجحة بايسبس دمبل', 'Dumbbell curl',
      muscle: mArms, equipment: eDumbbell,
      howToAr: 'اثنِ الكوع وارفع الدمبل ناحية كتفك واعصر البايسبس.',
      howToEn: 'Bend the elbow and curl the dumbbell to your shoulder.',
      reps: '3 × 12'),
  Exercise('غطس تراي على كرسي', 'Bench dip',
      muscle: mArms, equipment: eBody,
      howToAr: 'إيدك على كرسي خلفك، انزل بجسمك واثنِ الكوع وارفع.',
      howToEn: 'Hands on a bench behind you, lower body bending elbows, push up.',
      reps: '3 × 12-15'),
  Exercise('تراي بار', 'Skull crusher',
      muscle: mArms, equipment: eBarbell,
      howToAr: 'نايم، نزّل البار ناحية جبهتك بثني الكوع بس.',
      howToEn: 'Lying down, lower the bar toward forehead bending only elbows.',
      reps: '3 × 10-12'),
  Exercise('بايسبس أستك', 'Band curl',
      muscle: mArms, equipment: eBand,
      howToAr: 'قف على الأستك واثنِ ذراعك لأعلى ضد المقاومة.',
      howToEn: 'Stand on the band and curl arms up against resistance.',
      reps: '3 × 15'),

  // ===== بطن =====
  Exercise('بلانك', 'Plank',
      muscle: mCore, equipment: eBody,
      howToAr: 'ارتكز على ساعديك وأصابع رجلك وخلي جسمك خط مستقيم.',
      howToEn: 'Rest on forearms and toes, keep body in a straight line.',
      reps: '3 × 30-60ث'),
  Exercise('كرنش', 'Crunch',
      muscle: mCore, equipment: eBody,
      howToAr: 'نايم وركبك مثنية، ارفع كتفك ناحية ركبك واعصر البطن.',
      howToEn: 'Lie with knees bent, lift shoulders toward knees, squeeze abs.',
      reps: '3 × 20'),
  Exercise('رفع رجل', 'Leg raise',
      muscle: mCore, equipment: eBody,
      howToAr: 'نايم، ارفع رجليك لأعلى مفرودين وأنزلهم ببطء من غير ما يلمسوا الأرض.',
      howToEn: 'Lie down, raise straight legs up and lower slowly without touching floor.',
      reps: '3 × 15'),
  Exercise('دراجة بطن', 'Bicycle crunch',
      muscle: mCore, equipment: eBody,
      howToAr: 'لمس الكوع بالركبة المعاكسة بالتبادل زي الدرّاجة.',
      howToEn: 'Touch elbow to opposite knee alternately, like cycling.',
      reps: '3 × 20'),
  Exercise('بلانك جانبي', 'Side plank',
      muscle: mCore, equipment: eBody,
      howToAr: 'ارتكز على ساعد واحد وجنبك، ارفع حوضك وثبّت.',
      howToEn: 'Rest on one forearm on your side, lift hips and hold.',
      reps: '3 × 30ث لكل جنب'),

  // ===== كارديو =====
  Exercise('نط الحبل', 'Jump rope',
      muscle: mCardio, equipment: eBody,
      howToAr: 'نطّ بإيقاع ثابت مع تحريك رسغك — كارديو حرق عالي.',
      howToEn: 'Jump at a steady rhythm using your wrists — high-burn cardio.',
      reps: '5 × 1 دقيقة'),
  Exercise('جري في المكان', 'High knees',
      muscle: mCardio, equipment: eBody,
      howToAr: 'اجرِ في مكانك مع رفع ركبك لأعلى مستوى ممكن.',
      howToEn: 'Run in place raising knees as high as possible.',
      reps: '4 × 45ث'),
  Exercise('بربي', 'Burpee',
      muscle: mCardio, equipment: eBody,
      howToAr: 'قرفصاء → ضغط → قفزة لأعلى، تكرار سريع.',
      howToEn: 'Squat → push-up → jump up, repeat fast.',
      reps: '4 × 10'),
  Exercise('تسلق الجبل', 'Mountain climbers',
      muscle: mCardio, equipment: eBody,
      howToAr: 'وضع الضغط، بدّل ركبك ناحية صدرك بسرعة.',
      howToEn: 'Push-up position, drive knees to chest alternately, fast.',
      reps: '4 × 40ث'),
];

/// بحث/فلترة في مكتبة التمارين.
List<Exercise> filterExercises({String muscle = 'all', String equipment = 'all'}) {
  return kExercises.where((e) {
    if (muscle != 'all' && e.muscle != muscle) return false;
    if (equipment == 'none' && equipmentNeedsGear(e.equipment)) return false;
    if (equipment != 'all' &&
        equipment != 'none' &&
        e.equipment != equipment) {
      return false;
    }
    return true;
  }).toList();
}
