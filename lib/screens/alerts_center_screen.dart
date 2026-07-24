import 'package:flutter/material.dart';

import '../core/attention.dart';
import '../core/l10n.dart';
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

  /// البنود اللى المستخدم قال عليها «بعدين» — بتتخبّى لباقى الجلسة بس
  /// (مؤقت عن قصد: التأجيل معناه «مش وقته دلوقتى»، مش إنه اتعمل).
  /// المفتاح = النوع + الـid عشان يفضل ثابت عبر إعادة التحميل.
  final Set<String> _snoozed = {};

  String _keyOf(AttentionItem it) => '${it.kind.name}_${it.id}_${it.slot ?? ''}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await collectAttention();
    if (!mounted) return;
    setState(() {
      _items = items.where((it) => !_snoozed.contains(_keyOf(it))).toList();
      _loading = false;
    });
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
      };

  void _snooze(AttentionItem it) {
    setState(() {
      _snoozed.add(_keyOf(it));
      _items = _items.where((x) => _keyOf(x) != _keyOf(it)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('التنبيهات', 'Alerts')),
          actions: [
            if (_snoozed.isNotEmpty)
              IconButton(
                tooltip: tr('رجّع المؤجّل', 'Un-snooze'),
                icon: const Icon(Icons.unarchive_outlined),
                onPressed: () {
                  _snoozed.clear();
                  _load();
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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [for (final it in _items) _tile(it)],
                  ),
                ),
    );
  }

  Widget _tile(AttentionItem it) {
    final look = _look(it.kind);
    final screen = _screenFor(it.kind);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: look.color.withValues(alpha: 0.15),
          child: Icon(look.icon, color: look.color, size: 20),
        ),
        title: Text(it.text),
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
              tooltip: tr('بعدين', 'Later'),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.schedule, size: 18),
              onPressed: () => _snooze(it),
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
