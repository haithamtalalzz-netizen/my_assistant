import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../widgets/search_action.dart';

/// عنصر في هَب المجموعة — إما بيفتح شاشة (screen) أو بيبدّل تبويب في الـShell.
class GroupHubItem {
  final IconData icon;
  final String label;
  final Widget? screen;
  final int? tabIndex;
  final Color? color;

  const GroupHubItem(
    this.icon,
    this.label, {
    this.screen,
    this.tabIndex,
    this.color,
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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
        children: [for (final it in items) _tile(context, it)],
      ),
    );
  }

  Widget _tile(BuildContext context, GroupHubItem it) {
    final scheme = Theme.of(context).colorScheme;
    final color = it.color ?? accent ?? scheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (it.tabIndex != null) {
            Navigator.pop(context); // اقفل الهَب وارجع للـShell
            onSelectTab(it.tabIndex!);
          } else if (it.screen != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => it.screen!));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(it.icon, color: color, size: 27),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(it.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنوان تعريفي بسيط (مستخدم لو حبينا نضيف وصف للهَب لاحقًا).
String hubHint() => tr('اختار من المربعات', 'Pick a tile');
