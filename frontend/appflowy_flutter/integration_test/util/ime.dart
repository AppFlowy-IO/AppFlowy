import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension IME on WidgetTester {
  IMESimulator get ime => IMESimulator(this);
}

class IMESimulator {
  IMESimulator(this.tester) {
    client = findDeltaTextInputClient();
  }

  final WidgetTester tester;
  late final DeltaTextInputClient client;

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
    final deltas = [
      TextEditingDeltaInsertion(
        textInserted: character,
        oldText: value.text.replaceRange(
          value.selection.start,
          value.selection.end,
          '',
        ),
        insertionOffset: value.selection.baseOffset,
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + 1,
        ),
        composing: TextRange.empty,
      ),
    ];
    client.updateEditingValueWithDeltas(deltas);
    await tester.pumpAndSettle();
  }

  DeltaTextInputClient findDeltaTextInputClient() {
    final finder = find.byType(KeyboardServiceWidget);
    final KeyboardServiceWidgetState state = tester.state(finder);
    return state.textInputService as DeltaTextInputClient;
  }
}
