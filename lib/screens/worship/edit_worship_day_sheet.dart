import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/prayers.dart';
import '../../core/religion_data.dart';
import '../../data/worship_repo.dart';

/// **تعديل عبادات يوم فات.**
///
/// سجل العبادات كان **عرض بس**: تفتح يوم وتشوف «الفجر، الضهر…» ومفيش أى
/// طريقة تسجّل صلاة نسيت تعلّم عليها ولا تشيل علامة بالغلط. اللى فات
/// مايتسجّلش من شاشة اليوم لإنها شغّالة على النهاردة.
///
/// كل بند هنا بيتكتب فورًا على **تاريخ اليوم المفتوح** مش النهاردة.
class EditWorshipDaySheet extends StatefulWidget {
  final DateTime day;

  const EditWorshipDaySheet({super.key, required this.day});

  @override
  State<EditWorshipDaySheet> createState() => _EditWorshipDaySheetState();
}

class _EditWorshipDaySheetState extends State<EditWorshipDaySheet> {
  final _repo = WorshipRepo();
  bool _loading = true;
  bool _changed = false;

  Set<int> _prayed = {};
  Set<String> _dhikr = {};
  Set<String> _sunan = {};
  bool _fasted = false;
  int _pages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.dayReport(widget.day);
    final sunan = await _repo.sunnahDoneOn(widget.day);
    if (!mounted) return;
    setState(() {
      _prayed = r.prayers.toSet();
      _dhikr = r.dhikr.toSet();
      _sunan = sunan;
      _fasted = r.fasted;
      _pages = r.quranPages;
      _loading = false;
    });
  }

  Future<void> _togglePrayer(int i) async {
    final on = !_prayed.contains(i);
    await _repo.togglePrayer(widget.day, i, on);
    setState(() {
      _changed = true;
      on ? _prayed.add(i) : _prayed.remove(i);
    });
  }

  Future<void> _toggleDhikr(String kind) async {
    final on = !_dhikr.contains(kind);
    await _repo.setDhikrDone(widget.day, kind, on);
    setState(() {
      _changed = true;
      on ? _dhikr.add(kind) : _dhikr.remove(kind);
    });
  }

  Future<void> _toggleSunnah(String name) async {
    final on = !_sunan.contains(name);
    await _repo.toggleSunnah(widget.day, name, on);
    setState(() {
      _changed = true;
      on ? _sunan.add(name) : _sunan.remove(name);
    });
  }

  Future<void> _setFasted(bool v) async {
    await _repo.setFasted(widget.day, v);
    setState(() {
      _changed = true;
      _fasted = v;
    });
  }

  Future<void> _setPages(int v) async {
    final next = v.clamp(0, 604);
    if (next == _pages) return;
    await _repo.setQuranPagesOn(widget.day, next);
    setState(() {
      _changed = true;
      _pages = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => _loading
            ? const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator()))
            : ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(arFullDate(widget.day),
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      child: Text(tr('تمّ', 'Done')),
                    ),
                  ]),
                  Text(
                      tr('دوس على أى حاجة تسجّلها أو تشيلها',
                          'Tap anything to add or remove it'),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  _label(tr('الصلوات', 'Prayers'),
                      '${arNum(_prayed.length)}/${arNum(kPrayerNames.length)}'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < kPrayerNames.length; i++)
                      _chip(prayerNameLabel(i), _prayed.contains(i),
                          () => _togglePrayer(i)),
                  ]),
                  const SizedBox(height: 18),

                  _label(tr('الأذكار', 'Adhkar'), ''),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(tr('الصباح', 'Morning'), _dhikr.contains('morning'),
                        () => _toggleDhikr('morning')),
                    _chip(tr('المساء', 'Evening'), _dhikr.contains('evening'),
                        () => _toggleDhikr('evening')),
                  ]),
                  const SizedBox(height: 18),

                  _label(tr('الصيام', 'Fasting'), ''),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _fasted,
                    onChanged: _setFasted,
                    title: Text(_fasted
                        ? tr('صُمت اليوم ده', 'Fasted this day')
                        : tr('مصُمتش', 'Did not fast')),
                  ),
                  const SizedBox(height: 6),

                  _label(tr('قراءة القرآن', 'Quran'),
                      tr('${arNum(_pages)} صفحة', '${arNum(_pages)} pages')),
                  Row(children: [
                    IconButton.filledTonal(
                      onPressed: () => _setPages(_pages - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          tr('${arNum(_pages)} صفحة', '${arNum(_pages)} pages'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () => _setPages(_pages + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  _label(tr('سنن ونوافل', 'Sunnah'),
                      arNum(_sunan.length)),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final s in kSunanItems)
                      _chip(s.name, _sunan.contains(s.name),
                          () => _toggleSunnah(s.name)),
                  ]),
                  const SizedBox(height: 10),

                  // الوِرد بنود بعدّادات مستقلة — تعديله من هنا هيبقى شاشة
                  // لوحدها، فبنقول مكانه بدل ما نوهمه إنه مش موجود.
                  Text(
                      tr('الوِرد بيتسجّل من صفحة «وردى اليومى»',
                          'Wird is logged from the Daily Wird screen'),
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
      ),
    );
  }

  Widget _label(String text, String trailing) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          if (trailing.isNotEmpty)
            Text(trailing,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      );

  Widget _chip(String label, bool on, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: on ? scheme.primary : scheme.outlineVariant),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(on ? Icons.check : Icons.add,
              size: 16, color: on ? scheme.onPrimary : scheme.outline),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: on ? scheme.onPrimary : scheme.onSurface)),
        ]),
      ),
    );
  }
}
