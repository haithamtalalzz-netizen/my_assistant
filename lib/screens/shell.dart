import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../core/water_guard.dart';
import '../core/widget_bridge.dart';
import '../data/health_repo.dart';
import '../data/inbox_repo.dart';
import 'app_drawer.dart';
import 'brain/insights_screen.dart';
import 'docs/doc_form.dart';
import 'docs/docs_screen.dart';
import 'habits/habits_screen.dart';
import 'money/money_screen.dart';
import 'food/meal_sheet.dart';
import 'money/quick_expense_sheet.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';
import 'today_screen.dart';
import 'voice/voice_sheet.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  StreamSubscription<List<SharedMediaFile>>? _shareSub;
  StreamSubscription<Uri?>? _widgetSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQuickActions();
      _initSharing();
      _initWidgetLaunch();
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _widgetSub?.cancel();
    super.dispose();
  }

  /// زرارات الويدجت اللى بتفتح التطبيق (وجبة/مهام) — بتوصل كـURI:
  /// myassistant://open/meal أو myassistant://open/tasks.
  void _initWidgetLaunch() {
    if (kIsWeb) return;
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    _widgetSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null || !mounted || uri.host != 'open') return;
    final target = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    switch (target) {
      case 'meal':
        await showMealSheet(context);
      case 'tasks':
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TasksScreen()));
    }
    if (mounted) setState(() {}); // تحديث بيانات الشاشة بعد الرجوع
  }

  /// استقبال المشاركة من التطبيقات التانية: صورة → مستند، نص → صندوق الوارد.
  /// إضافة موبايل فقط — مالهاش تنفيذ على الويب (تعمل MissingPluginException).
  void _initSharing() {
    if (kIsWeb) return;
    final intent = ReceiveSharingIntent.instance;
    intent.getInitialMedia().then((media) async {
      await _handleShared(media);
      await intent.reset();
    });
    _shareSub = intent.getMediaStream().listen(_handleShared);
  }

  Future<void> _handleShared(List<SharedMediaFile> media) async {
    if (media.isEmpty || !mounted) return;
    final item = media.first;
    switch (item.type) {
      case SharedMediaType.image:
      case SharedMediaType.file:
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DocForm(sharedImagePath: item.path)));
        if (mounted) setState(() {});
      case SharedMediaType.text:
      case SharedMediaType.url:
        await InboxRepo().add(item.path);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('اتحفظت في صندوق الوارد ✓', 'Saved to inbox ✓'))));
        }
      case SharedMediaType.video:
        break;
    }
  }

  /// اختصارات الضغطة المطولة على أيقونة التطبيق — موبايل فقط.
  void _initQuickActions() {
    if (kIsWeb) return;
    const actions = QuickActions();
    actions.initialize((type) async {
      if (!mounted) return;
      switch (type) {
        case 'expense':
          await showQuickExpenseSheet(context);
        case 'voice':
          await showVoiceSheet(context);
        case 'water':
          final next =
              await HealthRepo().addWater(dayKey(DateTime.now()), 1);
          unawaited(WidgetBridge.push());
          unawaited(WaterGuard.ensureScheduled());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr('مياه النهارده: ${arNum(next)} كوباية',
                    "Today's water: ${arNum(next)} cups"))));
          }
      }
      if (mounted) setState(() {}); // إعادة بناء = تحديث بيانات الشاشة
    });
    actions.setShortcutItems([
      ShortcutItem(
          type: 'expense',
          localizedTitle: tr('سجل مصروف', 'Log expense')),
      ShortcutItem(
          type: 'voice', localizedTitle: tr('سجل بصوتك', 'Voice log')),
      ShortcutItem(
          type: 'water', localizedTitle: tr('+ كوباية مياه', '+ cup of water')),
    ]);
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    // الشاشة بتتبني من جديد مع كل تنقل عشان البيانات تفضل طازة.
    // كل شاشة رئيسية بتاخد نفس الدرج الجانبي، والهمبرجر بيفتحه.
    final drawer = AppDrawer(current: _index, onSelect: _go);
    return switch (_index) {
      1 => ScheduleScreen(drawer: drawer),
      2 => MoneyScreen(drawer: drawer),
      3 => HabitsScreen(drawer: drawer),
      4 => DocsScreen(drawer: drawer),
      5 => InsightsScreen(drawer: drawer),
      _ => TodayScreen(drawer: drawer, onGoToTab: _go),
    };
  }
}
