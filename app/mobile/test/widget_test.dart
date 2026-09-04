import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/main.dart';
import 'package:mobile/providers/user_mode_provider.dart';

void main() {
  testWidgets('Citizen view shows header, banner, and feed', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserModeProvider(),
        child: const CivicPulseApp(),
      ),
    );

    expect(find.text('Citizen Mode'), findsWidgets);
    expect(find.text('Report New Problem'), findsOneWidget);
    expect(find.text('Recent in your area'), findsOneWidget);
    expect(find.text('Deep pothole causing accidents'), findsOneWidget);
    expect(find.text('Report Problem'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Report flow submits and returns to citizen feed', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserModeProvider(),
        child: const CivicPulseApp(),
      ),
    );

    await tester.tap(find.text('Report Problem'));
    await tester.pumpAndSettle();

    expect(find.text('Report a Problem'), findsOneWidget);
    expect(find.text('Tap to Take Photo or Upload Image'), findsOneWidget);
    expect(find.text('Hold or Tap to Record Description'), findsOneWidget);

    await tester.tap(find.text('Tap to Take Photo or Upload Image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🚀 Submit Report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Report Submitted Successfully!'), findsOneWidget);

    await tester.tap(find.text('Back to feed'));
    await tester.pumpAndSettle();

    expect(find.text('Recent in your area'), findsOneWidget);
  });
}
