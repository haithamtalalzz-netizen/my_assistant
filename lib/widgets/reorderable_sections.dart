import 'package:flutter/material.dart';

import '../data/settings_repo.dart';

/// قسم واحد فى صفحة قابلة للترتيب: [id] ثابت (للحفظ) + [child] المحتوى.
class Section {
  final String id;
  final Widget child;
  const Section(this.id, this.child);
}

/// بيرتّب [sections] حسب [order] المحفوظ — أى قسم جديد (مش فى الترتيب المحفوظ)
/// بيفضل فى مكانه الافتراضى بدل ما يتنطّ للآخر.
///
/// دالة نقية عشان تتختبر من غير واجهة.
List<Section> applySectionOrder(List<Section> sections, List<String> order) {
  if (order.isEmpty) return sections;
  final rank = <String, int>{};
  for (var i = 0; i < order.length; i++) {
    rank[order[i]] = i;
  }
  // القسم اللى مش فى الترتيب المحفوظ بياخد رتبة جاره اللى قبله عشان يفضل مكانه.
  final keyed = <(double, int, Section)>[];
  var lastRank = -1.0;
  for (var i = 0; i < sections.length; i++) {
    final s = sections[i];
    final r = rank[s.id];
    if (r != null) {
      lastRank = r.toDouble();
      keyed.add((lastRank, i, s));
    } else {
      // جديد: يتحط بعد اللى قبله مباشرة.
      keyed.add((lastRank + 0.5, i, s));
    }
  }
  keyed.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  return [for (final k in keyed) k.$3];
}

/// قايمة أقسام بعرض كامل وارتفاع متغيّر، قابلة لإعادة الترتيب بالضغط المطوّل،
/// والترتيب بيتحفظ. (بعكس [ReorderableCards] اللى شبكة مربعات متساوية.)
///
/// [header] بيفضل ثابت فوق ومش بيتحرّك.
class ReorderableSections extends StatefulWidget {
  final String storageKey;
  final List<Section> sections;
  final Widget? header;
  final EdgeInsets padding;
  final double gap;

  const ReorderableSections({
    super.key,
    required this.storageKey,
    required this.sections,
    this.header,
    this.padding = EdgeInsets.zero,
    this.gap = 12,
  });

  @override
  State<ReorderableSections> createState() => _ReorderableSectionsState();
}

class _ReorderableSectionsState extends State<ReorderableSections> {
  final _settings = SettingsRepo();
  List<String> _order = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _settings.cardOrder(widget.storageKey).then((o) {
      if (!mounted) return;
      setState(() {
        _order = o;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _loaded
        ? applySectionOrder(widget.sections, _order)
        : widget.sections;

    return ReorderableListView.builder(
      padding: widget.padding,
      header: widget.header,
      itemCount: ordered.length,
      // السحب بالضغط المطوّل (مفيش مقابض ظاهرة عشان الشكل يفضل نضيف).
      buildDefaultDragHandles: false,
      // onReorderItem بيظبط الـindex لوحده بعد الشيل (بعكس onReorder المهجورة).
      onReorderItem: (oldI, newI) {
        final list = [...ordered];
        list.insert(newI, list.removeAt(oldI));
        final ids = [for (final s in list) s.id];
        setState(() => _order = ids);
        _settings.setCardOrder(widget.storageKey, ids);
      },
      itemBuilder: (_, i) => ReorderableDelayedDragStartListener(
        key: ValueKey(ordered[i].id),
        index: i,
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.gap),
          child: ordered[i].child,
        ),
      ),
    );
  }
}
