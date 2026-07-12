import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';

/// أسماء الله الحسنى — شبكة من 99 اسم.
class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('أسماء الله الحسنى', 'Names of Allah'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 1.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: kNames99.length,
        itemBuilder: (_, i) => Container(
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
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kNames99[i],
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(arNum(i + 1),
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}
