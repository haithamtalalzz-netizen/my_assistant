import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n.dart';
import '../../core/religion_data.dart';

/// أدعية مأثورة مصنّفة + بحث.
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _query = '';
  int _cat = 0; // 0 = الكل

  List<({String cat, String emoji, String dua})> get _results {
    final out = <({String cat, String emoji, String dua})>[];
    for (var i = 0; i < kDuaCategories.length; i++) {
      if (_cat != 0 && _cat - 1 != i) continue;
      final c = kDuaCategories[i];
      for (final d in c.duas) {
        if (_query.isEmpty || d.contains(_query) || c.name.contains(_query)) {
          out.add((cat: c.name, emoji: c.emoji, dua: d));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(tr('أدعية مأثورة', 'Supplications'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr('ابحث فى الأدعية…', 'Search du\'as…'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kDuaCategories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = i == 0
                    ? tr('الكل', 'All')
                    : '${kDuaCategories[i - 1].emoji} ${kDuaCategories[i - 1].name}';
                return ChoiceChip(
                  label: Text(label),
                  selected: _cat == i,
                  onSelected: (_) => setState(() => _cat = i),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(tr('لا يوجد نتائج', 'No results'),
                        style: TextStyle(color: scheme.onSurfaceVariant)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${r.emoji} ${r.cat}',
                                      style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: r.dua));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(tr(
                                                  'اتنسخ', 'Copied'))));
                                    },
                                    child: Icon(Icons.copy,
                                        size: 18, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(r.dua,
                                  style: const TextStyle(
                                      fontSize: 18, height: 1.9)),
                            ],
                          ),
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
