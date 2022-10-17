import 'dart:collection';

import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/text_field.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:textfield_tags/textfield_tags.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('text_field.dart', () {
    String submit = '';
    String remainder = '';
    List<String> select = [];

    final textField = SelectOptionTextField(
      options: const [],
      selectedOptionMap: LinkedHashMap<String, SelectOptionPB>(),
      distanceToText: 0.0,
      tagController: TextfieldTagsController(),
      onSubmitted: (text) => submit = text,
      onPaste: (options, remaining) {
        remainder = remaining;
        select = options;
      },
      newText: (_) {},
      textSeparators: const [','],
      textController: TextEditingController(),
    );

    testWidgets('SelectOptionTextField callback outputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Provider<AppTheme>.value(
              value: AppTheme.fromType(ThemeType.light),
              child: textField,
            ),
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

      await tester.enterText(find.byType(TextField), ' another one ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submit, 'another one');

      // test inputs containing commas
      await tester.enterText(find.byType(TextField), ' abcd,');
      expect(remainder, '');
      expect(select, ['abcd']);

      await tester.enterText(find.byType(TextField), ',acd, aaaa ');
      expect(remainder, 'aaaa ');
      expect(select, ['acd']);

      await tester.enterText(find.byType(TextField), 'a a, bbbb , ');
      expect(remainder, '');
      expect(select, ['a a', 'bbbb']);

      // test paste followed by submit
      await tester.enterText(find.byType(TextField), 'aaa, bbb, c');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(select, ['aaa', 'bbb']);
      expect(submit, 'c');
    });
  });
}
