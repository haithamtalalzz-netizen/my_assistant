import 'l10n.dart';

/// يوم تمرين داخل برنامج: رقم اليوم في الأسبوع (1..7) + اسمه + التمارين.
class WorkoutDay {
  final int weekday;
  final String title;
  final List<String> exercises;
  const WorkoutDay(this.weekday, this.title, this.exercises);
}

/// برنامج تمرين جاهز.
class WorkoutProgram {
  final String name;

  /// 'home' أو 'gym'.
  final String place;

  /// محتاج أجهزة/أوزان ولا لأ.
  final bool needsEquipment;

  /// مستوى: 'beginner' / 'intermediate' / 'advanced'.
  final String level;
  final List<WorkoutDay> days;

  const WorkoutProgram({
    required this.name,
    required this.place,
    required this.needsEquipment,
    required this.level,
    required this.days,
  });

  /// الخطة الأسبوعية (يوم→اسم) للكتابة في workout_plan.
  Map<int, String> get weeklyPlan => {for (final d in days) d.weekday: d.title};
}

String placeLabel(String p) =>
    p == 'home' ? tr('البيت', 'Home') : tr('الجيم', 'Gym');

String levelLabel(String l) => switch (l) {
      'beginner' => tr('مبتدئ', 'Beginner'),
      'intermediate' => tr('متوسط', 'Intermediate'),
      'advanced' => tr('متقدم', 'Advanced'),
      _ => l,
    };

