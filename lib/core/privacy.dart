import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/settings_repo.dart';

/// **وضع الخصوصية** — تقفل بياناتك عن عين حد تانى بضغطة.
///
/// الحالة: صاحبك ماسك الموبايل بيتفرّج على التطبيق، وانت مش عايزه يشوف
/// فلوسك ولا أدويتك ولا اللى مسجّله. الزرار بيلبّس البيانات **ضبابة**
/// فتفضل الشاشة بشكلها لكن مافيش رقم يتقرا.
///
/// قرارات مقصودة:
///
///  · **مفتاح واحد لكل التطبيق** مش مفتاح لكل شاشة. السبب إن الغرض
///    واحد: «محدش يشوف». لو كل شاشة ليها مفتاحها هتفتكر تقفل واحدة
///    وتنسى التانية — والنسيان هنا معناه إن الحاجة اتشافت.
///
///  · **بيتحفظ**. لو ماكانش بيتحفظ، قفلة التطبيق وفتحه تانى تكشف كل
///    حاجة — وده بالظبط اللى بيحصل لما حد ياخد الموبايل.
///
///  · **المضبّب مش بيتداس** ([PrivacyBlur] بتلفّه فى `IgnorePointer`).
///    ضبابة بتتداس مش ضبابة: دوسة واحدة بتفتح صفحة جوّه فيها نفس الرقم
///    واضح.
class Privacy {
  /// مقفولة؟ (true = البيانات مضبّبة)
  static final ValueNotifier<bool> hidden = ValueNotifier(false);

  static const _key = 'privacy.hidden';

  static Future<void> load() async {
    hidden.value = await SettingsRepo().get(_key) == '1';
  }

  static Future<void> toggle() async {
    hidden.value = !hidden.value;
    await SettingsRepo().set(_key, hidden.value ? '1' : '0');
  }
}

/// بيلفّ محتوى حسّاس: يبان عادى، ويتضبّب لمّا الخصوصية تتقفل.
///
/// 🔴 `ImageFiltered` بتضبّب الرسم بس — الودجت تحتها **لسه شغّالة**،
/// فمن غير `IgnorePointer` حد يقدر يدوس على الضبابة ويفتح الصفحة اللى
/// جوّاها الرقم واضح. الضبابة ساعتها بتبقى ستارة على باب مفتوح.
class PrivacyBlur extends StatelessWidget {
  final Widget child;

  /// قوة الضبابة. الرقم الصغير بيسيب الأرقام مقروءة وانت فاكرها مقفولة.
  final double sigma;

  const PrivacyBlur(this.child, {super.key, this.sigma = 10});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: Privacy.hidden,
    builder: (_, hidden, _) => hidden
        ? IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
              child: child,
            ),
          )
        : child,
  );
}

/// زرار القفل/الفتح اللى بيتحط فى شريط الشاشة.
class PrivacyAction extends StatelessWidget {
  const PrivacyAction({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: Privacy.hidden,
    builder: (ctx, hidden, _) => IconButton(
      tooltip: hidden
          ? (isAr(ctx) ? 'اظهر بياناتى' : 'Show my data')
          : (isAr(ctx) ? 'اخفِ بياناتى' : 'Hide my data'),
      icon: Icon(hidden ? Icons.visibility_off : Icons.visibility_outlined),
      color: hidden ? Theme.of(ctx).colorScheme.primary : null,
      onPressed: Privacy.toggle,
    ),
  );
}

bool isAr(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// **الطبقة العامة** — بتتحط فى `MaterialApp.builder` فتغطّى التطبيق
/// كله: كل شاشة، وكل حوار، وكل ورقة سفلية، والسايدبار كمان.
///
/// ليه عامة بدل ما كل شاشة تلفّ جسمها:
/// فى التطبيق **١٣٣ شريط علوى فى ١١٩ ملف**. لفّ كل جسم بإيدى معناه إنى
/// هنسى واحد — والشاشة المنسية هى بالظبط التسريب اللى البند ده متعمول
/// عشانه. والطبقة العامة كمان بتغطّى أى شاشة تتضاف بعد كده من غير ما
/// حد يفتكر.
///
/// مافيش `IgnorePointer` هنا **بقصد**: لمّا يكون التطبيق **كله** مضبّب
/// مافيش «صفحة واضحة ورا الستارة» — أى حتة تدوس عليها هتوصلك لحاجة
/// مضبّبة برضه. (الـ`IgnorePointer` ضرورى فى [PrivacyBlur] اللى بتغطّى
/// جزء من شاشة بس.)
class PrivacyShell extends StatelessWidget {
  final Widget child;
  const PrivacyShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: Privacy.hidden,
    builder: (ctx, hidden, _) {
      if (!hidden) return child;
      return Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
              tileMode: TileMode.decal,
            ),
            child: child,
          ),
          // زرار الفتح **فوق** الضبابة عشان يفضل واضح: زرار الشريط
          // نفسه بيتضبّب مع الباقى، فمن غير الزرار ده مافيش طريقة
          // تفتح غير إنك تدوس على حتة مش شايفها.
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 6,
            left: 10,
            child: _UnlockButton(),
          ),
        ],
      );
    },
  );
}

class _UnlockButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: Privacy.toggle,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(Icons.visibility_off, size: 21, color: scheme.onPrimary),
        ),
      ),
    );
  }
}
