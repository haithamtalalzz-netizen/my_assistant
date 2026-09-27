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

  const GroupHubItem(
    this.icon,
    this.label, {
    this.screen,
    this.tabIndex,
    this.color,
    this.badge,
  });
}

/// صفحة مجموعة على شكل مربعات (زي هَبّات ملف المركبة في طارة).
class GroupHubScreen extends StatelessWidget {
  final String title;
  final List<GroupHubItem> items;
  final void Function(int index) onSelectTab;
  final Color? accent;

  const GroupHubScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onSelectTab,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 640 ? 4 : 3;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [searchAction(context)]),
      body: ReorderableCards(
        // ترتيب لكل مجموعة على حدة (اضغط مطوّل واسحب).
        storageKey: 'group.$title',
        crossAxisCount: cols,
        // طول ثابت: على الشاشة العريضة (فولد/تابلت) النسبة كانت بتطوّل
        // الكروت وتسيبها فاضية من جوّه.
        mainAxisExtent: 132,
        padding: const EdgeInsets.all(16),
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        cards: [
          for (final it in items) ReorderCard(it.label, _tile(context, it)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, GroupHubItem it) {
    final scheme = Theme.of(context).colorScheme;
    final color = it.color ?? accent ?? scheme.primary;
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(it.icon, color: color, size: 20),
                ),
                const Spacer(),
                if (it.badge != null)
                  FutureBuilder<int>(
                    future: it.badge!(),
                    builder: (_, snap) {
                      final n = snap.data ?? 0;
                      if (n <= 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
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
              ]),
              const Spacer(),
              // سطرين: أسماء زى «الديون والسلف» بتتقصّ على سطر واحد.
              Text(it.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنوان تعريفي بسيط (مستخدم لو حبينا نضيف وصف للهَب لاحقًا).
String hubHint() => tr('اختار من المربعات', 'Pick a tile');
