import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_more.dart';

/// دليل العمرة والحج — خطوات مرتّبة.
class HajjUmrahScreen extends StatelessWidget {
  const HajjUmrahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('العمرة والحج', 'Umrah & Hajj')),
          bottom: TabBar(tabs: [
            Tab(text: tr('العمرة', 'Umrah')),
            Tab(text: tr('الحج', 'Hajj')),
          ]),
        ),
        body: TabBarView(
          children: [
            _steps(context, kUmrahSteps),
            _steps(context, kHajjSteps),
          ],
        ),
      ),
    );
  }

  Widget _steps(BuildContext context, List<String> steps) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: steps.length,
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary,
                child: Text(arNum(i + 1),
                    style: TextStyle(
                        color: scheme.onPrimary, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(steps[i],
                    style: const TextStyle(fontSize: 16, height: 1.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
