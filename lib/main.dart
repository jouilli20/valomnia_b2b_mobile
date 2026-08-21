import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/language_controller.dart';
import 'core/presentation/offline_status_banner.dart';
import 'features/auth/presentation/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale =
        ref.watch(languageControllerProvider).value ?? const Locale('fr');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Valomnia B2B',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A96E2)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
