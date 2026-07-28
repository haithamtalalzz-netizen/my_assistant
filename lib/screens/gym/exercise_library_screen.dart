import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/exercise_library.dart';
import '../../core/l10n.dart';
import '../../data/settings_repo.dart';
import '../../widgets/search_action.dart';

/// مكتبة التمارين — استعراض التمارين بالعضلة والمعدّات مع طريقة الأداء.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _muscle = 'all';
  String _equip = 'all'; // all / none / <equipment key>
  String _query = '';
  bool _favOnly = false;
  Set<String> _favs = {};
  static const _kFavs = 'gym_fav_exercises';

  @override
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final raw = await SettingsRepo().get(_kFavs) ?? '';
    if (raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => '$e').toSet();
      if (mounted) setState(() => _favs = list);
    } on FormatException {
      // مخزّن تالف — نتجاهله.
    }
  }

  Future<void> _toggleFav(String name) async {
    setState(() =>
        _favs.contains(name) ? _favs.remove(name) : _favs.add(name));
    await SettingsRepo().set(_kFavs, jsonEncode(_favs.toList()));
  }

  List<Exercise> get _filtered {
    final q = _query.trim().toLowerCase();
    return filterExercises(muscle: _muscle, equipment: _equip).where((e) {
      if (_favOnly && !_favs.contains(e.name)) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          muscleLabel(e.muscle).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('مكتبة التمارين', 'Exercise library')),
        actions: [searchAction(context)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: tr('ابحث عن تمرين…', 'Search exercises…'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // فلتر العضلات.
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _chip('⭐ ${tr('المفضّلة', 'Favorites')}', _favOnly,
                    () => setState(() => _favOnly = !_favOnly)),
                _chip(tr('كل العضلات', 'All muscles'), _muscle == 'all',
                    () => setState(() => _muscle = 'all')),
                for (final m in kMuscles)
                  _chip('${muscleEmoji(m)} ${muscleLabel(m)}', _muscle == m,
                      () => setState(() => _muscle = m)),
              ],
            ),
          ),
          // فلتر المعدّات.
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(tr('الكل', 'All'), _equip == 'all',
                    () => setState(() => _equip = 'all')),
                _chip(tr('🏠 بدون معدّات', '🏠 No gear'), _equip == 'none',
                    () => setState(() => _equip = 'none')),
                for (final e in kEquipment)
                  _chip(equipmentLabel(e), _equip == e,
                      () => setState(() => _equip = e)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(tr('مفيش تمارين بالفلتر ده', 'No exercises for this filter'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _exerciseCard(list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(Exercise e) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(muscleEmoji(e.muscle),
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${muscleLabel(e.muscle)} • ${equipmentLabel(e.equipment)} • ${e.reps}',
            style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: Icon(
              _favs.contains(e.name) ? Icons.star : Icons.star_border,
              color: _favs.contains(e.name) ? Colors.amber : scheme.outline),
          onPressed: () => _toggleFav(e.name),
        ),
        onTap: () => _showDetail(e),
      ),
    );
  }

  void _showDetail(Exercise e) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(muscleEmoji(e.muscle), style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _tag('${muscleEmoji(e.muscle)} ${muscleLabel(e.muscle)}'),
                _tag(equipmentLabel(e.equipment)),
                _tag('🔁 ${e.reps}'),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('طريقة الأداء', 'How to do it'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(e.howTo, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Chip(
        visualDensity: VisualDensity.compact,
        label: Text(text, style: const TextStyle(fontSize: 12)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
