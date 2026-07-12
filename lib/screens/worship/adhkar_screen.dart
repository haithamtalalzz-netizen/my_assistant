import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';

/// قارئ الأذكار (الصباح/المساء) — كل ذِكر معاه عدّاد، دوس عليه ينقص لحد ما يخلص.
class AdhkarScreen extends StatefulWidget {
  final bool morning;
  const AdhkarScreen({super.key, required this.morning});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  late final List<Dhikr> _items = widget.morning ? kMorningAdhkar : kEveningAdhkar;
  late final List<int> _remaining = _items.map((d) => d.count).toList();

  int get _doneCount => _remaining.where((r) => r == 0).length;

  void _tap(int i) {
    if (_remaining[i] == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _remaining[i]--;
      if (_remaining[i] == 0) HapticFeedback.mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.morning
            ? tr('أذكار الصباح', 'Morning adhkar')
            : tr('أذكار المساء', 'Evening adhkar')),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _items.isEmpty ? 0 : _doneCount / _items.length,
            minHeight: 6,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr('${arNum(_doneCount)} من ${arNum(_items.length)}',
                  '${arNum(_doneCount)} of ${arNum(_items.length)}'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final done = _remaining[i] == 0;
                return Card(
                  color: done ? scheme.surfaceContainerHighest : null,
                  child: InkWell(
                    onTap: () => _tap(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _items[i].text,
                            style: TextStyle(
                              fontSize: 19,
                              height: 1.9,
                              color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                            ),
                          ),
                          if (_items[i].note != null) ...[
                            const SizedBox(height: 8),
                            Text('• ${_items[i].note}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.primary,
                                    fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    done ? const Color(0xFF2FA36B) : scheme.primaryContainer,
                                child: done
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : Text(arNum(_remaining[i]),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onPrimaryContainer)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                done
                                    ? tr('تمّ', 'Done')
                                    : tr('التكرار: ${arNum(_items[i].count)}',
                                        'Repeat: ${arNum(_items[i].count)}'),
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
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
