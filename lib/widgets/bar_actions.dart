import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// زرار فى شريط العنوان — أيقونة + اسم + إجراء.
///
/// الاسم مش زينة: هو اللى بيظهر فى قايمة «المزيد» لمّا الزرار مايلاقيش
/// مكان، وهو كمان الـtooltip.
class BarAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const BarAction(this.icon, this.label, this.onTap);
}

/// بيوزّع أزرار شريط العنوان على حسب عرض الشاشة: اللى مايسعش بينزل فى
/// قايمة «⋮ المزيد».
///
/// 🔴 من غير كده، ٦ أيقونات على شاشة ٣٢٠px بتاكل العرض كله و**العنوان
/// بيختفى خالص** — مش بيتقصّ، بيروح. حصل فى «الجيم» و«المحفظة» ومحدّش
/// حاسس، لإن الاختفاء ده مابيرميش أى خطأ ومافيش اختبار بيشوفه؛
/// `tool/sizes_test.dart` بقى بيمسكه بقاعدة «عرض النصّ ≈ صفر».
/// [reserved] = عدد الأيقونات اللى بتتعرض **برّه** القايمة دى (زى زرار
/// عليه Badge مايقدرش ينزل فى قايمة). من غيرها الدالة بتحسب إن الشاشة
/// فاضية وتسيب كل حاجة ظاهرة، فالعنوان يتقصّ برضه.
List<Widget> barActions(BuildContext context, List<BarAction> items,
    {int reserved = 0}) {
  IconButton btn(BarAction a) => IconButton(
        icon: Icon(a.icon),
        tooltip: a.label,
        onPressed: a.onTap,
      );

  final width = MediaQuery.of(context).size.width;
  // الأرقام دى اتقاست مع الثيم الحالى (أيقونة ٢١ · `titleSpacing` ١٠):
  // الزرار بياخد ~٤٢px، والعنوان محتاج ~١٦٠ عشان اسم زى «الديون والسلف»
  // يبان كامل. لو الثيم اتغيّر، `tool/sizes_test` هو اللى هيقول.
  final fits = ((width - 160) / 42).floor() - reserved;
  if (fits >= items.length) return [for (final a in items) btn(a)];

  // بنسيب خانة للـ«⋮» نفسه.
  final keep = (fits - 1).clamp(0, items.length);
  final shown = items.take(keep).toList();
  final rest = items.sublist(shown.length);
  return [
    for (final a in shown) btn(a),
    PopupMenuButton<int>(
      tooltip: tr('المزيد', 'More'),
      itemBuilder: (_) => [
        for (var i = 0; i < rest.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(children: [
              Icon(rest[i].icon, size: 19),
              const SizedBox(width: 12),
              Expanded(child: Text(rest[i].label)),
            ]),
          ),
      ],
      onSelected: (i) => rest[i].onTap(),
    ),
  ];
}
