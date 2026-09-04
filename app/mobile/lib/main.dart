import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_mode_provider.dart';
import 'views/citizen_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserModeProvider(),
      child: const CivicPulseApp(),
    ),
  );
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
    final isCitizen = context.watch<UserModeProvider>().isCitizenMode;
    return isCitizen ? const CitizenView() : const _OfficialPlaceholder();
  }
}

/// Temporary Official landing until the municipal dashboard is built.
class _OfficialPlaceholder extends StatelessWidget {
  const _OfficialPlaceholder();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<UserModeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Official Mode'),
        actions: [
          IconButton(
            tooltip: 'Switch to Citizen Mode',
            onPressed: mode.toggleMode,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Official dashboard is not in this sprint.\nUse the header control to return to Citizen Mode.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF4A5568)),
          ),
        ),
      ),
    );
  }
}
