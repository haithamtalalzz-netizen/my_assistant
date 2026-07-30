// حسابات صحية نقية قابلة للاختبار: مؤشر كتلة الجسم (BMI) ومعدّل الأيض
// الأساسى (BMR) بمعادلة Mifflin-St Jeor. كله حساب على الجهاز، بلا أى API.

/// مؤشر كتلة الجسم = الوزن (كجم) ÷ مربّع الطول (متر).
double bmi(double weightKg, double heightCm) {
  if (heightCm <= 0) return 0;
  final m = heightCm / 100.0;
  return weightKg / (m * m);
}

/// تصنيف الـBMI (منظمة الصحة العالمية).
String bmiCategoryAr(double v) {
  if (v <= 0) return '—';
  if (v < 18.5) return 'نقص وزن';
  if (v < 25) return 'وزن طبيعى';
  if (v < 30) return 'زيادة وزن';
  return 'سمنة';
}

String bmiCategoryEn(double v) {
  if (v <= 0) return '—';
  if (v < 18.5) return 'Underweight';
  if (v < 25) return 'Normal';
  if (v < 30) return 'Overweight';
  return 'Obese';
}

/// معدّل الأيض الأساسى (سعرات/يوم) — Mifflin-St Jeor.
/// ذكر: 10·كجم + 6.25·سم − 5·العمر + 5 · أنثى: نفسها − 161.
double bmrMifflin({
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required bool isMale,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
  return base + (isMale ? 5 : -161);
}

/// معاملات النشاط البدنى لحساب إجمالى الطاقة اليومية (TDEE = BMR × المعامل).
const Map<String, double> kActivityFactors = {
  'sedentary': 1.2,
  'light': 1.375,
  'moderate': 1.55,
  'active': 1.725,
  'very': 1.9,
};

const List<String> kActivityLevels = [
  'sedentary',
  'light',
  'moderate',
  'active',
  'very',
];

/// إجمالى الطاقة المطلوبة يوميًا (TDEE) بحسب مستوى النشاط.
double tdee({required double bmr, required String activity}) =>
    bmr * (kActivityFactors[activity] ?? 1.2);

String activityLabelAr(String key) => switch (key) {
      'sedentary' => 'خامل (مكتبى)',
      'light' => 'نشاط خفيف',
      'moderate' => 'نشاط متوسط',
      'active' => 'نشيط',
      'very' => 'نشيط جدًا',
      _ => key,
    };

String activityLabelEn(String key) => switch (key) {
      'sedentary' => 'Sedentary',
      'light' => 'Light',
      'moderate' => 'Moderate',
      'active' => 'Active',
      'very' => 'Very active',
      _ => key,
    };
