import 'dart:convert';

import '../core/log.dart';
import 'income_repo.dart';
import 'money_repo.dart';
import 'settings_repo.dart';

/// **بنود المصروف والدخل** — الجاهزة + اللى بتضيفها بنفسك.
///
/// البنود الجاهزة (`kExpenseCategories` / `kIncomeSources`) ثابتة فى
/// الكود عشان البيانات القديمة تفضل مفهومة، واللى بتضيفه بيتحفظ فى
/// الإعدادات ويتقرا معاها.
///
/// ليه مخزّنة فى الإعدادات مش جدول: المصروف بيخزّن اسم البند **نصّ**،
/// فالقايمة دى للاختيار بس — مافيش علاقات ولا ارتباطات تتكسر.
///
/// 🔴 القايمة بتتحمّل مرة فى `load()` وبتفضل فى الذاكرة، عشان منتقيات
/// البنود بتتبنى **بشكل متزامن** جوّه `build`.
class MoneyCategories {
  static const _kExpense = 'custom_expense_categories';
  static const _kIncome = 'custom_income_sources';

  static List<String> _customExpense = [];
  static List<String> _customIncome = [];
  static bool _loaded = false;

  /// بنود المصروف: الجاهزة الأول وبعدها بتوعك.
  static List<String> get expense => [...kExpenseCategories, ..._customExpense];

  /// بنود الدخل: الجاهزة الأول وبعدها بتوعك.
  static List<String> get income => [...kIncomeSources, ..._customIncome];

  static bool isCustomExpense(String name) => _customExpense.contains(name);
  static bool isCustomIncome(String name) => _customIncome.contains(name);

  static Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _customExpense = await _read(_kExpense);
    _customIncome = await _read(_kIncome);
    _loaded = true;
  }

  static Future<List<String>> _read(String key) async {
    final raw = await SettingsRepo().get(key);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final e in list)
          if (e is String && e.trim().isNotEmpty) e.trim()
      ];
    } catch (e) {
      // إعداد بايظ مايوقّعش الشاشة — بنرجع فاضى ونكمّل بالبنود الجاهزة.
      logInfo('custom categories parse failed: $e');
      return [];
    }
  }

  static Future<void> _write(String key, List<String> list) =>
      SettingsRepo().set(key, jsonEncode(list));

  /// بيضيف بند جديد. بيرجّع false لو الاسم فاضى أو موجود خلاص.
  static Future<bool> addExpense(String name) async {
    final n = name.trim();
    if (n.isEmpty || expense.contains(n)) return false;
    _customExpense = [..._customExpense, n];
    await _write(_kExpense, _customExpense);
    return true;
  }

  static Future<bool> addIncome(String name) async {
    final n = name.trim();
    if (n.isEmpty || income.contains(n)) return false;
    _customIncome = [..._customIncome, n];
    await _write(_kIncome, _customIncome);
    return true;
  }

  /// بيشيل بند **أضفته انت** بس — الجاهز مابيتشالش.
  ///
  /// المصاريف القديمة اللى على البند ده مابتتغيّرش: اسمها متخزّن فيها،
  /// فبتفضل ظاهرة بنفس الاسم.
  static Future<void> removeExpense(String name) async {
    if (!_customExpense.contains(name)) return;
    _customExpense = [..._customExpense]..remove(name);
    await _write(_kExpense, _customExpense);
  }

  static Future<void> removeIncome(String name) async {
    if (!_customIncome.contains(name)) return;
    _customIncome = [..._customIncome]..remove(name);
    await _write(_kIncome, _customIncome);
  }

  /// للاختبارات: يرجّع كل حاجة لأصلها.
  static void resetForTests() {
    _customExpense = [];
    _customIncome = [];
    _loaded = false;
  }
}
