import 'l10n.dart';

/// كل عناصر الصفحة الرئيسية اللي المستخدم يقدر يظهرها/يخفيها من الإعدادات.
/// المفاتيح ثابتة (بتتخزن)، والعرض بيستخدم [homeSectionLabel].
const List<String> kHomeSectionKeys = [
  'quick_actions',
  'prayer',
  'summary',
  'cycle',
  'vitals',
  'smartwatch',
  'bills',
  'docs_expiry',
  'appointments',
  'meds',
  'workout',
  'meals',
  'habits',
  'money',
];

String homeSectionLabel(String key) => switch (key) {
      'quick_actions' => tr('أزرار الإضافة السريعة', 'Quick-add buttons'),
      'prayer' => tr('كارت مواعيد الصلاة', 'Prayer times card'),
      'summary' => tr('ملخص المدير', 'Manager summary'),
      'cycle' => tr('كارت الدورة الشهرية', 'Cycle card'),
      'vitals' => tr('الخطوات', 'Steps'),
      'smartwatch' => tr('من الساعة الذكية', 'From smartwatch'),
      'bills' => tr('الفواتير المستحقة', 'Bills due'),
      'docs_expiry' => tr('مستندات محتاجة تجديد', 'Documents to renew'),
      'appointments' => tr('مواعيد النهارده', "Today's appointments"),
      'meds' => tr('أدوية النهارده', "Today's medications"),
      'workout' => tr('التمرين', 'Workout'),
      'meals' => tr('وجبات النهارده', "Today's meals"),
      'habits' => tr('عادات النهارده', "Today's habits"),
      'money' => tr('فلوس النهارده', "Today's money"),
      _ => key,
    };
