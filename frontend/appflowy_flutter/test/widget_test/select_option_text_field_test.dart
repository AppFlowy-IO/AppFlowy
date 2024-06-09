import 'dart:collection';

import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../bloc_test/grid_test/util.dart';

void main() {
  setUpAll(() {
    AppFlowyGridTest.ensureInitialized();
  });

  group('text_field.dart', () {
    String submit = '';
    String remainder = '';
    List<String> select = [];

    final textController = TextEditingController();

    final textField = SelectOptionTextField(
      options: const [],
      selectedOptionMap: LinkedHashMap<String, SelectOptionPB>(),
      distanceToText: 0.0,
      onSubmitted: () => submit = textController.text,
      onPaste: (options, remaining) {
        remainder = remaining;
        select = options;
      },
      onRemove: (_) {},
      newText: (text) => remainder = text,
      textSeparators: const [','],
      textController: textController,
      focusNode: FocusNode(),
    );

    testWidgets('SelectOptionTextField callback outputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: textField,
          ),
        ),
      );

      // test that the input field exists
      expect(find.byType(TextField), findsOneWidget);

      // simulate normal input
      await tester.enterText(find.byType(TextField), 'abcd');
      expect(remainder, 'abcd');

      await tester.enterText(find.byType(TextField), ' ');
      expect(remainder, '');

      // test submit functionality (aka pressing enter)
      await tester.enterText(find.byType(TextField), 'an option');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submit, 'an option');

      // test inputs containing commas
      await tester.enterText(find.byType(TextField), 'a a, bbbb , c');
      expect(remainder, 'c');
      expect(select, ['a a', 'bbbb']);
    });
  });
}
