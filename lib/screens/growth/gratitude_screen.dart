import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/gratitude_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// مفكرة الامتنان — سجّل كل يوم حاجات إنت شاكر عليها.
class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final _repo = GratitudeRepo();
  final _input = TextEditingController();
  bool _loading = true;
  List<GratitudeEntry> _items = [];
  int _days = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.recent();
    final days = await _repo.daysCount();
    if (!mounted) return;
    setState(() {
      _items = items;
      _days = days;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    await _repo.add(t);
    _input.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('مفكرة الامتنان', 'Gratitude journal'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          decoration: InputDecoration(
                              labelText: tr('شاكر على إيه النهاردة؟',
                                  "What are you grateful for today?")),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                          onPressed: _add, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                if (_days > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                          tr('🙏 سجّلت امتنان فى ${arNum(_days)} يوم',
                              '🙏 gratitude on ${arNum(_days)} days'),
                          style: TextStyle(
                              fontSize: 12, color: scheme.outline)),
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyHint(
                          icon: Icons.favorite_outline,
                          text: tr('اكتب أول حاجة إنت شاكر عليها فوق',
                              'Write your first gratitude above'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          children: [for (final g in _items) _tile(g, scheme)],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tile(GratitudeEntry g, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: const Text('🙏', style: TextStyle(fontSize: 20)),
        title: Text(g.text),
        subtitle: Text(arShortDate(DateTime.parse(g.day)),
            style: TextStyle(fontSize: 11, color: scheme.outline)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () async {
            await _repo.delete(g.id!);
            await _load();
          },
        ),
      ),
    );
  }
}
