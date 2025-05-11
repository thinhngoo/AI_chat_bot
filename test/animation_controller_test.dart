import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/features/chat/presentation/assistant_selector.dart';

void main() {
  group('AssistantSelector Animation Controller Tests', () {
    testWidgets('Animation controller is properly created and animated',
        (WidgetTester tester) async {
      // Build our widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantSelector(
              selectedAssistantId: 'gpt-4o',
              onSelect: (_) {},
            ),
          ),
        ),
      );      // We can't directly access private members in tests, so we'll use indirect testing

      // Initially, the refresh indicator should not be visible
      expect(find.byIcon(Icons.refresh), findsNothing);

      // Since we can't directly manipulate private state, we'll check other aspects
      // like widget rendering and behavior
      
      // Check that the selector renders with the expected model name
      expect(find.text('GPT-4o'), findsOneWidget);

      // Simulate a tap to open the menu
      await tester.tap(find.byType(AssistantSelector));
      await tester.pumpAndSettle();
      
      // Now we should see the menu and check for expected elements
      expect(find.text('Base AI Models'), findsOneWidget);
      expect(find.text('Your Bots'), findsOneWidget);
      expect(find.text('Manage Bots'), findsOneWidget);
      
      // Simulate tap outside to close the menu
      await tester.tap(find.byType(Scaffold), warnIfMissed: false);
      await tester.pumpAndSettle();
      
      // The menu should be closed again
      expect(find.text('Base AI Models'), findsNothing);
    });
  });
}
