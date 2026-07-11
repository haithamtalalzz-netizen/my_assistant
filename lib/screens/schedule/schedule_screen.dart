import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/appointments_repo.dart';
import '../../data/meds_repo.dart';
import '../../core/contacts_import.dart';
import '../../data/occasions_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'appointment_form.dart';
import 'med_form.dart';
import 'occasion_form.dart';

class ScheduleScreen extends StatelessWidget {
  final Widget? drawer;

  const ScheduleScreen({super.key, this.drawer});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: drawer,
        appBar: AppBar(
          title: Text(tr('الجدول', 'Schedule')),
          actions: [searchAction(context)],
          bottom: TabBar(tabs: [
            Tab(text: tr('المواعيد', 'Appointments')),
            Tab(text: tr('الأدوية', 'Medications')),
            Tab(text: tr('المناسبات', 'Occasions')),
          ]),
        ),
        body: const TabBarView(
            children: [_AppointmentsTab(), _MedsTab(), _OccasionsTab()]),
      ),
    );
  }
}

class _OccasionsTab extends StatefulWidget {
  const _OccasionsTab();

  @override
  State<_OccasionsTab> createState() => _OccasionsTabState();
}

class _OccasionsTabState extends State<_OccasionsTab> {
  final _repo = OccasionsRepo();
  bool _loading = true;
  List<Occasion> _occasions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final occasions = await _repo.all();
    final now = DateTime.now();
    occasions.sort(
        (a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
    if (!mounted) return;
    setState(() {
      _occasions = occasions;
      _loading = false;
    });
  }

  Future<void> _openForm([Occasion? o]) async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => OccasionForm(occasion: o)));
    if (saved == true && mounted) await _load();
  }

  String _countdown(Occasion o) {
    final days = o
        .nextOccurrence(DateTime.now())
        .difference(dateOnly(DateTime.now()))
        .inDays;
    if (days == 0) return tr('النهارده! 🎉', 'Today! 🎉');
    if (days == 1) return tr('بكرة', 'Tomorrow');
    return tr('باقي ${arNum(days)} يوم', 'in ${arNum(days)} days');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _occasions.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.cake_outlined,
                          text:
                              tr('مفيش مناسبات متسجلة — ضيف أعياد الميلاد\nوالمناسبات المهمة وهفكرك قبلها',
                                  'No occasions — add birthdays\nand key dates, reminded ahead')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        for (final o in _occasions)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: scheme.secondaryContainer,
                                child: Icon(Icons.cake_outlined,
                                    color: scheme.onSecondaryContainer),
                              ),
                              title: Text(o.person.isEmpty
                                  ? o.title
                                  : '${o.title} — ${o.person}'),
                              subtitle: Text(
                                  '${arShortDate(o.nextOccurrence(DateTime.now()))} • ${_countdown(o)}'),
                              onTap: () => _openForm(o),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  switch (v) {
                                    case 'edit':
                                      await _openForm(o);
                                    case 'delete':
                                      if (!await confirmDelete(context,
                                          tr('المناسبة "${o.title}"', 'occasion "${o.title}"'))) {
                                        return;
                                      }
                                      await _repo.delete(o.id!);
                                      if (mounted) await _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(tr('تعديل', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(tr('حذف', 'Delete'))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'occasion_import_fab',
            onPressed: _importContacts,
            tooltip: tr('استيراد أعياد الميلاد', 'Import birthdays'),
            child: const Icon(Icons.contacts_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'occasion_fab',
            onPressed: () => _openForm(),
            tooltip: tr('مناسبة جديدة', 'New occasion'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _importContacts() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('بستورد أعياد الميلاد...', 'Importing birthdays...'))));
    final n = await ContactsImport.importBirthdays();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (n == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('محتاج إذن جهات الاتصال', 'Contacts permission needed'))));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(n == 0
            ? tr('مفيش أعياد ميلاد جديدة', 'No new birthdays found')
            : tr('اتضاف ${arNum(n)} عيد ميلاد', 'Added ${arNum(n)} birthdays'))));
    await _load();
  }
}

