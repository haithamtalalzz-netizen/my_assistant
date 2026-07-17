import '../core/db.dart';
import '../core/food_db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kMealSlots = ['فطار', 'غدا', 'عشا', 'سناك'];

/// تصنيفات أصناف التسوق.
const List<String> kShoppingCategories = [
  'خضار وفاكهة',
  'بقالة',
  'لحوم',
  'ألبان',
  'منظفات',
  'أخرى',
];

String shoppingCategoryLabel(String c) => switch (c) {
      'خضار وفاكهة' => tr('خضار وفاكهة', 'Produce'),
      'بقالة' => tr('بقالة', 'Grocery'),
      'لحوم' => tr('لحوم', 'Meat'),
      'ألبان' => tr('ألبان', 'Dairy'),
      'منظفات' => tr('منظفات', 'Cleaning'),
      'أخرى' => tr('أخرى', 'Other'),
      _ => c,
    };
/// يرتّب تصنيفات التسوق حسب ترتيب المستخدم المحفوظ (ممرات السوبرماركت
/// بتاعه)، وبيضيف أى تصنيف جديد مش موجود فى الترتيب فى آخره — فمفيش تصنيف
/// بيختفى. طبقة نقية عشان تتختبر.
List<String> orderedShoppingCategories(List<String> savedOrder) {
  final valid = [for (final c in savedOrder) if (kShoppingCategories.contains(c)) c];
  final rest = [for (final c in kShoppingCategories) if (!valid.contains(c)) c];
  return [...valid, ...rest];
}

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
  /// الوجبات الأكتر تسجيلاً (آخر نسخة من كل وصف بقيمها) — للمفضّلة.
  Future<List<Meal>> frequentMeals({int limit = 8}) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery("""
      SELECT m.* FROM meals m
      JOIN (SELECT description, COUNT(*) c, MAX(id) mid FROM meals
            GROUP BY description ORDER BY c DESC, mid DESC LIMIT ?) f
        ON m.id = f.mid
      ORDER BY f.c DESC
    """, [limit]);
    return rows.map(Meal.fromMap).toList();
  }

  /// آخر وجبة اتسجّلت (لزرار «سجّل تانى»).
  Future<Meal?> lastMeal() async {
    final db = await AppDb.instance;
    final rows = await db.query('meals', orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : Meal.fromMap(rows.first);
  }

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

  /// إجمالي القيم الغذائية ليوم (سعرات + بروتين + كارب + دهون).
  Future<Nutrients> dayNutrients(String day) async {
    final meals = await forDay(day);
    var total = const Nutrients();
    for (final m in meals) {
      total = total +
          Nutrients(
            kcal: m.calories ?? 0,
            protein: m.protein ?? 0,
            carbs: m.carbs ?? 0,
            fat: m.fat ?? 0,
          );
    }
    return total;
  }

  // ---- قائمة التسوق ----

  Future<List<ShoppingItem>> shoppingItems() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('shopping_items', orderBy: 'checked, id DESC');
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<int> addShoppingItem(String name,
      {String category = '', double price = 0}) async {
    final db = await AppDb.instance;
    return db.insert(
        'shopping_items',
        ShoppingItem(
          name: name,
          category: category,
          price: price,
          createdAt: DateTime.now().toIso8601String(),
        ).toMap());
  }

  Future<void> updateShoppingItem(int id,
      {String? name, String? category, double? price}) async {
    final db = await AppDb.instance;
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (category != null) data['category'] = category;
    if (price != null) data['price'] = price;
    if (data.isEmpty) return;
    await db.update('shopping_items', data, where: 'id = ?', whereArgs: [id]);
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

  /// إجمالي أسعار العناصر اللى لسه ماتشالتش.
  Future<double> shoppingTotal() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(price),0) t FROM shopping_items WHERE checked = 0');
    return (r.first['t'] as num).toDouble();
  }

  // ---- الأساسيات المتكررة ----

  Future<List<ShoppingStaple>> staples() async {
    final db = await AppDb.instance;
    final rows = await db.query('shopping_staples', orderBy: 'category, name');
    return rows.map(ShoppingStaple.fromMap).toList();
  }

  Future<void> addStaple(String name, {String category = ''}) async {
    final db = await AppDb.instance;
    await db.insert('shopping_staples', {
      'name': name,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteStaple(int id) async {
    final db = await AppDb.instance;
    await db.delete('shopping_staples', where: 'id = ?', whereArgs: [id]);
  }

  /// يضيف كل الأساسيات لقائمة التسوق (اللى مش موجودة بالفعل غير متشالة).
  Future<int> addStaplesToList() async {
    final staplesList = await staples();
    final existing = (await shoppingItems())
        .where((i) => !i.checked)
        .map((i) => i.name)
        .toSet();
    var added = 0;
    for (final s in staplesList) {
      if (!existing.contains(s.name)) {
        await addShoppingItem(s.name, category: s.category);
        added++;
      }
    }
    return added;
  }
}
