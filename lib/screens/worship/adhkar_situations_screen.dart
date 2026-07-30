import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_more.dart';

/// أذكار المواقف اليومية (نوم/طعام/سفر/دخول وخروج…) — مع بحث ونسخ.
class AdhkarSituationsScreen extends StatefulWidget {
  const AdhkarSituationsScreen({super.key});

  @override
  State<AdhkarSituationsScreen> createState() => _AdhkarSituationsScreenState();
}

class _AdhkarSituationsScreenState extends State<AdhkarSituationsScreen> {
  String _query = '';

  List<AdhkarSituation> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return kSituationalAdhkar;
    return kSituationalAdhkar
        .where((s) =>
            s.title.contains(q) ||
            s.items.any((it) => it.text.contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text(tr('أذكار المواقف', 'Daily-life adhkar'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: tr('ابحث فى الأذكار…', 'Search adhkar…'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(tr('لا يوجد نتائج', 'No results'),
                        style: TextStyle(color: scheme.onSurfaceVariant)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          initiallyExpanded: _query.trim().isNotEmpty,
                          leading:
                              Text(s.emoji, style: const TextStyle(fontSize: 24)),
                          title: Text(s.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [
                            for (final item in s.items)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.repeat > 1
                                            ? '${item.text}  (${arNum(item.repeat)})'
                                            : item.text,
                                        style: const TextStyle(
                                            fontSize: 17, height: 1.9),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                            ClipboardData(text: item.text));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    tr('اتنسخ', 'Copied'))));
                                      },
                                      child: Icon(Icons.copy,
                                          size: 16,
                                          color: scheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
