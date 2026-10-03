// «عملت إيه النهاردة» — رياضة وأكل بدوسة واحدة.
//
// ليه الملف ده موجود: اللى بيقتل أى تتبّع هو **تكلفة التسجيل**، مش
// قلّة المكان. تسجيل «مشيت ٣٠ دقيقة» كان بيتكلّف شاشة كاملة (فورم
// الجيم ببرنامجه ومجموعاته، أو متتبّع GPS)، فبعد أسبوع بتبطّل.
//
// هنا الحساب والأزرار الجاهزة — **بعيد عن الودجت** عشان يتختبروا، لإن
// الرقم اللى بيتعرض لازم يكون صادق: مدة اليوم بتتجمّع من **مصدرين**
// (نشاط حُرّ + جلسات جيم)، ولو قريت واحد بس هتقول رقم ناقص وانت واثق.
import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';
import 'activity_repo.dart';
import 'gym_repo.dart';
import 'meals_repo.dart';

/// زرار جاهز: نوعه المخزّن ومدته بالدقايق.
///
/// 🔴 الاسم **بيتحسب** مش بيتخزّن: أول نسخة كانت بتاخد الاسم جاهز،
/// فالافتراضيات اتكتبت بأرقام عربية («مشى ٣٠ د») واللى بيتعلّم من
/// بياناتك اتبنى بـ`arNum` (أرقام إنجليزية زى باقى التطبيق) — يعنى
/// صفّ واحد فيه خطّين مختلفين. تعريف واحد = مستحيل يختلفوا.
class ExercisePreset {
  final String type;
  final int minutes;
  const ExercisePreset(this.type, this.minutes);

  String get label => '$type ${arNum(minutes)} د';

  @override
  bool operator ==(Object other) =>
      other is ExercisePreset && other.type == type && other.minutes == minutes;

  @override
  int get hashCode => Object.hash(type, minutes);
}

/// الأزرار اللى بتظهر لو لسه ماسجّلتش حاجة.
const List<ExercisePreset> kDefaultExercisePresets = [
  ExercisePreset('مشى', 30),
  ExercisePreset('جيم', 45),
  ExercisePreset('جرى', 20),
];

/// خلاصة رياضة اليوم: الدقايق، والكلام اللى بيقول عملت **إيه**.
///
/// الرقم لوحده مابيقولش حاجة — «٤٠ د» ممكن تكون مشى أو حديد.
class ExerciseDay {
  final int minutes;

  /// «مشى ٣٠ د · جيم ١٠ د».
  final String what;

  /// سعرات **محروقة** — غير سعرات الأكل اللى فى مربّع «سعرة».
  final int calories;
  const ExerciseDay(this.minutes, this.what, {this.calories = 0});

  bool get isEmpty => minutes == 0;
}

class DayLog {
  // ————————————————— رياضة —————————————————

  /// بتجمع نشاط اليوم من **المصدرين**: الجلسات الحُرّة (اللى الأزرار
  /// الجاهزة ومتتبّع الـGPS بيكتبوا فيها) وجلسات الجيم.
  static Future<ExerciseDay> exerciseToday([DateTime? at]) async {
    final day = dayKey(at ?? DateTime.now());
    final parts = <String, int>{};
    var burned = 0;

    for (final s in await ActivityRepo().forDay(day)) {
      burned += s.calories;
      final mins = (s.durationSec / 60).round();
      if (mins <= 0) continue;
      parts[_typeLabel(s.type)] = (parts[_typeLabel(s.type)] ?? 0) + mins;
    }
    for (final g in await GymRepo().recentSessions(limit: 60)) {
      if (g.day != day || g.durationMin <= 0) continue;
      final label = g.program.trim().isEmpty ? 'جيم' : g.program.trim();
      parts[label] = (parts[label] ?? 0) + g.durationMin;
    }

    final total = parts.values.fold(0, (a, b) => a + b);
    final what = parts.entries
        .map((e) => '${e.key} ${arNum(e.value)} د')
        .join(' · ');
    return ExerciseDay(total, what, calories: burned);
  }

