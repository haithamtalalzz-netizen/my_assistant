import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/trips_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// السفر — رحلات، كل واحدة بقائمة تجهيز/مهام/حجوزات وميزانية.
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final _repo = TripsRepo();
  bool _loading = true;
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trips = await _repo.all();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('السفر', 'Travel'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _trips.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.flight_takeoff,
                          text: tr('ضيف رحلة بزرار +', 'Add a trip with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [
                        for (final t in _trips)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: const Icon(Icons.luggage),
                              ),
                              title: Text(t.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text([
                                if (t.destination.isNotEmpty) t.destination,
                                if (t.start != null)
                                  arShortDate(t.start!) +
                                      (t.end != null
                                          ? ' → ${arShortDate(t.end!)}'
                                          : ''),
                                if (t.budget > 0) egp(t.budget),
                              ].where((s) => s.isNotEmpty).join('  •  ')),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => _open(t),
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('رحلة جديدة', 'New trip'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _open(Trip t) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => _TripDetail(trip: t)));
    if (mounted) await _load();
  }

  Future<void> _form([Trip? trip]) async {
    final title = TextEditingController(text: trip?.title ?? '');
    final dest = TextEditingController(text: trip?.destination ?? '');
    final budget = TextEditingController(
        text: trip == null || trip.budget == 0 ? '' : trip.budget.toStringAsFixed(0));
    DateTime? start = trip?.start;
    DateTime? end = trip?.end;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(trip == null ? tr('رحلة جديدة', 'New trip') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: title,
                  autofocus: trip == null,
                  decoration: InputDecoration(labelText: tr('العنوان', 'Title'))),
              const SizedBox(height: 8),
              TextField(
                  controller: dest,
                  decoration: InputDecoration(labelText: tr('الوجهة', 'Destination'))),
              const SizedBox(height: 8),
              TextField(
                  controller: budget,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: tr('الميزانية (ج.م)', 'Budget (EGP)'))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: Text(start == null
                        ? tr('من', 'From')
                        : arShortDate(start!))),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => start = d);
                  },
                  child: Text(tr('البداية', 'Start')),
                ),
              ]),
              Row(children: [
                Expanded(
                    child:
                        Text(end == null ? tr('إلى', 'To') : arShortDate(end!))),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: end ?? start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => end = d);
                  },
                  child: Text(tr('النهاية', 'End')),
                ),
              ]),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );

    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(Trip(
        id: trip?.id,
        title: title.text.trim(),
        destination: dest.text.trim(),
        startDay: start == null ? null : dayKey(start!),
        endDay: end == null ? null : dayKey(end!),
        budget: double.tryParse(toEnglishDigits(budget.text.trim())) ?? 0,
        notes: trip?.notes ?? '',
        createdAt: trip?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    dest.dispose();
    budget.dispose();
  }
}

class _TripDetail extends StatefulWidget {
  final Trip trip;
  const _TripDetail({required this.trip});

  @override
  State<_TripDetail> createState() => _TripDetailState();
}

class _TripDetailState extends State<_TripDetail> {
  final _repo = TripsRepo();
  List<TripItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.items(widget.trip.id!);
    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        children: [
          for (final kind in kTripItemKinds) ..._section(kind),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyHint(
                  icon: Icons.checklist,
                  text: tr('ضيف عناصر التجهيز بزرار +',
                      'Add packing items with +')),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _section(String kind) {
    final items = _items.where((i) => i.kind == kind).toList();
    if (items.isEmpty) return [];
    return [
      SectionHeader(tripItemKindLabel(kind)),
      for (final i in items)
        CheckboxListTile(
          dense: true,
          value: i.done,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(i.text,
              style: TextStyle(
                  decoration: i.done ? TextDecoration.lineThrough : null)),
          onChanged: (v) async {
            await _repo.toggleItem(i.id!, v ?? false);
            await _load();
          },
          secondary: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await _repo.deleteItem(i.id!);
              await _load();
            },
          ),
        ),
    ];
  }

  Future<void> _addItem() async {
    var kind = kTripItemKinds.first;
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr('عنصر جديد', 'New item')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final k in kTripItemKinds)
                    ChoiceChip(
                      label: Text(tripItemKindLabel(k)),
                      selected: kind == k,
                      onSelected: (_) => setD(() => kind = k),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: text, autofocus: true),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('إضافة', 'Add'))),
          ],
        ),
      ),
    );
    if (ok == true && text.text.trim().isNotEmpty) {
      await _repo.addItem(widget.trip.id!, kind, text.text.trim());
      await _load();
    }
    text.dispose();
  }
}
