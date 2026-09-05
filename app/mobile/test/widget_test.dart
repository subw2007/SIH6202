import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('switches between the Citizen and Solver views', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Citizen Mode'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch Mode (Citizen / Official)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Official Mode'));
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Solver Mode'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('5 problems'), findsOneWidget);
    expect(find.text('• 2 high priority'), findsOneWidget);
    expect(
      find.text('Deep pothole causing accidents near school'),
      findsOneWidget,
    );
  });
}
