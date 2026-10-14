import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import 'screens.dart';

class StudyPetApp extends ConsumerWidget {
  const StudyPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'StudyPet',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
              path: '/home', builder: (_, __) => const ShellScreen(index: 0)),
          GoRoute(
              path: '/progress',
              builder: (_, __) => const ShellScreen(index: 1)),
          GoRoute(
              path: '/achievements',
              builder: (_, __) => const ShellScreen(index: 2)),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const ShellScreen(index: 3)),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
          GoRoute(
              path: '/session', builder: (_, __) => const StartSessionScreen()),
          GoRoute(
            path: '/active',
            builder: (_, state) {
              final values = state.extra as List<Object?>?;
              return ActiveSessionScreen(
                subject: values?[0] as String? ?? 'Deep work',
                task: values?[1] as String? ?? 'Focus session',
                duration: values?[2] as int? ?? 25,
              );
            },
          ),
        ],
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    const seed = Color(0xFF6656D9);
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF8F7FC)
          : const Color(0xFF11101A),
      fontFamily: 'sans',
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1D1B28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1D1B28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