/// مكتبة برامج جاهزة — بيت/جيم، بأجهزة أو من غير.
const List<WorkoutProgram> kWorkoutPrograms = [
  // ---- البيت بدون أجهزة ----
  WorkoutProgram(
    name: 'بيت مبتدئ — وزن الجسم',
    place: 'home',
    needsEquipment: false,
    level: 'beginner',
    days: [
      WorkoutDay(6, 'كامل الجسم أ',
          ['قرفصاء (سكوات)', 'ضغط على الركب', 'بلانك ٣٠ث', 'جسر الحوض']),
      WorkoutDay(1, 'كامل الجسم ب',
          ['اندفاع (لانجز)', 'ضغط مائل على الحيطة', 'سوبرمان', 'بطن كرنش']),
      WorkoutDay(3, 'كامل الجسم ج',
          ['قرفصاء وقوف من كرسي', 'ضغط عادي', 'بلانك جانبي', 'رفع رجل']),
    ],
  ),
  WorkoutProgram(
    name: 'بيت متوسط — علوي/سفلي',
    place: 'home',
    needsEquipment: false,
    level: 'intermediate',
    days: [
      WorkoutDay(6, 'علوي',
          ['ضغط عادي', 'ضغط ماسي', 'غطس على كرسي', 'بلانك دفع']),
      WorkoutDay(7, 'سفلي',
          ['قرفصاء بلغاري', 'اندفاع مشي', 'قرفصاء قفز', 'سمانة وقوف']),
      WorkoutDay(2, 'علوي',
          ['ضغط واسع', 'ضغط بايك', 'سحب مناشف', 'بطن دراجة']),
      WorkoutDay(3, 'سفلي',
          ['قرفصاء ثابت', 'جسر رجل واحدة', 'اندفاع جانبي', 'بلانك']),
    ],
  ),
  WorkoutProgram(
    name: 'كارديو حرق دهون (بيت)',
    place: 'home',
    needsEquipment: false,
    level: 'beginner',
    days: [
      WorkoutDay(6, 'كارديو HIIT',
          ['جري مكان', 'بربي', 'تسلق الجبل', 'قفز نجمة']),
      WorkoutDay(1, 'كارديو خفيف', ['مشي سريع ٣٠د', 'قفز حبل', 'بطن']),
      WorkoutDay(3, 'كارديو HIIT',
          ['بربي', 'قفز قرفصاء', 'ركل خلفي', 'بلانك جاك']),
      WorkoutDay(5, 'كارديو خفيف', ['مشي/جري ٣٠د', 'إطالة']),
    ],
  ),

  // ---- البيت بأجهزة بسيطة (دمبل/مطاط) ----
  WorkoutProgram(
    name: 'بيت بالدمبل — ٣ أيام',
    place: 'home',
    needsEquipment: true,
    level: 'intermediate',
    days: [
      WorkoutDay(6, 'دفع (دمبل)',
          ['بنش دمبل أرضي', 'كتف أمامي', 'ترايسبس تمديد', 'ضغط']),
      WorkoutDay(1, 'سحب (دمبل)',
          ['تجديف دمبل', 'رفرفة خلفي', 'بايسبس دمبل', 'رفعة ميتة دمبل']),
      WorkoutDay(3, 'أرجل (دمبل)',
          ['قرفصاء دمبل', 'اندفاع دمبل', 'رفعة رومانية', 'سمانة']),
    ],
  ),
  WorkoutProgram(
    name: 'بيت بالمطاط — كامل الجسم',
    place: 'home',
    needsEquipment: true,
    level: 'beginner',
    days: [
      WorkoutDay(6, 'كامل الجسم',
          ['ضغط مطاط', 'تجديف مطاط', 'قرفصاء مطاط', 'كتف مطاط']),
      WorkoutDay(2, 'كامل الجسم',
          ['بنش مطاط', 'سحب لأسفل', 'اندفاع مطاط', 'بايسبس مطاط']),
      WorkoutDay(4, 'كامل الجسم',
          ['فتح صدر', 'رفعة ميتة مطاط', 'قرفصاء', 'بطن']),
    ],
  ),

  // ---- الجيم ----
  WorkoutProgram(
    name: 'جيم — فل بودي مبتدئ',
    place: 'gym',
    needsEquipment: true,
    level: 'beginner',
    days: [
      WorkoutDay(6, 'فل بودي',
          ['قرفصاء باربل', 'بنش برس', 'تجديف', 'كتف ضغط', 'بطن']),
      WorkoutDay(1, 'فل بودي',
          ['رفعة ميتة', 'ضغط علوي', 'سحب أرضي', 'قرفصاء أمامي']),
      WorkoutDay(3, 'فل بودي',
          ['هاك سكوات', 'بنش مايل', 'عقلة', 'رفرفة جانبي']),
    ],
  ),
  WorkoutProgram(
    name: 'جيم — علوي/سفلي (٤ أيام)',
    place: 'gym',
    needsEquipment: true,
    level: 'intermediate',
    days: [
      WorkoutDay(6, 'علوي',
          ['بنش برس', 'تجديف باربل', 'كتف ضغط', 'بايسبس', 'ترايسبس']),
      WorkoutDay(7, 'سفلي',
          ['قرفصاء', 'رفعة رومانية', 'دفع أرجل', 'سمانة', 'بطن']),
      WorkoutDay(2, 'علوي',
          ['بنش مايل', 'عقلة', 'رفرفة جانبي', 'تفتيح', 'ترايسبس حبل']),
      WorkoutDay(3, 'سفلي',
          ['رفعة ميتة', 'هاك سكوات', 'مارس رجل خلفي', 'سمانة جالس']),
    ],
  ),
  WorkoutProgram(
    name: 'جيم — دفع/سحب/أرجل (PPL)',
    place: 'gym',
    needsEquipment: true,
    level: 'advanced',
    days: [
      WorkoutDay(6, 'دفع',
          ['بنش برس', 'كتف ضغط', 'بنش مايل', 'رفرفة جانبي', 'ترايسبس']),
      WorkoutDay(7, 'سحب',
          ['رفعة ميتة', 'عقلة', 'تجديف', 'سحب وجه', 'بايسبس']),
      WorkoutDay(1, 'أرجل',
          ['قرفصاء', 'دفع أرجل', 'رفعة رومانية', 'سمانة', 'بطن']),
      WorkoutDay(3, 'دفع',
          ['بنش مايل', 'كتف دمبل', 'تفتيح', 'ترايسبس حبل']),
      WorkoutDay(4, 'سحب', ['تجديف باربل', 'سحب علوي', 'رفرفة خلفي', 'بايسبس']),
      WorkoutDay(5, 'أرجل', ['هاك سكوات', 'مارس رجل', 'اندفاع', 'سمانة']),
    ],
  ),
  WorkoutProgram(
    name: 'جيم — تقسيمة العضلات (٥ أيام)',
    place: 'gym',
    needsEquipment: true,
    level: 'advanced',
    days: [
      WorkoutDay(6, 'صدر',
          ['بنش برس', 'بنش مايل', 'تفتيح', 'ضغط متوازي']),
      WorkoutDay(7, 'ظهر',
          ['رفعة ميتة', 'عقلة', 'تجديف', 'سحب أرضي']),
      WorkoutDay(1, 'رجل',
          ['قرفصاء', 'دفع أرجل', 'رفعة رومانية', 'سمانة']),
      WorkoutDay(3, 'كتف',
          ['كتف ضغط', 'رفرفة جانبي', 'رفرفة أمامي', 'سحب وجه']),
      WorkoutDay(4, 'ذراع',
          ['بايسبس باربل', 'ترايسبس حبل', 'مطرقة', 'ترايسبس فوق الراس']),
    ],
  ),
];
