import 'dart:convert';

import '../core/log.dart';
import 'settings_repo.dart';

/// **تاريخ إجمالى فلوسك شهرًا بشهر.**
///
/// بيتسجّل رقم واحد أول ما تفتح «فلوسى» فى شهر جديد، فبنقدر نقول لك
/// «زادت ولا قلّت» من غير ما نحسب حاجة غلط.
///
/// ليه لقطة مش جمع الحركات: إجمالى فلوسك فيه أصول وذهب قيمتهم بتتغيّر
/// لما تعدّلها انت — والتعديل ده مش «حركة»، فجمع الدخل والمصروف كان
/// هيقول لك رقم مش صحيح.
class WealthHistory {
  static const _key = 'wealth_snapshots';

  /// بنحتفظ بسنتين — أكتر من كده مالهوش لازمة وبيكبّر الإعداد.
  static const _keep = 24;

  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static Future<Map<String, double>> all() async {
    final raw = await SettingsRepo().get(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return {};
      return {
        for (final e in m.entries)
          if (e.value is num) e.key.toString(): (e.value as num).toDouble()
      };
    } catch (e) {
      logInfo('wealth snapshots parse failed: $e');
      return {};
    }
  }

  /// بيسجّل إجمالى الشهر ده **لو لسه مااتسجّلش**.
  ///
  /// أول فتحة فى الشهر هى المرجع؛ اللى بعدها مابتغيّرهاش، وإلا الفرق
  /// هيفضل صفر على طول.
  static Future<void> recordIfNew(double total, {DateTime? now}) async {
    final k = monthKey(now ?? DateTime.now());
    final map = await all();
    if (map.containsKey(k)) return;
    map[k] = total;
    final keys = map.keys.toList()..sort();
    final trimmed = keys.length <= _keep
        ? map
        : {for (final key in keys.sublist(keys.length - _keep)) key: map[key]!};
    await SettingsRepo().set(_key, jsonEncode(trimmed));
  }

  /// الفرق بين إجمالى النهاردة وأول الشهر.
  ///
  /// بيرجّع null لو ده أول شهر بيتسجّل — عشان مانقولش «صفر» وكأن مفيش
  /// تغيير، والحقيقة إننا مانعرفش.
  static Future<double?> changeThisMonth(double total, {DateTime? now}) async {
    final map = await all();
    final start = map[monthKey(now ?? DateTime.now())];
    if (start == null) return null;
    return total - start;
  }

  static Future<void> clearForTests() => SettingsRepo().set(_key, '');
}
