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

  // ---- قوائم التسوق المتعددة ----

  Future<List<ShoppingList>> shoppingLists() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('shopping_lists', orderBy: 'sort_order, id');
    return rows.map(ShoppingList.fromMap).toList();
  }

  Future<int> addShoppingList(String name, {String emoji = '🛒'}) async {
    final db = await AppDb.instance;
    final maxRow = await db
        .rawQuery('SELECT COALESCE(MAX(sort_order), -1) m FROM shopping_lists');
    final next = ((maxRow.first['m'] as num?)?.toInt() ?? -1) + 1;
    return db.insert('shopping_lists', {
      'name': name,
      'emoji': emoji,
      'sort_order': next,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> renameShoppingList(int id,
      {String? name, String? emoji}) async {
    final db = await AppDb.instance;
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (emoji != null) data['emoji'] = emoji;
    if (data.isEmpty) return;
    await db.update('shopping_lists', data, where: 'id = ?', whereArgs: [id]);
  }

  /// يمسح القائمة وبنودها.
  Future<void> deleteShoppingList(int id) async {
    final db = await AppDb.instance;
    await db.delete('shopping_items', where: 'list_id = ?', whereArgs: [id]);
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  // ---- بنود التسوق ----

  /// بنود قائمة معيّنة (النشطة، مش المؤجّلة). [listId] = null → كل البنود.
  Future<List<ShoppingItem>> shoppingItems({int? listId}) async {
    final db = await AppDb.instance;
    final where = ['buy_later = 0'];
    final args = <Object?>[];
    if (listId != null) {
      where.add('list_id = ?');
      args.add(listId);
    }
    final rows = await db.query('shopping_items',
        where: where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'checked, id DESC');
    return rows.map(ShoppingItem.fromMap).toList();
  }

  /// قائمة «أشتري لاحقاً» (المؤجّلة) عبر كل القوائم، الأهم الأول.
  Future<List<ShoppingItem>> buyLaterItems() async {
    final db = await AppDb.instance;
    final rows = await db.query('shopping_items',
        where: 'buy_later = 1', orderBy: 'priority DESC, id DESC');
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<int> addShoppingItem(String name,
      {String category = '',
      double price = 0,
      int? listId,
      String qty = '',
      String place = '',
      int priority = 0,
      bool buyLater = false}) async {
    final db = await AppDb.instance;
    return db.insert(
        'shopping_items',
        ShoppingItem(
          name: name,
          category: category,
          price: price,
          listId: listId,
          qty: qty,
          place: place,
          priority: priority,
          buyLater: buyLater,
          createdAt: DateTime.now().toIso8601String(),
        ).toMap());
  }

  Future<void> updateShoppingItem(int id,
      {String? name,
      String? category,
      double? price,
      int? listId,
      String? qty,
      String? place,
      int? priority,
      bool? buyLater}) async {
    final db = await AppDb.instance;
    final data = <String, Object?>{};
    if (name != null) data['name'] = name;
    if (category != null) data['category'] = category;
    if (price != null) data['price'] = price;
    if (listId != null) data['list_id'] = listId;
    if (qty != null) data['qty'] = qty;
    if (place != null) data['place'] = place;
    if (priority != null) data['priority'] = priority;
    if (buyLater != null) data['buy_later'] = buyLater ? 1 : 0;
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

  /// إجمالي أسعار العناصر اللى لسه ماتشالتش (لقائمة معيّنة أو الكل).
  Future<double> shoppingTotal({int? listId}) async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(price),0) t FROM shopping_items '
        'WHERE checked = 0 AND buy_later = 0'
        '${listId != null ? ' AND list_id = ?' : ''}',
        listId != null ? [listId] : null);
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
  Future<int> addStaplesToList({int? listId}) async {
    final staplesList = await staples();
    final existing = (await shoppingItems(listId: listId))
        .where((i) => !i.checked)
        .map((i) => i.name)
        .toSet();
    var added = 0;
    for (final s in staplesList) {
      if (!existing.contains(s.name)) {
        await addShoppingItem(s.name, category: s.category, listId: listId);
        added++;
      }
    }
    return added;
  }

  /// يضيف مجموعة أصناف من قالب لقائمة — بيتخطّى اللى موجود بالفعل.
  Future<int> addTemplateToList(List<String> names, {int? listId}) async {
    final existing = (await shoppingItems(listId: listId))
        .where((i) => !i.checked)
        .map((i) => i.name)
        .toSet();
    var added = 0;
    for (final n in names) {
      if (n.trim().isEmpty || existing.contains(n)) continue;
      await addShoppingItem(n, listId: listId);
      added++;
    }
    return added;
  }
}

/// قوالب جاهزة (اسم القالب → أصناف نموذجية) — بضغطة تتضاف للقائمة.
const Map<String, List<String>> kShoppingTemplates = {
  'مستلزمات مدرسة': [
    'كشاكيل', 'أقلام', 'ألوان', 'حقيبة', 'أدوات هندسية', 'مقلمة', 'كراسات'
  ],
  'عزومة': [
    'فراخ', 'لحمة', 'رز', 'خضار سلطة', 'مشروبات', 'حلويات', 'فاكهة', 'عيش'
  ],
  'سفر/رحلة': [
    'معجون وفرشة', 'شاحن', 'أدوية شخصية', 'مناديل', 'كريم شمس', 'محبس/كمامة',
    'ملابس', 'سناكس'
  ],
  'رمضان': [
    'تمر', 'ياميش', 'عصائر', 'مكرونة', 'رز', 'زيت', 'سكر', 'دقيق', 'فراخ',
    'لحمة'
  ],
  'مستلزمات بيبى': [
    'حفاضات', 'مناديل مبللة', 'لبن', 'كريم', 'شامبو أطفال', 'ببرونة'
  ],
};

/// فئة المصروف المناسبة لقائمة تسوق (للربط بالميزانية) — بالاسم.
String expenseCategoryForList(String listName) {
  if (listName.contains('سوبر') ||
      listName.contains('بقالة') ||
      listName.contains('أكل')) {
    return 'أكل';
  }
  if (listName.contains('صيدلية') || listName.contains('دوا')) return 'صحة';
  return 'تسوق';
}
