import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension IME on WidgetTester {
  IMESimulator get ime => IMESimulator(this);
}

class IMESimulator {
  IMESimulator(this.tester) {
    client = findTextInputClient();
  }

  final WidgetTester tester;
  late final TextInputClient client;

  Future<void> insertText(String text) async {
    for (final c in text.characters) {
      await insertCharacter(c);
    }
  }

  Future<void> insertCharacter(String character) async {
    final value = client.currentTextEditingValue;
    if (value == null) {
      assert(false);
      return;
    }
    final text = value.text
        .replaceRange(value.selection.start, value.selection.end, character);
    final textEditingValue = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: value.selection.baseOffset + 1,
      ),
    );
    client.updateEditingValue(textEditingValue);
    await tester.pumpAndSettle();
  }

  TextInputClient findTextInputClient() {
    final finder = find.byType(KeyboardServiceWidget);
    final KeyboardServiceWidgetState state = tester.state(finder);
    return state.textInputService as TextInputClient;
  }
}
