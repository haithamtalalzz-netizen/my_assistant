import '../core/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../core/l10n.dart';
import '../data/settings_repo.dart';
import 'emergency_view.dart';

/// إعداد «ارجع للرئيسية بعد غياب طويل».
const String kReturnHomeSetting = 'return_home_on_resume';

/// بوابة القفل: تلف الـ Shell وتطلب البصمة عند الفتح وبعد غياب طويل
/// في الخلفية — لو القفل مفعّل من الإعدادات.
class LockGate extends StatefulWidget {
  final Widget child;

  const LockGate({super.key, required this.child});

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  static const _relockAfter = Duration(minutes: 1);

  final _auth = LocalAuthentication();
  bool _checked = false;
  bool _locked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialCheck() async {
    final enabled = await SettingsRepo().appLockEnabled();
    if (!mounted) return;
    setState(() {
      _checked = true;
      _locked = enabled;
    });
    if (enabled) await _tryUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeRelock();
    }
  }

  /// بعد غياب طويل نرجع للرئيسية (لو المستخدم مفعّلها) — نقفل أى صفحات
  /// مفتوحة فوق الشِل. أطول من قفل البصمة عشان تبديل تطبيق سريع مايضيّعش
  /// مكانك، بس رجوعك «تانى يوم» يبدأ من الرئيسية.
  static const _homeAfter = Duration(minutes: 5);

  Future<void> _maybeRelock() async {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;
    final away = DateTime.now().difference(pausedAt);

    // أولًا: القفل بالبصمة (لو مفعّل + غياب > دقيقة).
    if (!_locked &&
        away >= _relockAfter &&
        await SettingsRepo().appLockEnabled()) {
      if (!mounted) return;
      setState(() => _locked = true);
      await _tryUnlock();
    }

    // ثانيًا: الرجوع للرئيسية (لو مفعّل + غياب > ٥ دقايق) — بنقفل أى
    // صفحات مدفوعة فوق الشِل، فرجوعك «تانى يوم» يبدأ نضيف من الرئيسية.
    if (away >= _homeAfter &&
        (await SettingsRepo().get(kReturnHomeSetting)) == '1') {
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _tryUnlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: tr('افتح My Assistant', 'Unlock My Assistant'),
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok && mounted) {
        setState(() => _locked = false);
        _pausedAt = null;
      }
    } on PlatformException catch (e) {
      logError('فشلت محاولة فتح القفل', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!_locked) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(tr('التطبيق مقفول', 'App locked'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(tr('بياناتك محمية بالبصمة', 'Your data is protected by fingerprint'),
                style: TextStyle(color: scheme.outline)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _tryUnlock,
              icon: const Icon(Icons.fingerprint),
              label: Text(tr('افتح', 'Unlock')),
            ),
            const SizedBox(height: 12),
            // متاح عمدًا من غير بصمة — وقت الطوارئ كل ثانية بتفرق.
            TextButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyView())),
              icon: Icon(Icons.medical_services_outlined,
                  color: scheme.error),
              label: Text(tr('كارت الطوارئ', 'Emergency card'),
                  style: TextStyle(color: scheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}
