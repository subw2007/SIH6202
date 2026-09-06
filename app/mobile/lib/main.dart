import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/citizen_feed_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/solver_provider.dart';
import 'providers/teams_provider.dart';
import 'providers/user_mode_provider.dart';
import 'views/citizen_view.dart';
import 'views/auth/login_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserModeProvider()),
        ChangeNotifierProvider(
          create: (context) => SolverProvider(
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TeamsProvider(
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CitizenFeedProvider(
            authProvider: context.read<AuthProvider>(),
          ),
        ),
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

class _RootSwitcher extends StatefulWidget {
  const _RootSwitcher();

  @override
  State<_RootSwitcher> createState() => _RootSwitcherState();
}

class _RootSwitcherState extends State<_RootSwitcher> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?['role'] == 'solver') {
      context.read<UserModeProvider>().setCitizenMode(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) return const LoginScreen();
    final mode = context.watch<UserModeProvider>();
    if (mode.isCitizenMode) return const CitizenView();
    return SolverView(
      modeProvider: mode,
      solverProvider: context.watch<SolverProvider>(),
    );
  }
}
