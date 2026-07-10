import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kMealSlots = ['فطار', 'غدا', 'عشا', 'سناك'];
const List<String> kRamadanMealSlots = ['سحور', 'فطار', 'سناك'];

/// عرض نوع الوجبة بالإنجليزي مع إبقاء القيمة المخزّنة عربي.
String mealSlotLabel(String s) => switch (s) {
      'فطار' => tr('فطار', 'Breakfast'),
      'غدا' => tr('غدا', 'Lunch'),
      'عشا' => tr('عشا', 'Dinner'),
      'سناك' => tr('سناك', 'Snack'),
      'سحور' => tr('سحور', 'Suhoor'),
      _ => s,
    };

class MealsRepo {
  Future<List<Meal>> forDay(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('meals', where: 'day = ?', whereArgs: [day], orderBy: 'id');
    return rows.map(Meal.fromMap).toList();
  }

  Future<int> add(Meal meal) async {
    final db = await AppDb.instance;
    return db.insert('meals', meal.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  // ---- قائمة التسوق ----

  Future<List<ShoppingItem>> shoppingItems() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('shopping_items', orderBy: 'checked, id DESC');
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<int> addShoppingItem(String name) async {
    final db = await AppDb.instance;
    return db.insert('shopping_items', ShoppingItem(
      name: name,
      createdAt: DateTime.now().toIso8601String(),
    ).toMap());
  }

  Future<void> setChecked(int id, bool checked) async {
    final db = await AppDb.instance;
    await db.update('shopping_items', {'checked': checked ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteShoppingItem(int id) async {
    final db = await AppDb.instance;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearChecked() async {
    final db = await AppDb.instance;
    await db.delete('shopping_items', where: 'checked = 1');
  }
}
