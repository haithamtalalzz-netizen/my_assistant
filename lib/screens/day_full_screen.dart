import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_timeline.dart';
import '../core/l10n.dart';
import '../widgets/a_kit.dart';

/// **يومك بالكامل** — كل بنود النهارده: اللى خلص واللى فات واللى جاى.
///
/// ليه الصفحة دى موجودة: الرئيسية بتعرض **مختصر** (آخر ٣ فايتين + بندين
/// ماضيين بس) عشان ماتبقاش جدار، فالبند اللى تعلّم عليه «تمّ» بيختفى من
/// قدامك — وماكانش فيه أى طريقة تشوف الإجمالى ولا **ترجّع** علامة غلط.
/// هنا كل حاجة باينة، وكل سطر بيتقلب فى الاتجاهين بضغطة.
class DayFullScreen extends StatefulWidget {
  final List<TimelineEvent> events;

  /// بيتنادى لمّا المستخدم يقلب حالة بند — بيرجّع القايمة بعد التحديث.
  final Future<List<TimelineEvent>> Function(TimelineEvent e, bool done)
      onToggle;

  /// بيفتح صفحة البند نفسه.
  final void Function(TimelineEvent e) onOpen;

  const DayFullScreen({
    super.key,
    required this.events,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  State<DayFullScreen> createState() => _DayFullScreenState();
}

class _DayFullScreenState extends State<DayFullScreen> {
  late List<TimelineEvent> _events = widget.events;
  bool _busy = false;

  Future<void> _toggle(TimelineEvent e) async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = await widget.onToggle(e, !e.done);
    if (!mounted) return;
    setState(() {
      _events = next;
      _busy = false;
    });
  }

  Color _kindColor(TimelineKind k, ColorScheme s) => switch (k) {
        TimelineKind.prayer => s.primary,
        TimelineKind.appointment => Colors.blue,
        TimelineKind.med => Colors.pink,
        TimelineKind.task => Colors.orange,
      };

  IconData _kindIcon(TimelineKind k) => switch (k) {
        TimelineKind.prayer => Icons.mosque,
        TimelineKind.appointment => Icons.event,
        TimelineKind.med => Icons.medication_outlined,
        TimelineKind.task => Icons.checklist,
      };

  String _kindLabel(TimelineKind k) => switch (k) {
        TimelineKind.prayer => tr('صلاة', 'Prayer'),
        TimelineKind.appointment => tr('موعد', 'Appointment'),
        TimelineKind.med => tr('دوا', 'Medicine'),
        TimelineKind.task => tr('مهمة', 'Task'),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final p = dayTimelineProgress(_events);
    final missed = [
      for (final e in _events)
        if (!e.done && e.at.isBefore(now)) e
    ];
    final upcoming = [
      for (final e in _events)
        if (!e.done && !e.at.isBefore(now)) e
    ];
    final done = [
      for (final e in _events)
        if (e.done) e
    ];

    Widget section(String title, List<TimelineEvent> list,
        {String? hint, bool missed = false}) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppPad(AppGroupHead(title, trail: arNum(list.length))),
        if (hint != null)
          AppPad(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(hint,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ),
          ),
        for (var i = 0; i < list.length; i++)
          AppPad(_row(list[i], last: i == list.length - 1, missed: missed)),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('يومك بالكامل', 'Your full day'))),
      body: _events.isEmpty
          ? Center(
              child: Text(tr('مفيش بنود النهارده', 'Nothing scheduled today'),
                  style: TextStyle(color: scheme.outline)),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 32),
              children: [
                AppPad(
                  AppCard(Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        tr('${arNum(p.done)} من ${arNum(p.total)} خلصوا',
                            '${arNum(p.done)} of ${arNum(p.total)} done'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                          value: p.total == 0 ? 0 : p.done / p.total,
                          minHeight: 8),
                    ),
                  ])),
                  bottom: 18,
                ),
                section(tr('فاتك', 'Missed'), missed, missed: true),
                section(tr('الجاى', 'Coming up'), upcoming),
                section(
                  tr('خلصت', 'Done'),
                  done,
                  hint: tr('دوس على العلامة عشان ترجّعها لو علّمت بالغلط',
                      'Tap the check to undo if you marked it by mistake'),
                ),
              ],
            ),
    );
  }

  /// [missed] بيخلّى الدايرة **والتوقيت** أحمر مع بعض — كانت الدايرة
  /// حمرا والتوقيت أخضر فالسطر يبان متناقض. غير كده كل نوع بلونه
  /// (موعد أزرق · مهمة برتقالى) عشان تفرّقهم من نظرة.
  Widget _row(TimelineEvent e, {bool last = false, bool missed = false}) {
    final scheme = Theme.of(context).colorScheme;
    final tint = missed ? scheme.error : _kindColor(e.kind, scheme);
    final color = e.done ? scheme.primary : tint;
    // نفس سطر الرئيسية بالظبط: أيقونة نوع البند + الوقت + مربّع بيتقفل
    // ويترجّع. (كان كارت لكل مجموعة، والصفحة تطلع صناديق جوّه صناديق.)
    return AppListRow(
      title: e.title,
      sub: e.sub.isEmpty
          ? _kindLabel(e.kind)
          : '${_kindLabel(e.kind)} • ${e.sub}',
      icon: _kindIcon(e.kind),
      tint: color,
      check: true,
      checked: e.done,
      divider: !last,
      onCheck: _busy ? null : () => _toggle(e),
      onTap: () => widget.onOpen(e),
      trailing: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(e.timeLabel,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
      ),
    );
  }
}
