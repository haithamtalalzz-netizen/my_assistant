// بندَا «الرياضة» و«الأكل» اتشالوا بالكامل — الاختبار ده بيمنع رجوعهم
// بالغلط، وبيحرس اللى **لازم** يفضل.
//
// الملف ده كان بيعمل العكس بالظبط: لمّا البندين اتشالوا من السايدبار
// بس، كان بيتأكد إن شاشاتهم لسه ليها باب (تلاتة منها كان السايدبار
// بابها الوحيد). بعد ما المستخدم قرّر الحذف الكامل، بقى يتأكد إنها
// راحت — بشاشاتها ومخازنها وجداولها.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String p) => File(p).readAsStringSync();

  test('ملفات الشاشات والمخازن اتمسحت', () {
    for (final f in const [
      'lib/screens/gym/gym_screen.dart',
      'lib/screens/gym/walk_tracker_screen.dart',
      'lib/screens/gym/progress_screen.dart',
      'lib/screens/gym/exercise_library_screen.dart',
      'lib/screens/gym/workout_programs_screen.dart',
      'lib/screens/food/food_card_screen.dart',
      'lib/screens/food/diet_plans_screen.dart',
      'lib/screens/food/meal_planner_screen.dart',
      'lib/screens/food/fasting_screen.dart',
      'lib/screens/recipes_screen.dart',
      'lib/data/gym_repo.dart',
      'lib/data/body_progress_repo.dart',
      'lib/data/meal_plan_repo.dart',
      'lib/data/fasting_repo.dart',
      'lib/data/recipes_repo.dart',
      'lib/core/exercise_library.dart',
      'lib/core/workout_programs.dart',
      'lib/core/diet_plans.dart',
    ]) {
      expect(File(f).existsSync(), isFalse, reason: '$f لسه موجود');
    }
  });

  test('الجداول اتشالت من الـDDL وفيه هجرة بتمسحها', () {
    final db = read('lib/core/db.dart');
    for (final t in const [
      'gym_sessions',
      'gym_sets',
      'body_progress',
      'meal_plan',
      'if_fasts',
      'recipes',
    ]) {
      expect(db.contains('CREATE TABLE $t('), isFalse,
          reason: 'جدول $t لسه بيتعمل فى قاعدة جديدة');
      expect(db.contains("'$t',"), isTrue,
          reason: 'جدول $t مش فى قايمة الحذف — القواعد القديمة هتفضل شايلاه');
    }
    expect(db.contains('version: 69'), isTrue);
  });

  test('اللى لازم يفضل فضل', () {
    // 🔴 دول **مش** جزء من البندين، ولو اتشالوا بالغلط حاجات تانية
    // بتقع: تسجيل التمرينة بيكتب فى `activity_sessions`، وسطر «أكلت»
    // بيقرا `meals`، و«خطة التمارين» شاشة مستقلّة لسه موجودة.
    for (final f in const [
      'lib/data/activity_repo.dart',
      'lib/data/meals_repo.dart',
      'lib/data/workout_repo.dart',
      'lib/screens/food/meal_sheet.dart',
      'lib/screens/food/food_picker_sheet.dart',
      'lib/screens/food/barcode_scan_screen.dart',
      'lib/screens/workout/workout_plan_screen.dart',
      'lib/screens/health/exercise_sheet.dart',
    ]) {
      expect(File(f).existsSync(), isTrue, reason: '$f اتشال بالغلط');
    }
    final db = read('lib/core/db.dart');
    for (final t in const [
      'activity_sessions',
      'meals',
      'workout_plan',
      'workout_logs',
    ]) {
      expect(db.contains('CREATE TABLE $t('), isTrue, reason: 'جدول $t اتشال');
    }
  });

  test('مفيش بند راجع فى السايدبار', () {
    final drawer = read('lib/screens/app_drawer.dart');
    for (final name in const [
      'GymScreen',
      'FoodCardScreen',
      'DietPlansScreen',
      'MealPlannerScreen',
      'RecipesScreen',
      'exerciseHub',
      'foodHub',
    ]) {
      expect(drawer.contains(name), isFalse, reason: '$name رجع');
    }
  });
}
