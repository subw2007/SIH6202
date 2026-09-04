import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/solver_provider.dart';
import 'providers/user_mode_provider.dart';
import 'views/citizen_view.dart';
import 'views/solver_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModeProvider()),
        ChangeNotifierProvider(create: (_) => SolverProvider()),
      ],
      child: const CivicPulseApp(),
    );
  }
}

class CivicPulseApp extends StatelessWidget {
  const CivicPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A62AD),
          surface: const Color(0xFFF4F6FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      ),
      home: const _RootSwitcher(),
    );
  }
}

class _RootSwitcher extends StatelessWidget {
  const _RootSwitcher();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UserModeProvider>();
    if (mode.isCitizenMode) return const CitizenView();
    return SolverView(
      modeProvider: mode,
      solverProvider: context.watch<SolverProvider>(),
    );
  }
}