class _AppointmentsTab extends StatefulWidget {
  const _AppointmentsTab();

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  final _repo = AppointmentsRepo();
  bool _loading = true;
  List<Appointment> _upcoming = [];
  List<Appointment> _overdue = [];
  List<Appointment> _done = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.all();
    final startOfToday = dateOnly(DateTime.now());
    if (!mounted) return;
    setState(() {
      _upcoming = all
          .where((a) => !a.done && !a.when.isBefore(startOfToday))
          .toList();
      _overdue =
          all.where((a) => !a.done && a.when.isBefore(startOfToday)).toList();
      _done = all.where((a) => a.done).toList().reversed.take(20).toList();
      _loading = false;
    });
  }

  Future<void> _openForm([Appointment? a]) async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => AppointmentForm(appointment: a)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Appointment a) async {
    if (!await confirmDelete(
        context, tr('الموعد "${a.title}"', 'appointment "${a.title}"'))) {
      return;
    }
    await _repo.delete(a.id!);
    if (mounted) await _load();
  }

  Widget _tile(Appointment a, {bool faded = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Opacity(
        opacity: faded ? 0.6 : 1,
        child: ListTile(
          leading: Checkbox(
            value: a.done,
            onChanged: (_) async {
              HapticFeedback.selectionClick();
              await _repo.setDone(a.id!, !a.done);
              if (mounted) await _load();
            },
          ),
          title: Row(
            children: [
              Flexible(child: Text(a.title)),
              if (a.isRecurring) ...[
                const SizedBox(width: 6),
                Icon(Icons.repeat, size: 15, color: scheme.primary),
              ],
            ],
          ),
          subtitle: Text(
              '${arFullDate(a.when)} • ${arTime(a.when)} • ${a.category}'
              '${a.isRecurring ? ' • ${repeatLabel(a.repeat)}' : ''}'
              '${a.postponeCount >= 2 && !a.done ? tr(' • اتأجل ${arNum(a.postponeCount)} مرات', ' • postponed ${arNum(a.postponeCount)}×') : ''}'
              '${a.notes.isEmpty ? '' : '\n${a.notes}'}'),
          isThreeLine: a.notes.isNotEmpty,
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'edit':
                  await _openForm(a);
                case 'delete':
                  await _delete(a);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
              PopupMenuItem(
                  value: 'delete', child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  if (_overdue.isNotEmpty) ...[
                    SectionHeader(tr('فاتت من غير ما تتعمل', 'Missed')),
                    ..._overdue.map((a) => _tile(a)),
                  ],
                  SectionHeader(tr('القادمة', 'Upcoming')),
                  if (_upcoming.isEmpty)
                    EmptyHint(
                        icon: Icons.event_available,
                        text: tr('مفيش مواعيد قادمة — ضيف موعد بزرار +',
                            'No upcoming appointments — add one with +'))
                  else
                    ..._upcoming.map((a) => _tile(a)),
                  if (_done.isNotEmpty) ...[
                    SectionHeader(tr('اللي تمت', 'Done')),
                    ..._done.map((a) => _tile(a, faded: true)),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'appt_fab',
        onPressed: () => _openForm(),
        tooltip: tr('موعد جديد', 'New appointment'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MedsTab extends StatefulWidget {
  const _MedsTab();

  @override
  State<_MedsTab> createState() => _MedsTabState();
}

class _MedsTabState extends State<_MedsTab> {
  final _repo = MedsRepo();
  bool _loading = true;
  List<Medication> _meds = [];
  Set<String> _taken = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await _repo.all();
    final taken = await _repo.takenOn(dayKey(DateTime.now()));
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _taken = taken;
      _loading = false;
    });
  }

  Future<void> _openForm([Medication? m]) async {
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => MedForm(medication: m)));
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Medication m) async {
    if (!await confirmDelete(
        context, tr('الدواء "${m.name}"', 'medication "${m.name}"'))) {
      return;
    }
    await _repo.delete(m.id!);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _meds.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      EmptyHint(
                          icon: Icons.medication_outlined,
                          text: tr('مفيش أدوية متسجلة — ضيف دواء بزرار +',
                              'No medications — add one with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        for (final m in _meds)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Switch(
                                    value: m.active,
                                    onChanged: (v) async {
                                      await _repo.setActive(m.id!, v);
                                      if (mounted) await _load();
                                    },
                                  ),
                                  title: Text(m.name),
                                  subtitle: Text([
                                    if (m.form.isNotEmpty || m.unit.isNotEmpty)
                                      [m.form, m.unit]
                                          .where((s) => s.isNotEmpty)
                                          .join(' — '),
                                    if (m.dosage.isNotEmpty) m.dosage,
                                    if (!m.active)
                                      m.times.map(arTimeOfSlot).join(' • '),
                                    if (m.daysLeft(DateTime.now()) != null)
                                      m.daysLeft(DateTime.now())! > 0
                                          ? tr('كورس — باقي ${arNum(m.daysLeft(DateTime.now())!)} أيام',
                                              'Course — ${arNum(m.daysLeft(DateTime.now())!)} days left')
                                          : tr('الكورس خلص', 'Course ended'),
                                    if (m.notes.isNotEmpty) m.notes,
                                  ].where((s) => s.isNotEmpty).join('\n')),
                                  isThreeLine: m.dosage.isNotEmpty ||
                                      m.notes.isNotEmpty,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      switch (v) {
                                        case 'edit':
                                          await _openForm(m);
                                        case 'delete':
                                          await _delete(m);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text(tr('تعديل', 'Edit'))),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text(tr('حذف', 'Delete'))),
                                    ],
                                  ),
                                ),
                                // جرعات النهاردة — تعلّم منها المتاخد.
                                if (m.active && m.times.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          for (final s in m.times)
                                            FilterChip(
                                              label: Text(arTimeOfSlot(s)),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              selected:
                                                  _taken.contains('${m.id}|$s'),
                                              onSelected: (v) async {
                                                HapticFeedback.selectionClick();
                                                await _repo.setTaken(m.id!,
                                                    dayKey(DateTime.now()), s, v);
                                                if (mounted) await _load();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'med_fab',
        onPressed: () => _openForm(),
        tooltip: tr('دواء جديد', 'New medication'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
