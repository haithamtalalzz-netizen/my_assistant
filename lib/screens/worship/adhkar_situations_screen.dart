import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_more.dart';

/// أذكار المواقف اليومية (نوم/طعام/سفر/دخول وخروج…).
class AdhkarSituationsScreen extends StatelessWidget {
  const AdhkarSituationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('أذكار المواقف', 'Daily-life adhkar'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kSituationalAdhkar.length,
        itemBuilder: (_, i) {
          final s = kSituationalAdhkar[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: Text(s.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(s.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final item in s.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.repeat > 1
                                ? '${item.text}  (${arNum(item.repeat)})'
                                : item.text,
                            style: const TextStyle(fontSize: 17, height: 1.9),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
