import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../data/settings_repo.dart';

/// كارت واحد قابل للترتيب: [id] ثابت (للحفظ) + [child] المحتوى.
class ReorderCard {
  final String id;
  final Widget child;
  const ReorderCard(this.id, this.child);
}

/// شبكة كروت قابلة لإعادة الترتيب بالضغط المطوّل + السحب، والترتيب بيتحفظ.
/// بتتحط جوّه أى صفحة (مثلاً داخل ListView) عن طريق shrinkWrap.
class ReorderableCards extends StatefulWidget {
  final String storageKey;
  final List<ReorderCard> cards;
  final int? crossAxisCount;
  final double? maxCrossAxisExtent;
  final double childAspectRatio;
  final double spacing;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ReorderableCards({
    super.key,
    required this.storageKey,
    required this.cards,
    this.crossAxisCount,
    this.maxCrossAxisExtent,
    this.childAspectRatio = 1,
    this.spacing = 12,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  State<ReorderableCards> createState() => _ReorderableCardsState();
}

class _ReorderableCardsState extends State<ReorderableCards> {
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

  List<ReorderCard> get _ordered {
    final byId = {for (final c in widget.cards) c.id: c};
    return <ReorderCard>[
      for (final id in _order) ?byId.remove(id),
      ...byId.values,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ordered = _ordered;
    final gridDelegate = widget.maxCrossAxisExtent != null
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: widget.maxCrossAxisExtent!,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: widget.spacing,
            mainAxisSpacing: widget.spacing,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount ?? 3,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: widget.spacing,
            mainAxisSpacing: widget.spacing,
          );

    return ReorderableGridView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      gridDelegate: gridDelegate,
      itemCount: ordered.length,
      onReorder: (oldI, newI) {
        final list = [...ordered];
        list.insert(newI, list.removeAt(oldI));
        setState(() => _order = [for (final c in list) c.id]);
        _settings.setCardOrder(widget.storageKey, _order);
      },
      itemBuilder: (_, i) =>
          KeyedSubtree(key: ValueKey(ordered[i].id), child: ordered[i].child),
    );
  }
}
