import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/attention.dart';
import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/a_kit.dart';
import '../data/settings_repo.dart';
import 'money/wallets_screen.dart';
import '../widgets/common.dart';
import '../widgets/search_action.dart';
import 'baladna/debts_screen.dart';
import 'baladna/gameya_screen.dart';
import 'baladna/home_maintenance_screen.dart';
import 'baladna/relatives_screen.dart';
import 'docs/docs_screen.dart';
import 'home/pharmacy_screen.dart';
import 'home/plants_screen.dart';
import 'money/subscriptions_screen.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';

/// مركز التنبيهات — كل اللى محتاج انتباهك النهارده فى مكان واحد.
///
/// بيقرا من **`collectAttention` وبس**. قبل كده الشاشة كانت بتبنى قايمتها
/// بنفسها من ٦ مصادر بينما عدّاد الجرس بيحسب من `collectAttention` (٩) —
/// فالعدّاد كان بيقول رقم والشاشة توريك أقل منه: المهام والأدوية
/// والتطعيمات كانت **بتتعدّ ومابتظهرش**.
class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  bool _loading = true;
  List<AttentionItem> _items = const [];

  /// البنود المؤجَّلة: المفتاح → وقت الرجوع (ISO). بتتحفظ محليًا فى الإعدادات،
  /// فالتأجيل بيفضل بعد إعادة فتح الشاشة/التطبيق لحد ما وقته يجى.
  static const _kSnooze = 'alerts_snooze';
  Map<String, String> _snooze = {};

  String _keyOf(AttentionItem it) => '${it.kind.name}_${it.id}_${it.slot ?? ''}';

  /// مفتاح تخزين «أول مرة شُفت فيها التنبيه ده».
  static const _kFirstSeen = 'alert_first_seen';

  /// التنبيه مالوش تاريخ فى النموذج — هو محسوب من اللى مستحق دلوقتى.
  /// فعشان نعرف «من امتى وهو معلّق»، بنسجّل أول مرة ظهر فيها.
  Map<String, DateTime> _firstSeen = {};

  /// الفلتر: الكل · محتاج تصرّف · للعلم.
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = SettingsRepo();
    final now = DateTime.now();
    final map = <String, String>{};
    final raw = await s.get(_kSnooze) ?? '';
    if (raw.isNotEmpty) {
      try {
        (jsonDecode(raw) as Map).forEach((k, v) => map[k as String] = '$v');
      } on FormatException {
        // مخزَّن تالف — نتجاهله.
      }
    }
    // شيل المؤجَّل اللى وقته عدّى.
    map.removeWhere((k, v) {
      final t = DateTime.tryParse(v);
      return t == null || !t.isAfter(now);
    });
    await s.set(_kSnooze, jsonEncode(map));
    final items = await collectAttention();
    if (!mounted) return;
    setState(() {
      _snooze = map;
      _items = items.where((it) => !map.containsKey(_keyOf(it))).toList();
      _loading = false;
    });
    await _trackFirstSeen(now);
  }

  /// بيسجّل أول ظهور لأى تنبيه جديد، وبيشيل اللى اختفى.
  ///
  /// التنظيف مهم: من غيره الملف بيكبر بمفاتيح لحاجات خلصت من زمان.
  Future<void> _trackFirstSeen(DateTime now) async {
    final st = SettingsRepo();
    final stored = <String, DateTime>{};
    final raw = await st.get(_kFirstSeen) ?? '';
    if (raw.isNotEmpty) {
      try {
        (jsonDecode(raw) as Map).forEach((k, v) {
          final d = DateTime.tryParse('$v');
          if (d != null) stored[k as String] = d;
        });
      } on FormatException {
        // مخزَّن تالف — نبدأ من جديد.
      }
    }
    final live = {for (final it in _items) _keyOf(it)};
    final next = <String, DateTime>{
      for (final e in stored.entries)
        if (live.contains(e.key)) e.key: e.value
    };
    for (final k in live) {
      next[k] ??= now;
    }
    if (next.length != stored.length ||
        next.keys.any((k) => !stored.containsKey(k))) {
      await st.set(_kFirstSeen,
          jsonEncode({for (final e in next.entries) e.key: e.value.toIso8601String()}));
    }
    if (mounted) setState(() => _firstSeen = next);
  }

  /// عنوان المجموعة اللى البند بيقع فيها.
  String _bucketOf(AttentionItem it) {
    final seen = _firstSeen[_keyOf(it)];
    if (seen == null) return tr('النهارده', 'Today');
    final days = dateOnly(DateTime.now()).difference(dateOnly(seen)).inDays;
    if (days <= 0) return tr('النهارده', 'Today');
    if (days == 1) return tr('امبارح', 'Yesterday');
    if (days <= 7) return tr('الأسبوع ده', 'This week');
    return tr('من زمان', 'Older');
  }

  Widget _filterBar() {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String id, String label) {
      final on = _filter == id;
      return Padding(
        padding: const EdgeInsets.only(left: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: () => setState(() => _filter = id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: on ? scheme.primary : scheme.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: on ? scheme.primary : scheme.outlineVariant),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: on ? scheme.onPrimary : scheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    return Row(children: [
      chip('all', tr('الكل', 'All')),
      chip('act', tr('محتاج تصرّف', 'Needs you')),
      chip('fyi', tr('للعلم', 'FYI')),
    ]);
  }

  /// تنفيذ الإجراء من التنبيه نفسه — من غير ما تفتح الصفحة.
  Future<void> _act(AttentionItem it) async {
    final done = await performAttentionAction(it);
    if (!mounted) return;
    if (!done) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('تمام ✓', 'Done ✓'))));
  }

  /// الصفحة اللى البند بيفتحها لما تدوس عليه.
  Widget? _screenFor(AttentionKind kind) => switch (kind) {
        // الفواتير والتطعيمات جوّه شاشات أكبر (تبويب) — الزرار بيكفى.
        AttentionKind.bill => null,
        AttentionKind.vaccine => null,
        AttentionKind.task => const TasksScreen(),
        AttentionKind.med => const PharmacyScreen(),
        AttentionKind.appointment => const ScheduleScreen(),
        AttentionKind.doc => const DocsScreen(),
        AttentionKind.plant => const PlantsScreen(),
        AttentionKind.maintenance => const HomeMaintenanceScreen(),
        AttentionKind.relative => const RelativesScreen(),
        AttentionKind.debt => const DebtsScreen(),
        AttentionKind.subscription => const SubscriptionsScreen(),
        AttentionKind.gameya => const GameyaScreen(),
        AttentionKind.backup => null, // إجراؤه بيطلّع النسخة، مفيش صفحة
        // التجديد بيحصل فى البنك — الضغط بيودّيك تعدّل التاريخ.
        AttentionKind.certificate => const WalletsScreen(),
      };

  ({IconData icon, Color color}) _look(AttentionKind kind) => switch (kind) {
        AttentionKind.bill =>
          (icon: Icons.receipt_long_outlined, color: Colors.redAccent),
        AttentionKind.task => (icon: Icons.checklist_rtl, color: Colors.orange),
        AttentionKind.med =>
          (icon: Icons.medication_outlined, color: Colors.pink),
        AttentionKind.appointment =>
          (icon: Icons.event_outlined, color: Colors.blue),
        AttentionKind.doc => (icon: Icons.folder_outlined, color: Colors.teal),
        AttentionKind.vaccine =>
          (icon: Icons.vaccines_outlined, color: Colors.indigo),
        AttentionKind.plant => (icon: Icons.yard_outlined, color: Colors.green),
        AttentionKind.maintenance =>
          (icon: Icons.home_repair_service_outlined, color: Colors.orange),
        AttentionKind.relative =>
          (icon: Icons.diversity_1_outlined, color: Colors.purple),
        AttentionKind.debt =>
          (icon: Icons.handshake_outlined, color: Color(0xFFFF6F00)),
        AttentionKind.subscription =>
          (icon: Icons.subscriptions_outlined, color: Colors.indigo),
        AttentionKind.gameya =>
          (icon: Icons.groups_outlined, color: Colors.teal),
        AttentionKind.backup =>
          (icon: Icons.backup_outlined, color: Colors.blueGrey),
        AttentionKind.certificate =>
          (icon: Icons.account_balance_outlined, color: Color(0xFF14B8A6)),
      };

  /// يؤجّل بندًا لحد وقت معيّن ويحفظه محليًا.
  Future<void> _snoozeUntil(AttentionItem it, DateTime until) async {
    _snooze[_keyOf(it)] = until.toIso8601String();
    await SettingsRepo().set(_kSnooze, jsonEncode(_snooze));
    if (!mounted) return;
    setState(
        () => _items = _items.where((x) => _keyOf(x) != _keyOf(it)).toList());
  }

  /// خيارات التأجيل: ساعة / ٣ ساعات / بكرة الصبح.
  Future<void> _snoozeMenu(AttentionItem it) async {
    final now = DateTime.now();
    final choice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(tr('بعد ساعة', 'In an hour')),
              onTap: () =>
                  Navigator.pop(context, now.add(const Duration(hours: 1))),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(tr('بعد ٣ ساعات', 'In 3 hours')),
              onTap: () =>
                  Navigator.pop(context, now.add(const Duration(hours: 3))),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(tr('بكرة الصبح', 'Tomorrow morning')),
              onTap: () => Navigator.pop(
                  context, DateTime(now.year, now.month, now.day + 1, 9)),
            ),
          ],
        ),
      ),
    );
    if (choice != null) await _snoozeUntil(it, choice);
  }

  /// «خلّص المتاح» — بينفّذ إجراء كل بند له زرار (تمّت/اتاخد/…) دفعة
  /// واحدة. البنود اللى مالهاش إجراء (زى الاشتراك) بتفضل زى ما هى.
  Future<void> _clearActionable() async {
    // النسخة مستثناة: إجراؤها بيفتح شيت مشاركة، مايصحّش وسط لوب.
    final actionable = _items
        .where((i) => i.actionLabel != null && i.kind != AttentionKind.backup)
        .toList();
    if (actionable.isEmpty) return;
    final ok = await confirmAction(
      context,
      title: tr('خلّص ${arNum(actionable.length)} بند؟',
          'Clear ${arNum(actionable.length)} items?'),
      message: tr('هنفّذ كل اللى ليه زرار (تمّت / اتاخد / اتدفعت …) مرة واحدة.',
          "I'll run every item's action (Done / Taken / Paid …) at once."),
      confirmLabel: tr('خلّص الكل', 'Clear all'),
    );
    if (!ok) return;
    for (final it in actionable) {
      await performAttentionAction(it);
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('اتخلّصوا ✓', 'All cleared ✓'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التنبيهات', 'Alerts')),
          actions: [
            if (_items.any((i) => i.actionLabel != null))
              IconButton(
                tooltip: tr('خلّص المتاح', 'Clear actionable'),
                icon: const Icon(Icons.done_all),
                onPressed: _clearActionable,
              ),
            if (_snooze.isNotEmpty)
              IconButton(
                tooltip: tr('رجّع المؤجّل', 'Un-snooze'),
                icon: const Icon(Icons.unarchive_outlined),
                onPressed: () async {
                  _snooze.clear();
                  await SettingsRepo().set(_kSnooze, jsonEncode(_snooze));
                  await _load();
                },
              ),
            searchAction(context),
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyHint(
                  icon: Icons.notifications_none,
                  text: tr('مفيش تنبيهات النهارده — كله تمام 🎉',
                      'No alerts today — all clear 🎉'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: _grouped(),
                  ),
                ),
    );
  }

  /// **مقسومة بالوقت**: النهارده · امبارح · الأسبوع ده · من زمان.
  ///
  /// التنبيه مالوش تاريخ فى النموذج (بيتحسب من اللى مستحق دلوقتى)،
  /// فبنسجّل أول ظهور له ونجمّع عليه — كده تعرف اللى معلّق من أسبوع
  /// من اللى طلع دلوقتى.
  List<Widget> _grouped() {
    final shown = [
      for (final i in _items)
        if (_filter == 'all' ||
            (_filter == 'act' && i.actionLabel != null) ||
            (_filter == 'fyi' && i.actionLabel == null))
          i
    ];
    const order = ['النهارده', 'امبارح', 'الأسبوع ده', 'من زمان'];
    final buckets = <String, List<AttentionItem>>{};
    for (final it in shown) {
      buckets.putIfAbsent(_bucketOf(it), () => []).add(it);
    }
    final keys = buckets.keys.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a);
        final ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    return [
      AppPad(_filterBar()),
      for (final k in keys) ...[
        AppGroupHead(k, trail: arNum(buckets[k]!.length)),
        for (var i = 0; i < buckets[k]!.length; i++)
          _tile(buckets[k]![i], last: i == buckets[k]!.length - 1),
      ],
    ];
  }

  Widget _tile(AttentionItem it, {bool last = false}) {
    final look = _look(it.kind);
    final screen = _screenFor(it.kind);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7)))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: look.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(look.icon, color: look.color, size: 19),
        ),
        title: Text(it.text, style: const TextStyle(fontSize: 13.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (it.actionLabel != null)
              FilledButton.tonal(
                onPressed: () => _act(it),
                style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                child: Text(it.actionLabel!,
                    style: const TextStyle(fontSize: 12.5)),
              ),
            // «بعدين» — يخبّى البند لباقى الجلسة عشان القايمة تفضل معبّرة.
            IconButton(
              tooltip: tr('أجّل لوقت', 'Snooze'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.schedule, size: 18),
              onPressed: () => _snoozeMenu(it),
            ),
          ],
        ),
        onTap: screen == null
            ? null
            : () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => screen));
                if (mounted) await _load();
              },
      ),
    );
  }
}
