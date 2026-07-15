import 'l10n.dart';

/// كل عناصر الصفحة الرئيسية اللي المستخدم يقدر يظهرها/يخفيها من الإعدادات.
/// المفاتيح ثابتة (بتتخزن)، والعرض بيستخدم [homeSectionLabel].
const List<String> kHomeSectionKeys = [
  'attention',
  'glance',
  'quick_actions',
  'prayer',
  'summary',
  'week',
  'dashboard',
  'cycle',
  'vitals',
  'smartwatch',
  'bills',
  'docs_expiry',
  'appointments',
  'meds',
  'meals',
  'habits',
];

String homeSectionLabel(String key) => switch (key) {
      'attention' => tr('شريط «محتاج منك دلوقتي»', '"Needs you now" strip'),
      'glance' => tr('يومك فى سطر (حلقات التقدّم)', 'Day at a glance (rings)'),
      'quick_actions' => tr('أزرار الإضافة السريعة', 'Quick-add buttons'),
      'prayer' => tr('كارت مواعيد الصلاة', 'Prayer times card'),
      'summary' => tr('ملخص المدير', 'Manager summary'),
      'week' => tr('نظرة الأسبوع', 'Week ahead'),
      'dashboard' => tr('كروت الأقسام', 'Section cards'),
      'cycle' => tr('كارت الدورة الشهرية', 'Cycle card'),
      'vitals' => tr('الخطوات', 'Steps'),
      'smartwatch' => tr('من الساعة الذكية', 'From smartwatch'),
      'bills' => tr('الفواتير المستحقة', 'Bills due'),
      'docs_expiry' => tr('مستندات محتاجة تجديد', 'Documents to renew'),
      'appointments' => tr('مواعيد النهارده', "Today's appointments"),
      'meds' => tr('أدوية النهارده', "Today's medications"),
      'meals' => tr('وجبات النهارده', "Today's meals"),
      'habits' => tr('عادات النهارده', "Today's habits"),
      _ => key,
    };
