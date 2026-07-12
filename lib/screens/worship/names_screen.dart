import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';

/// أسماء الله الحسنى — شبكة الـ99 + المعنى عند الضغط + وضع الحفظ.
class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  bool _memorize = false; // يخفى الاسم ويكشفه عند الضغط.

  void _open(int i) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(arNum(i + 1),
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(kNames99[i],
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary)),
            const SizedBox(height: 14),
            Text(kNames99Meaning[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.9)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('أسماء الله الحسنى', 'Names of Allah')),
        actions: [
          IconButton(
            tooltip: tr('وضع الحفظ', 'Memorize mode'),
            isSelected: _memorize,
            icon: const Icon(Icons.visibility_off_outlined),
            selectedIcon: const Icon(Icons.visibility),
            onPressed: () => setState(() => _memorize = !_memorize),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_memorize)
            Container(
              width: double.infinity,
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(8),
              child: Text(
                tr('وضع الحفظ: الاسم مخفى — اضغط للكشف عنه ومعناه',
                    'Memorize mode: names hidden — tap to reveal + meaning'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kNames99.length,
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _open(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.7),
                        scheme.primaryContainer.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _memorize ? '﴾ ؟ ﴿' : kNames99[i],
                        style: TextStyle(
                            fontSize: _memorize ? 16 : 20,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(arNum(i + 1),
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimaryContainer
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
