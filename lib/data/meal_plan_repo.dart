import 'package:sqflite/sqflite.dart';

import '../core/db.dart';

/// مخطّط الوجبات الأسبوعى — نص لكل (يوم الأسبوع، خانة الوجبة).
class MealPlanRepo {
  /// كل الخطة كـ map: "weekday|slot" → text.
  Future<Map<String, String>> weekMap() async {
    final db = await AppDb.instance;
    final rows = await db.query('meal_plan');
    return {
      for (final r in rows)
        '${r['weekday']}|${r['slot']}': r['text'] as String,
    };
  }

  Future<void> setItem(int weekday, String slot, String text) async {
    final db = await AppDb.instance;
    if (text.trim().isEmpty) {
      await db.delete('meal_plan',
          where: 'weekday = ? AND slot = ?', whereArgs: [weekday, slot]);
      return;
    }
    await db.insert(
        'meal_plan', {'weekday': weekday, 'slot': slot, 'text': text.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// كل نصوص الخطة (للإضافة لقائمة التسوق).
  Future<List<String>> allTexts() async {
    final db = await AppDb.instance;
    final rows = await db.query('meal_plan');
    return [
      for (final r in rows)
        if ((r['text'] as String).trim().isNotEmpty) r['text'] as String
    ];
  }
}
