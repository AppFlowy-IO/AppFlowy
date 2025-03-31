import 'package:appflowy/ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extended_text_field/extended_text_field.dart';

extension AppFlowyAITest on WidgetTester {
  Future<void> enterTextInPromptTextField(String text) async {
    // Wait for the text field to be visible
    await pumpAndSettle();

    // Find the ExtendedTextField widget
    final textField = find.descendant(
      of: find.byType(PromptInputTextField),
      matching: find.byType(ExtendedTextField),
    );
    expect(textField, findsOneWidget, reason: 'ExtendedTextField not found');

    final widget = element(textField).widget as ExtendedTextField;
    expect(widget.enabled, isTrue, reason: 'TextField is not enabled');

    testTextInput.enterText(text);
    await pumpAndSettle(const Duration(milliseconds: 300));
  }
}