  /// النوع المخزّن بالإنجليزى من متتبّع الـGPS — بنعرّبه للعرض.
  static String _typeLabel(String type) => switch (type) {
        'walk' => 'مشى',
        'run' => 'جرى',
        _ => type,
      };

  /// الأزرار الجاهزة — **بتتعلّم منك**.
  ///
  /// أكتر تلاتة سجّلتهم (نوع + مدة) بيفضلوا قدامك، فبعد أسبوعين الشاشة
  /// تبقى على مزاجك انت مش على مزاج افتراضى. الافتراضيات بتكمّل الناقص
  /// عشان الصفّ مايبقاش فاضى فى أول يوم.
  static Future<List<ExercisePreset>> presets({int limit = 3}) async {
    final counts = <ExercisePreset, int>{};
    for (final s in await ActivityRepo().recent(limit: 120)) {
      final mins = (s.durationSec / 60).round();
      if (mins <= 0) continue;
      final p = ExercisePreset(_typeLabel(s.type), mins);
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final learned = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final out = learned.take(limit).toList();
    for (final d in kDefaultExercisePresets) {
      if (out.length >= limit) break;
      if (!out.contains(d)) out.add(d);
    }
    return out;
  }

  /// بتسجّل تمرينة وبترجّع رقمها (عشان «تراجع»).
  ///
  /// [calories] **محروقة** — اللى بتدخلها بإيدك من ورقة التسجيل، أو صفر
  /// لو الزرار الجاهز هو اللى سجّل (الزرار بيعرف النوع والمدة بس).
  static Future<int> logExercise(ExercisePreset p,
      {int calories = 0, DateTime? at}) async {
    final now = at ?? DateTime.now();
    return ActivityRepo().add(ActivitySession(
      day: dayKey(now),
      type: p.type,
      distanceKm: 0,
      durationSec: p.minutes * 60,
      calories: calories,
      createdAt: now.toIso8601String(),
    ));
  }

  static Future<void> undoExercise(int id) => ActivityRepo().delete(id);

  // ————————————————— أكل —————————————————

  /// آخر وجبة اتسجّلت فى خانة معيّنة (فطار/غدا/…) — دى اللى الزرار
  /// بيكرّرها بدوسة واحدة.
  static Future<Meal?> lastMealForSlot(String slot) async {
    final db = await AppDb.instance;
    final rows = await db.query('meals',
        where: 'slot = ?', whereArgs: [slot], orderBy: 'day DESC, id DESC',
        limit: 1);
    return rows.isEmpty ? null : Meal.fromMap(rows.first);
  }

  /// بتكرّر آخر وجبة فى الخانة دى على النهاردة.
  ///
  /// بترجّع رقم الصف الجديد، أو null لو مفيش وجبة سابقة — ساعتها
  /// الشاشة بتفتح ورقة الوجبة بدل ما تسجّل حاجة من دماغها.
  static Future<int?> repeatMeal(String slot, [DateTime? at]) async {
    final prev = await lastMealForSlot(slot);
    if (prev == null) return null;
    return MealsRepo().add(Meal(
      day: dayKey(at ?? DateTime.now()),
      slot: slot,
      description: prev.description,
      calories: prev.calories,
      protein: prev.protein,
      carbs: prev.carbs,
      fat: prev.fat,
      grams: prev.grams,
    ));
  }

  static Future<void> undoMeal(int id) => MealsRepo().delete(id);

  /// خلاصة أكل اليوم: السعرات، والخانات اللى اتسجّلت.
  static Future<({int calories, String what})> mealsToday(
      [DateTime? at]) async {
    final day = dayKey(at ?? DateTime.now());
    final meals = await MealsRepo().forDay(day);
    final cal =
        meals.fold<double>(0, (s, m) => s + (m.calories ?? 0)).round();
    // بالترتيب الطبيعى للخانات، من غير تكرار.
    final slots = [
      for (final s in kMealSlots)
        if (meals.any((m) => m.slot == s)) s
    ];
    return (calories: cal, what: slots.join(' · '));
  }
}
