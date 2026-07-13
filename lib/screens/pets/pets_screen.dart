import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/pets_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// الحيوانات الأليفة — قائمة، كل واحد يفتح صفحته بأحداثه (تطعيم/بيطري/أكل).
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final _repo = PetsRepo();
  bool _loading = true;
  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pets = await _repo.pets();
    if (!mounted) return;
    setState(() {
      _pets = pets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الحيوانات الأليفة', 'Pets'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _pets.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.pets,
                          text: tr('ضيف حيوانك بزرار +', 'Add your pet with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [
                        for (final p in _pets)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                child: const Icon(Icons.pets),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: p.species.isEmpty ? null : Text(p.species),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => _open(p),
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('حيوان جديد', 'New pet'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _open(Pet p) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => _PetDetail(pet: p)));
    if (mounted) await _load();
  }

  Future<void> _form([Pet? pet]) async {
    final name = TextEditingController(text: pet?.name ?? '');
    final species = TextEditingController(text: pet?.species ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(pet == null ? tr('حيوان جديد', 'New pet') : tr('تعديل', 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                autofocus: pet == null,
                decoration: InputDecoration(labelText: tr('الاسم', 'Name'))),
            const SizedBox(height: 8),
            TextField(
                controller: species,
                decoration: InputDecoration(
                    labelText: tr('النوع (قطة، كلب…)', 'Species (cat, dog…)'))),
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
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.savePet(Pet(
        id: pet?.id,
        name: name.text.trim(),
        species: species.text.trim(),
        notes: pet?.notes ?? '',
        createdAt: pet?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    name.dispose();
    species.dispose();
  }
}

class _PetDetail extends StatefulWidget {
  final Pet pet;
  const _PetDetail({required this.pet});

  @override
  State<_PetDetail> createState() => _PetDetailState();
}

class _PetDetailState extends State<_PetDetail> {
  final _repo = PetsRepo();
  List<PetEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _repo.events(widget.pet.id!);
    if (!mounted) return;
    setState(() => _events = events);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.pet.name)),
      body: _events.isEmpty
          ? ListView(children: [
              const SizedBox(height: 60),
              EmptyHint(
                  icon: Icons.medical_services_outlined,
                  text: tr('سجّل تطعيم/بيطري/أكل بزرار +',
                      'Log vaccine/vet/food with +')),
            ])
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              children: [
                for (final e in _events)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      dense: true,
                      leading: Icon(_icon(e.type), color: scheme.primary),
                      title: Text(petEventTypeLabel(e.type),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        arShortDate(DateTime.parse(e.day)),
                        if (e.note.isNotEmpty) e.note,
                        if (e.nextDueDate != null)
                          tr('الجاى: ${arShortDate(e.nextDueDate!)}',
                              'Next: ${arShortDate(e.nextDueDate!)}'),
                      ].join('  •  ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          await _repo.deleteEvent(e.id!);
                          await _load();
                        },
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _eventForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _icon(String t) => switch (t) {
        'vaccine' => Icons.vaccines_outlined,
        'vet' => Icons.local_hospital_outlined,
        'food' => Icons.restaurant_outlined,
        _ => Icons.pets,
      };

  Future<void> _eventForm() async {
    var type = kPetEventTypes.first;
    DateTime day = DateTime.now();
    DateTime? nextDue;
    final note = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(tr('حدث جديد', 'New event')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final t in kPetEventTypes)
                    ChoiceChip(
                      label: Text(petEventTypeLabel(t)),
                      selected: type == t,
                      onSelected: (_) => setD(() => type = t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(arShortDate(day))),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: day,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => day = d);
                  },
                  child: Text(tr('التاريخ', 'Date')),
                ),
              ]),
              Row(children: [
                Expanded(
                    child: Text(nextDue == null
                        ? tr('الموعد الجاى (اختيارى)', 'Next due (optional)')
                        : arShortDate(nextDue!))),
                if (nextDue != null)
                  IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setD(() => nextDue = null)),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate:
                          nextDue ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => nextDue = d);
                  },
                  child: Text(tr('الجاى', 'Next')),
                ),
              ]),
              TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: tr('ملاحظة', 'Note'))),
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

    if (saved == true) {
      await _repo.saveEvent(PetEvent(
        petId: widget.pet.id!,
        type: type,
        day: dayKey(day),
        nextDue: nextDue?.toIso8601String(),
        note: note.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    note.dispose();
  }
}
