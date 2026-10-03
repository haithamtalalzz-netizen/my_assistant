// الشاشات اللى اتشالت من السايدبار لازم يفضل ليها باب.
//
// أكتر عيب بيتكرّر فى التطبيق ده: ميزة مبنية ومحدش يقدر يوصلها. لمّا
// «الرياضة» و«الأكل» اتشالوا من السايدبار، تلات شاشات كان **السايدبار
// بابها الوحيد** (الأنظمة الغذائية · مخطّط الوجبات · الصيام المتقطّع).
// فاتنقلوا جوّه سطرَى «صحتى» بدل ما يتحذفوا.
//
// الاختبار ده بيقرا الكود نفسه: لو حد شال المعاملين من السايدبار، أو
// شال بند من جوّه الهَب، الشاشة تبقى موجودة ومحدش يقدر يفتحها —
// ومفيش اختبار سلوك هيلاحظ، لإن مفيش حاجة بتكسر.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final drawer = File('lib/screens/app_drawer.dart').readAsStringSync();

  test('«الرياضة» و«الأكل» مابقوش بنود فى السايدبار', () {
    // البند فى السايدبار بيتبنى بـ`push(أيقونة, اسم, شاشة, لون)`.
    expect(drawer.contains("push(\n                Icons.fitness_center"), isFalse);
    expect(
        drawer.contains("push(\n                Icons.restaurant_outlined"), isFalse);
  });

  test('بس لسه ليهم باب من «صحتى»', () {
    expect(drawer.contains('exerciseHub:'), isTrue);
    expect(drawer.contains('foodHub:'), isTrue);
  });

  test('الشاشات اللى السايدبار كان بابها الوحيد لسه مفتوحة', () {
    // الثلاثة دول لو اتشالوا من الهَب مفيش حتة تانية فى التطبيق كله
    // بتفتحهم — اتأكدنا بالبحث وقت النقل.
    for (final screen in const [
      'DietPlansScreen',
      'MealPlannerScreen',
      'FastingScreen',
      'RecipesScreen',
    ]) {
      expect(drawer.contains('const $screen()'), isTrue,
          reason: '$screen بقت من غير باب');
    }
  });

  test('مفيش شاشة جوّه الهَبّين اتسابت ورا', () {
    for (final screen in const [
      'GymScreen',
      'WalkTrackerScreen',
      'ProgressScreen',
      'ExerciseLibraryScreen',
      'WorkoutProgramsScreen',
      'FoodCardScreen',
    ]) {
      expect(drawer.contains('const $screen()'), isTrue, reason: screen);
    }
  });
}
