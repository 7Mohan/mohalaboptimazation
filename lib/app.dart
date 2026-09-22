import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/theme_preference.dart';
import 'features/settings/presentation/providers/theme_provider.dart';

/// Root application widget.
///
/// Responsibilities:
/// - Wires [MaterialApp.router] with GoRouter.
/// - Reads [themeModeProvider] and applies the correct [ThemeData].
/// - Does NOT contain any business logic.
class MohaLabApp extends ConsumerWidget {
  const MohaLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themePref =
        ref.watch(themeNotifierProvider).valueOrNull ?? ThemePreference.system;
    final darkTheme =
        themePref == ThemePreference.amoled ? AppTheme.amoled : AppTheme.dark;

    return MaterialApp.router(
      title: 'Moha Lab Optimization',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
