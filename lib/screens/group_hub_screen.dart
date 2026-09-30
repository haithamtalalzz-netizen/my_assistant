import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../widgets/reorderable_cards.dart';
import '../core/ar.dart';
import '../widgets/search_action.dart';

/// عنصر في هَب المجموعة — إما بيفتح شاشة (screen) أو بيبدّل تبويب في الـShell.
class GroupHubItem {
  final IconData icon;
  final String label;
  final Widget? screen;
  final int? tabIndex;
  final Color? color;

  /// دالة بترجّع عدد يتعرض كشارة حمرا على الكارت (مثلًا مستندات قربت
  /// تنتهى). null = مفيش شارة. بتتنادى مرة عند بناء الهَب.
  final Future<int> Function()? badge;

  /// رقم البند وحالته — عشان السطر يقول اللى وراه **قبل** ما تدوس.
  /// null = البند مالوش رقم يتقال.
  final Future<HubStat?> Function()? stat;

  const GroupHubItem(
    this.icon,
    this.label, {
    this.screen,
    this.tabIndex,
    this.color,
    this.badge,
    this.stat,
  });
}

/// اللى بيتعرض على سطر البند: وصف حى + رقم كبير + كلمة تحته.
///
/// الفكرة اللى طلعت من «فلوسى»: **مافيش باب بيتفتح من غير ما يقول اللى
/// وراه**. قايمة أبواب صامتة بتخلّى كل دوسة تجربة.
class HubStat {
  /// سطر تحت الاسم — «الرحيق المختوم · صفحة 84».
  final String? sub;

  /// الرقم الكبير على الشمال — «3».
  final String? big;

  /// كلمة صغيرة تحت الرقم — «كتب السنة دى».
  final String? bigSub;

  /// لون الرقم — أحمر لو الرقم ده حاجة فاتت.
  final Color? bigColor;

  const HubStat({this.sub, this.big, this.bigSub, this.bigColor});
}

/// صفحة مجموعة على شكل مربعات (زي هَبّات ملف المركبة في طارة).
class GroupHubScreen extends StatelessWidget {
  final String title;
  final List<GroupHubItem> items;
  final void Function(int index) onSelectTab;
  final Color? accent;

  /// كارت خلاصة فوق القايمة (اختيارى) — بيقول حالة المجموعة كلها.
  final Widget? header;

  const GroupHubScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onSelectTab,
    this.accent,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // ٣ أعمدة على شاشة ٣٢٠ بتخلّى الكارت ٨٨px، فالأيقونة والشارة
    // مايسعوش جوّه الصف. العدد بيتبع العرض بدل ما يكون ثابت.
    // **قايمة واحدة** بدل شبكة مربعات: المربّع كان بيسع كلمتين، فأسماء
    // زى «الديون والسلف» تتقصّ، والشاشة تبقى صفّين ونص من غير أى تفصيلة.
    // السطر بيسع الاسم كامل، وعلى الشاشة العريضة بيرجع عمودين.
    final cols = width > 640 ? 2 : 1;
    // السطر بيعلى لما يكون فيه رقم ووصف تحت الاسم.
    final tall = items.any((i) => i.stat != null);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [searchAction(context)]),
      body: Column(children: [
        if (header != null)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2), child: header!),
        Expanded(
            child: ReorderableCards(
        // ترتيب لكل مجموعة على حدة (اضغط مطوّل واسحب).
        storageKey: 'group.$title',
        crossAxisCount: cols,
        mainAxisExtent: tall ? 68 : 58,
        spacing: 7,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        cards: [
          for (final it in items) ReorderCard(it.label, _tile(context, it)),
        ],
      )),
      ]),
    );
  }

  /// لون ثابت لكل بند مأخوذ من اسمه — عشان تعرف البند من لونه قبل ما
  /// تقرا. (لو كل الأيقونات بلون الهَب الواحد بتبقى كلها شكل واحد.)
  static const _palette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF43F5E),
    Color(0xFF14B8A6),
  ];

  static Color _colorFor(String label) =>
      _palette[label.hashCode.abs() % _palette.length];

  Widget _tile(BuildContext context, GroupHubItem it) {
    // 🔴 FutureBuilder واحد للسطر كله. لو الاسم والرقم كل واحد فى
    // FutureBuilder لوحده الدالة بتتنفّذ **مرتين** — استعلامين على
    // القاعدة لكل سطر من غير ما حد يلاحظ.
    return it.stat == null
        ? _row(context, it, null)
        : FutureBuilder<HubStat?>(
            future: it.stat!(),
            builder: (_, snap) => _row(context, it, snap.data),
          );
  }

  Widget _row(BuildContext context, GroupHubItem it, HubStat? st) {
    final scheme = Theme.of(context).colorScheme;
    final color = it.color ?? _colorFor(it.label);
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (it.tabIndex != null) {
            // اقفل كل الهَبّات المفتوحة (ممكن تكون متداخلة أكتر من مستوى،
            // زى «العادات» جوّه «الصحة» جوّه «صحتى») وارجع للـShell قبل
            // تبديل التبويب — pop واحدة كانت بترجع للهَب الأب مش للـShell.
            Navigator.popUntil(context, (route) => route.isFirst);
            onSelectTab(it.tabIndex!);
          } else if (it.screen != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => it.screen!));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(it.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: it.stat == null
                  ? Text(it.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(it.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface)),
                        // لحد ما الرقم يوصل السطر بيفضل فاضى مش «...» —
                        // فالسطر مابينطّش لما البيانات توصل.
                        const SizedBox(height: 2),
                        Text(st?.sub ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
            ),
            if (st?.big != null)
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(st!.big!,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: st.bigColor ?? color)),
                      if (st.bigSub != null)
                        Text(st.bigSub!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5,
                                color: scheme.onSurfaceVariant)),
                    ]),
              ),
            if (it.badge != null)
              FutureBuilder<int>(
                future: it.badge!(),
                builder: (_, snap) {
                  final n = snap.data ?? 0;
                  if (n <= 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      n > 9 ? tr('٩+', '9+') : arNum(n),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: scheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            Icon(Icons.chevron_left, size: 20, color: scheme.outline),
          ]),
        ),
      ),
    );
  }
}

/// عنوان تعريفي بسيط (مستخدم لو حبينا نضيف وصف للهَب لاحقًا).
String hubHint() => tr('اختار من القايمة', 'Pick one');
