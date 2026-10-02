import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_timeline.dart';
import '../core/l10n.dart';
import '../core/privacy.dart';
import '../widgets/a_kit.dart';

/// أى مجموعة الصفحة مفتوحة عليها.
enum DayFilter { all, missed, upcoming, done }

/// **خط اليوم** — كل بنود النهارده **بترتيب الساعة**، من الفجر للعشا.
///
/// ليه الترتيب الزمنى بدل المجموعات (فاتك/الجاى/خلصت):
/// لمّا البنود تتفرز لمجموعات، الدوا اللى اتاخد الساعة ٨ الصبح بينزل
/// آخر الصفحة تحت «خلصت» — بعيد عن مكانه فى يومك. الورقة ساعتها بتقول
/// «إيه حالته» بس ماتقولش «اليوم عدّى إزاى». الترتيب الزمنى بيخلّى
/// **اللى خلص يفضل مكانه**، فالصفحة تتقرا زى يومك ما حصل بالظبط.
///
/// الشرايط فوق لسه بتفلتر (فاتوا/جايين/خلصوا) — عشان لو انت عايز حاجة
/// بعينها، بس الافتراضى هو اليوم كامل بترتيبه.
class DayFullScreen extends StatefulWidget {
  final List<TimelineEvent> events;

  /// بيتنادى لمّا المستخدم يقلب حالة بند — بيرجّع القايمة بعد التحديث.
  final Future<List<TimelineEvent>> Function(TimelineEvent e, bool done)
      onToggle;

  /// بيفتح صفحة البند نفسه.
  final void Function(TimelineEvent e) onOpen;

  /// الصفحة بتفتح على المجموعة دى (الرئيسية بتبعتها لمّا تدوس على رقم).
  final DayFilter filter;

  const DayFullScreen({
    super.key,
    required this.events,
    required this.onToggle,
    required this.onOpen,
    this.filter = DayFilter.all,
  });

  @override
  State<DayFullScreen> createState() => _DayFullScreenState();
}

class _DayFullScreenState extends State<DayFullScreen> {
  late List<TimelineEvent> _events = widget.events;
  late DayFilter _filter = widget.filter;
  bool _busy = false;

  /// بيتثبّت مرة واحدة عند الفتح.
  ///
  /// 🔴 لو الوقت اتقرا فى كل `build`، بند على حدّ «دلوقتى» كان هيقفز من
  /// «جاى» لـ«فات» فى نُص تفاعل المستخدم — والخط اللى بيقول «دلوقتى»
  /// كان هيتحرك تحت إيده.
  final DateTime _now = DateTime.now();

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

  bool _isMissed(TimelineEvent e) => !e.done && e.at.isBefore(_now);

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

  List<TimelineEvent> get _shown {
    final all = [..._events]..sort((a, b) => a.at.compareTo(b.at));
    return switch (_filter) {
      DayFilter.all => all,
      DayFilter.missed => [for (final e in all) if (_isMissed(e)) e],
      DayFilter.upcoming => [
          for (final e in all)
            if (!e.done && !_isMissed(e)) e
        ],
      DayFilter.done => [for (final e in all) if (e.done) e],
    };
  }

