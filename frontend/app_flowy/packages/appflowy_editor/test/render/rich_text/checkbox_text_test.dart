import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/render/rich_text/default_selectable.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('checkbox_text_handler.dart', () {
    testWidgets('Click checkbox icon', (tester) async {
      // Before
      //
      // [BIUS]Welcome to Appflowy 😁[BIUS]
      //
      // After
      //
      // [checkbox]Welcome to Appflowy 😁
      //
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(
          '',
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.checkbox,
            BuiltInAttributeKey.checkbox: false,
          },
          delta: Delta([
            TextInsert(text, {
              BuiltInAttributeKey.bold: true,
              BuiltInAttributeKey.italic: true,
              BuiltInAttributeKey.underline: true,
              BuiltInAttributeKey.strikethrough: true,
            }),
          ]),
        );
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );

      final selection =
          Selection.single(path: [0], startOffset: 0, endOffset: text.length);
      var node = editor.nodeAtPath([0]) as TextNode;
      var state = node.key?.currentState as DefaultSelectable;
      var checkboxWidget = find.byKey(state.iconKey!);
      await tester.tap(checkboxWidget);
      await tester.pumpAndSettle();

      expect(node.attributes.check, true);

      expect(node.allSatisfyBoldInSelection(selection), true);
      expect(node.allSatisfyItalicInSelection(selection), true);
      expect(node.allSatisfyUnderlineInSelection(selection), true);
      expect(node.allSatisfyStrikethroughInSelection(selection), true);

      node = editor.nodeAtPath([0]) as TextNode;
      state = node.key?.currentState as DefaultSelectable;
      await tester.ensureVisible(find.byKey(state.iconKey!));
      await tester.tap(find.byKey(state.iconKey!));
      await tester.pump();

      expect(node.attributes.check, false);
      expect(node.allSatisfyBoldInSelection(selection), true);
      expect(node.allSatisfyItalicInSelection(selection), true);
      expect(node.allSatisfyUnderlineInSelection(selection), true);
      expect(node.allSatisfyStrikethroughInSelection(selection), true);
    });
  });
}
