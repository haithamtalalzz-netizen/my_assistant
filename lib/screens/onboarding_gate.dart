import 'package:flutter/material.dart';

import '../data/settings_repo.dart';
import 'onboarding_screen.dart';
import 'tour_screen.dart';

/// بيقرر: يعرض التهيئة (أول مرة) → الجولة التعريفية (مرة واحدة) → التطبيق.
class OnboardingGate extends StatefulWidget {
  final Widget child;

  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _onboarded;
  bool _tourSeen = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final settings = SettingsRepo();
    // المستخدم الحالي (عنده اسم متسجل) بيتعامل كإنه اتهيّأ خلاص — عشان الترقية
    // متعرضش التهيئة لناس بتستخدم التطبيق من قبل.
    final done = await settings.get('onboarded') == '1' ||
        (await settings.userName()).isNotEmpty;
    final tour = await settings.get('tour_seen') == '1';
    if (mounted) {
      setState(() {
        _onboarded = done;
        _tourSeen = tour;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!_onboarded!) {
      return OnboardingScreen(onDone: () {
        setState(() => _onboarded = true);
      });
    }
    // الجولة التعريفية بعد التهيئة — مرة واحدة بس (وتتعاد من الإعدادات).
    if (!_tourSeen) {
      return TourScreen(onDone: () => setState(() => _tourSeen = true));
    }
    return widget.child;
  }
}
