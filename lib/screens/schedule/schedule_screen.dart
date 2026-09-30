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
import '../../widgets/month_grid.dart';
import '../../widgets/common.dart';
import 'appointment_form.dart';
import 'med_form.dart';
import '../../core/calendar_sync.dart';

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
  List<Appointment> _overdue = [];

  /// كل المواعيد — التقويم محتاج **الشهر كله** مش القادم بس، عشان يحط
  /// نقطة على الأيام اللى فاتت كمان (وده اللى بيخلّى التقويم أرشيف).
  List<Appointment> _all = [];
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = dateOnly(DateTime.now());

  /// كام موعد فى كل يوم — مفتاح `dayKey`.
  Map<String, int> get _counts {
    final m = <String, int>{};
    for (final a in _all) {
      final k = dayKey(a.when);
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  List<Appointment> get _onSelected {
    final d = dateOnly(_selected);
    return [
      for (final a in _all)
        if (dateOnly(a.when) == d) a
    ]..sort((a, b) => a.when.compareTo(b.when));
  }

  /// اللى بعد اليوم المختار — أقرب خمسة، عشان الشاشة تفضل تقول «وبعدين؟».
  List<Appointment> get _afterSelected {
    final d = dateOnly(_selected);
    return [
      for (final a in _all)
        if (!a.done && dateOnly(a.when).isAfter(d)) a
    ].take(5).toList();
  }

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
      _all = all;
      _overdue =
          all.where((a) => !a.done && a.when.isBefore(startOfToday)).toList();
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
    // التاريخ بقى فوق فى عنوان المجموعة، فمفيش لزوم يتكرّر فى كل سطر —
    // ده اللى كان بيخلّى الوصف يتقصّ («عيادة ا…»).
    final bits = <String>[
      if (a.location.isNotEmpty) a.location,
      if (a.category.isNotEmpty) a.category,
      if (a.isRecurring) repeatLabel(a.repeat),
    ];
    final sub = StringBuffer()..write(bits.join(' • '));
    if (a.postponeCount >= 2 && !a.done) {
      sub.write(tr(' • اتأجل ${arNum(a.postponeCount)} مرات',
          ' • postponed ${arNum(a.postponeCount)}×'));
    }
    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: AppListRow(
        title: a.title,
        sub: sub.toString(),
        icon: _apptIcon(a.category),
        tint: overdue ? scheme.error : const Color(0xFF3B82F6),
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
          Text(arTime(a.when),
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
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

  Widget _group(String title, List<Appointment> list,
          {String? trailing, bool faded = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPad(AppGroupHead(title, trail: trailing)),
        for (var i = 0; i < list.length; i++)
          AppPad(_tile(list[i], faded: faded, last: i == list.length - 1)),
      ]);

  /// أيقونة حسب نوع الموعد — عشان تعرف البند من شكله قبل ما تقرا.
  IconData _apptIcon(String category) {
    final c = category.trim();
    if (c.contains('دكتور') || c.contains('عياد') || c.contains('طب')) {
      return Icons.medical_services_outlined;
    }
    if (c.contains('تحليل') || c.contains('معمل') || c.contains('أشعة')) {
      return Icons.science_outlined;
    }
    if (c.contains('عربية') || c.contains('صيانة')) return Icons.build_outlined;
    if (c.contains('شغل') || c.contains('اجتماع')) return Icons.work_outline;
    if (c.contains('مدرسة') || c.contains('جامعة')) return Icons.school_outlined;
    return Icons.event;
  }

  /// عنوان مجموعة اليوم: «النهارده · 29 سبتمبر».
  ///
  /// التجميع باليوم بيخلّى التاريخ يتكتب **مرة واحدة** بدل ما يتكرّر فى
  /// كل سطر ويزحم الوصف.
  String _dayLabel(DateTime d) {
    final diff = dateOnly(d).difference(dateOnly(DateTime.now())).inDays;
    final date = arShortDate(d);
    if (diff == 0) return tr('النهارده · $date', 'Today · $date');
    if (diff == 1) return tr('بكرة · $date', 'Tomorrow · $date');
    return '${arWeekday(d)} · $date';
  }

  /// بيقسّم المواعيد لمجموعات باليوم، بترتيبها.
  List<Widget> _byDay(List<Appointment> list) {
    final groups = <DateTime, List<Appointment>>{};
    for (final a in list) {
      groups.putIfAbsent(dateOnly(a.when), () => []).add(a);
    }
    final days = groups.keys.toList()..sort();
    return [
      for (final d in days)
        _group(_dayLabel(d), groups[d]!, trailing: arNum(groups[d]!.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  AppPad(
                      MonthGrid(
                        month: _month,
                        selected: _selected,
                        counts: _counts,
                        onSelect: (d) => setState(() {
                          _selected = d;
                          _month = DateTime(d.year, d.month, 1);
                        }),
                        onMonthChange: (m) => setState(() => _month = m),
                      ),
                      top: 12,
                      bottom: 4),
                  // الفايت من غير ما يتعمل فوق: عمره ما هتلاقيه وانت
                  // بتتفرّج على التقويم، ولازم تعمل فيه حاجة.
                  if (_overdue.isNotEmpty)
                    _group(tr('فاتت من غير ما تتعمل', 'Missed'), _overdue,
                        trailing: arNum(_overdue.length)),
                  if (_onSelected.isEmpty)
                    AppPad(Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(children: [
                        Icon(Icons.event_available,
                            size: 18, color: scheme.outline),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                              tr('${_dayLabel(_selected)} — مافيش مواعيد',
                                  '${_dayLabel(_selected)} — nothing booked'),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: scheme.onSurfaceVariant)),
                        ),
                      ]),
                    ))
                  else
                    _group(_dayLabel(_selected), _onSelected,
                        trailing: arNum(_onSelected.length)),
                  if (_afterSelected.isNotEmpty)
                    ..._byDay(_afterSelected),
                  const SizedBox(height: 18),
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

  /// بيبعت الجرعات لتقويم الموبايل — حدث يومى متكرّر لكل ميعاد.
  /// شاشة الإضافة بتتفتح لكل ميعاد على حدة (المستخدم بيأكّد)، فبنقول له
  /// العدد الأول عشان مايتفاجأش بأكتر من شاشة.
  Future<void> _addMedToCalendar(Medication m) async {
    final n = m.times.length;
    if (n > 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('هتفتح ${arNum(n)} شاشة — ميعاد لكل جرعة',
              '${arNum(n)} screens will open — one per dose'))));
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    final sent = await CalendarSync.addMedication(m);
    if (!mounted || sent > 0) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('مقدرتش أفتح التقويم', "Couldn't open the calendar"))));
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
                                        case 'calendar':
                                          await _addMedToCalendar(m);
                                        case 'delete':
                                          await _delete(m);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text(tr('تعديل', 'Edit'))),
                                      if (m.times.isNotEmpty)
                                        PopupMenuItem(
                                            value: 'calendar',
                                            child: Text(tr('أضف لتقويم الموبايل',
                                                'Add to phone calendar'))),
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
