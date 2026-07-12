import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/lock_gate.dart';
import 'screens/onboarding_gate.dart';
import 'screens/shell.dart';

class MyAssistantApp extends StatelessWidget {
  const MyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (context, mode, _) => ValueListenableBuilder<Locale>(
        valueListenable: AppState.locale,
        builder: (context, locale, _) => ListenableBuilder(
          listenable: Listenable.merge([
            AppState.accentKey,
            AppState.bgKey,
            AppState.bgLightKey,
            AppState.gender,
          ]),
          builder: (context, _) => MaterialApp(
            title: 'My Assistant',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: mode,
          // اللغة بتقلب الاتجاه تلقائيًا (عربي = يمين، إنجليزي = شمال).
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
            home: const OnboardingGate(child: LockGate(child: Shell())),
          ),
        ),
      ),
    );
  }
}