  Widget _chips() {
    final scheme = Theme.of(context).colorScheme;
    final missed = _events.where(_isMissed).length;
    final doneN = _events.where((e) => e.done).length;
    final up = _events.length - missed - doneN;

    Widget chip(DayFilter f, String label, int? n, Color? c) {
      final on = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(left: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () => setState(() => _filter = f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: on ? (c ?? scheme.primary) : scheme.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: on ? (c ?? scheme.primary) : scheme.outlineVariant),
            ),
            child: Text(n == null ? label : '$label ${arNum(n)}',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : scheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip(DayFilter.all, tr('الكل', 'All'), null, null),
        chip(DayFilter.missed, tr('فاتوا', 'Missed'), missed, scheme.error),
        chip(DayFilter.upcoming, tr('جايين', 'Coming'), up, Colors.blue),
        chip(DayFilter.done, tr('خلصوا', 'Done'), doneN, scheme.primary),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = dayTimelineProgress(_events);
    final shown = _shown;
    final missedN = _events.where(_isMissed).length;

    // مكان خط «دلوقتى»: أول بند لسه ما جاش وقته. -1 يعنى اليوم كله عدّى.
    final nowAt = _filter == DayFilter.all
        ? shown.indexWhere((e) => !e.at.isBefore(_now))
        : -1;

    return Scaffold(
      appBar: AppBar(
        actions: const [PrivacyAction()],
        title: Text(tr('خط اليوم', 'Day timeline')),
      ),
      body: _events.isEmpty
          ? Center(
              child: Text(tr('مفيش بنود النهارده', 'Nothing scheduled today'),
                  style: TextStyle(color: scheme.outline)),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 32),
              children: [
                AppPad(AppCard(Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              tr('${arNum(p.done)} من ${arNum(p.total)} خلصوا',
                                  '${arNum(p.done)} of ${arNum(p.total)} done'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: p.total == 0 ? 0 : p.done / p.total,
                              minHeight: 8,
                              backgroundColor:
                                  scheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ]),
                  ),
                  if (missedN > 0) ...[
                    const SizedBox(width: 14),
                    Column(children: [
                      Text(arNum(missedN),
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: scheme.error)),
                      Text(tr('فاتوا', 'missed'),
                          style: TextStyle(
                              fontSize: 9.5, color: scheme.onSurfaceVariant)),
                    ]),
                  ],
                ]))),
                AppPad(_chips(), top: 14, bottom: 6),
                if (shown.isEmpty)
                  AppPad(Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(tr('مفيش حاجة هنا', 'Nothing here'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.outline)),
                  ))
                else
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i == nowAt) AppPad(_nowMarker()),
                    AppPad(_row(shown[i],
                        first: i == 0, last: i == shown.length - 1)),
                  ],
                // اليوم كله عدّى — الخط بينزل آخر القايمة عشان يفضل صادق.
                if (nowAt < 0 && _filter == DayFilter.all && shown.isNotEmpty)
                  AppPad(_nowMarker()),
              ],
            ),
    );
  }

  /// الخط اللى بيقول انت فين من يومك.
  Widget _nowMarker() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: scheme.primary, borderRadius: BorderRadius.circular(99)),
          child: Text(tr('دلوقتى ${arTime(_now)}', 'Now ${arTime(_now)}'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1.4, color: scheme.primary)),
      ]),
    );
  }

  /// سطر على الخط: عمود الوقت · النقطة والخيط · كارت البند.
  Widget _row(TimelineEvent e, {bool first = false, bool last = false}) {
    final scheme = Theme.of(context).colorScheme;
    final missed = _isMissed(e);
    final dot = e.done
        ? scheme.primary
        : missed
            ? scheme.error
            : scheme.outlineVariant;

    // 🔴 الخيط الرأسى بيستعمل `Expanded` عشان يطول لطول الكارت، والصف
    // ده جوّه `ListView` يعنى ارتفاعه **مفتوح** — و`Expanded` جوّه
    // ارتفاع مفتوح بيرمى. `IntrinsicHeight` بتقيس أطول عنصر الأول
    // فيبقى للصف ارتفاع محدّد. (نفس المصيدة اللى حصلت فى مربعات
    // المحافظ وزرارى السجل.)
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        width: 56,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(e.timeLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: missed ? scheme.error : scheme.onSurfaceVariant)),
        ),
      ),
      // الخيط الرأسى اللى بيربط اليوم ببعضه — هو اللى بيخلّيه «خط».
      SizedBox(
        width: 20,
        child: Column(children: [
          Container(
              width: 2,
              height: 14,
              color: first ? Colors.transparent : scheme.outlineVariant),
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: e.done || missed ? dot : scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: dot, width: 2),
            ),
          ),
          Expanded(
            child: Container(
                width: 2,
                color: last ? Colors.transparent : scheme.outlineVariant),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => widget.onOpen(e),
              child: Container(
                padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _kindColor(e.kind, scheme)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11)),
                    child: Icon(_kindIcon(e.kind),
                        size: 16, color: _kindColor(e.kind, scheme)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      e.done ? scheme.outline : scheme.onSurface,
                                  decoration: e.done
                                      ? TextDecoration.lineThrough
                                      : null)),
                          const SizedBox(height: 2),
                          Text(
                              e.sub.isEmpty
                                  ? _kindLabel(e.kind)
                                  : '${_kindLabel(e.kind)} • ${e.sub}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant)),
                        ]),
                  ),
                  const SizedBox(width: 6),
                  // العلامة بتتقلب فى الاتجاهين — تقدر ترجّع تعليم غلط.
                  IconButton(
                    tooltip: e.done
                        ? tr('رجّع العلامة', 'Undo')
                        : tr('علّم إنه خلص', 'Mark done'),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy ? null : () => _toggle(e),
                    icon: Icon(
                      e.done
                          ? Icons.check_circle
                          : missed
                              ? Icons.error_outline
                              : Icons.circle_outlined,
                      size: 22,
                      color: e.done
                          ? scheme.primary
                          : missed
                              ? scheme.error
                              : scheme.outline,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]),
    );
  }
}
