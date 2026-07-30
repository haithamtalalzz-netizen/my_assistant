import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/religion_data.dart';
import '../../data/settings_repo.dart';
import '../../data/worship_repo.dart';

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
  bool _marked = false;
  double _fontSize = 19;
  static const _kFont = 'adhkar_font_size';

  int get _doneCount => _remaining.where((r) => r == 0).length;

  @override
  void initState() {
    super.initState();
    SettingsRepo().get(_kFont).then((v) {
      final f = double.tryParse(v ?? '');
      if (f != null && mounted) setState(() => _fontSize = f.clamp(14, 32));
    });
  }

  void _adjustFont(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(14, 32));
    SettingsRepo().set(_kFont, _fontSize.toString());
  }

  void _tap(int i) {
    if (_remaining[i] == 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _remaining[i]--;
      if (_remaining[i] == 0) HapticFeedback.mediumImpact();
    });
    if (!_marked && _doneCount == _items.length) {
      _marked = true;
      WorshipRepo()
          .markDhikrDone(DateTime.now(), widget.morning ? 'morning' : 'evening');
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('أتممت الورد — سُجّل في سلسلتك ✓',
              'Adhkar complete — added to your streak ✓'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.morning
            ? tr('أذكار الصباح', 'Morning adhkar')
            : tr('أذكار المساء', 'Evening adhkar')),
        actions: [
          IconButton(
            tooltip: tr('تصغير الخط', 'Smaller text'),
            icon: const Icon(Icons.text_decrease),
            onPressed: () => _adjustFont(-2),
          ),
          IconButton(
            tooltip: tr('تكبير الخط', 'Larger text'),
            icon: const Icon(Icons.text_increase),
            onPressed: () => _adjustFont(2),
          ),
        ],
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
                              fontSize: _fontSize,
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
