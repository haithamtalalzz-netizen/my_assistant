import '../core/db.dart';
import '../models/models.dart';
import 'meals_repo.dart';

class RecipesRepo {
  Future<int> save(Recipe r) async {
    final db = await AppDb.instance;
    if (r.id == null) return db.insert('recipes', r.toMap());
    await db.update('recipes', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
    return r.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('recipes', orderBy: 'name');
    return rows.map(Recipe.fromMap).toList();
  }

  /// يضيف مقادير الوصفة لقائمة التسوق.
  Future<int> addIngredientsToShopping(Recipe r) async {
    final meals = MealsRepo();
    var added = 0;
    for (final ing in r.ingredientList) {
      await meals.addShoppingItem(ing);
      added++;
    }
    return added;
  }
}
