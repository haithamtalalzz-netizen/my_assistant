import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import 'appointments_calendar_screen.dart';
import '../../core/l10n.dart';
import '../../widgets/search_action.dart';
import '../../data/appointments_repo.dart';
import '../../data/meds_repo.dart';
import '../../models/models.dart';
import '../../widgets/a_kit.dart';
import '../../widgets/common.dart';
import 'appointment_form.dart';
import 'med_form.dart';

class ScheduleScreen extends StatelessWidget {
  final Widget? drawer;

  const ScheduleScreen({super.key, this.drawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      appBar: AppBar(
        // البند فى السايدبار اسمه «مواعيدى» وبيفتح الصفحة دى مباشرةً
        // (زر «عرض شهري» جوّاها بيفتح التقويم — البند المستقل القديم اتشال).
        title: Text(tr('مواعيدى', 'My calendar')),
        actions: [
          searchAction(context),
          IconButton(
            tooltip: tr('عرض شهري', 'Month view'),
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AppointmentsCalendarScreen())),
          ),
        ],
      ),
      body: const _AppointmentsTab(),
    );
  }
}

/// شاشة الأدوية مستقلة — تُفتح من مجموعة «الصحة» فى السايدبار.
class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(tr('الأدوية', 'Medications')),
          actions: [searchAction(context)],
        ),
        body: const _MedsTab(),
      );
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

  /// سطر موعد جوّه كارت القسم — نفس الإجراءات القديمة بالظبط.
  Widget _tile(Appointment a, {bool faded = false, bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = !a.done && a.when.isBefore(dateOnly(DateTime.now()));
    final sub = StringBuffer()
      ..write('${arFullDate(a.when)} • ${arTime(a.when)}');
    if (a.category.isNotEmpty) sub.write(' • ${a.category}');
    if (a.location.isNotEmpty) sub.write(' • ${a.location}');
    if (a.isRecurring) sub.write(' • ${repeatLabel(a.repeat)}');
    if (a.postponeCount >= 2 && !a.done) {
      sub.write(tr(' • اتأجل ${arNum(a.postponeCount)} مرات',
          ' • postponed ${arNum(a.postponeCount)}×'));
    }
    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: AppListRow(
        title: a.title,
        sub: sub.toString(),
        check: true,
        checked: a.done,
        divider: !last,
        onTap: () => _openForm(a),
        onCheck: () async {
          HapticFeedback.selectionClick();
          await _repo.setDone(a.id!, !a.done);
          if (mounted) await _load();
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (a.isRecurring)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.repeat, size: 15, color: scheme.primary),
            ),
          if (overdue)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.priority_high, size: 16, color: scheme.error),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
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
              PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
            ],
          ),
        ]),
      ),
    );
  }

  /// أقرب موعد جاى — البطل.
  Appointment? get _next {
    final now = DateTime.now();
    final future = [
      for (final a in _upcoming)
        if (!a.when.isBefore(now)) a
    ]..sort((x, y) => x.when.compareTo(y.when));
    return future.isEmpty ? null : future.first;
  }

  String _whenLabel(DateTime when) {
    final mins = when.difference(DateTime.now()).inMinutes;
    if (mins < 0) return tr('فات', 'passed');
    if (mins < 60) return tr('بعد ${arNum(mins)} دقيقة', 'in ${arNum(mins)} min');
    final hours = mins ~/ 60;
    if (hours < 24) {
      return tr('بعد ${arNum(hours)} ساعات', 'in ${arNum(hours)}h');
    }
    final days = when.difference(dateOnly(DateTime.now())).inDays;
    return days == 1
        ? tr('بكرة', 'tomorrow')
        : tr('بعد ${arNum(days)} أيام', 'in ${arNum(days)} days');
  }

  Widget _hero() {
    final a = _next;
    if (a == null) {
      return AppHero(
        icon: Icons.event_available,
        kicker: tr('مواعيدك', 'Your calendar'),
        title: _overdue.isEmpty
            ? tr('مفيش مواعيد قادمة', 'No upcoming appointments')
            : tr('فيه مواعيد فاتت', 'Some appointments were missed'),
        primaryLabel: tr('موعد جديد', 'New appointment'),
        primaryIcon: Icons.add,
        onPrimary: _openForm,
      );
    }
    return AppHero(
      icon: Icons.event,
      kicker: tr('أقرب موعد', 'Next appointment'),
      title: a.title,
      trailingBig: arTime(a.when),
      trailingSmall: _whenLabel(a.when),
      primaryLabel: tr('تم', 'Done'),
      primaryIcon: Icons.check,
      onPrimary: () async {
        await _repo.setDone(a.id!, true);
        if (mounted) await _load();
      },
      secondaryLabel: tr('التفاصيل', 'Details'),
      onSecondary: () => _openForm(a),
      colors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      extra: (a.location.isEmpty && a.notes.isEmpty)
          ? null
          : Row(children: [
              Icon(a.location.isEmpty ? Icons.notes : Icons.place_outlined,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                    a.location.isEmpty ? a.notes : a.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
            ]),
    );
  }

  Widget _group(String title, List<Appointment> list,
          {String? trailing, bool faded = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPad(AppSectionTitle(title, trailing: trailing)),
        AppPad(AppCard(Column(children: [
          for (var i = 0; i < list.length; i++)
            _tile(list[i], faded: faded, last: i == list.length - 1),
        ]))),
        const SizedBox(height: 18),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading

          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  AppPad(_hero(), top: 12, bottom: 20),
                  if (_overdue.isNotEmpty)
                    _group(tr('فاتت من غير ما تتعمل', 'Missed'), _overdue,
                        trailing: arNum(_overdue.length)),
                  if (_upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: EmptyHint(
                        icon: Icons.event_available,
                        text: tr('مفيش مواعيد قادمة — ضيف موعد بزرار +',
                            'No upcoming appointments — add one with +'),
                        actionLabel: tr('ضيف موعد', 'Add appointment'),
                        onAction: _openForm,
                      ),
                    )
                  else
                    _group(tr('القادمة', 'Upcoming'), _upcoming,
                        trailing: arNum(_upcoming.length)),
                  if (_done.isNotEmpty)
                    _group(tr('اللي تمت', 'Done'), _done, faded: true),
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

  /// بانر «قرب يخلص» — أدوية الكورس الباقى لها ٣ أيام أو أقل.
  Widget _refillBanner(BuildContext context) {
    final now = DateTime.now();
    final soon = _meds.where((m) {
      if (!m.active) return false;
      final d = m.daysLeft(now);
      return d != null && d >= 0 && d <= 3;
    }).toList();
    if (soon.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    const amber = Color(0xFFB26A00);
    String left(Medication m) {
      final d = m.daysLeft(now)!;
      return d == 0
          ? tr('يخلص النهاردة', 'runs out today')
          : tr('باقى ${arNum(d)} يوم', '$d day(s) left');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.medication_liquid_outlined,
                size: 18, color: amber),
            const SizedBox(width: 6),
            Text(tr('أدوية قربت تخلص — جهّز إعادة الصرف',
                'Meds running low — arrange a refill'),
                style: const TextStyle(
                    color: amber, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ]),
          const SizedBox(height: 6),
          for (final m in soon)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text('• ${m.name} — ${left(m)}',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant)),
            ),
        ],
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
                        _refillBanner(context),
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
