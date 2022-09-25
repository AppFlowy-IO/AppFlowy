import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('tab_handler.dart', () {
    testWidgets('press tab in plain text', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();
      final document = editor.document;

      var selection = Selection.single(path: [0], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      // nothing happens
      expect(editor.documentSelection, selection);
      expect(editor.document.toJson(), document.toJson());

      selection = Selection.single(path: [1], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      // nothing happens
      expect(editor.documentSelection, selection);
      expect(editor.document.toJson(), document.toJson());
    });

    testWidgets('press tab in bulleted list', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(
          text,
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList
          },
        )
        ..insertTextNode(
          text,
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList
          },
        )
        ..insertTextNode(
          text,
          attributes: {
            BuiltInAttributeKey.subtype: BuiltInAttributeKey.bulletedList
          },
        );
      await editor.startTesting();
      var document = editor.document;

      var selection = Selection.single(path: [0], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      // nothing happens
      expect(editor.documentSelection, selection);
      expect(editor.document.toJson(), document.toJson());

      // Before
      // * Welcome to Appflowy 😁
      // * Welcome to Appflowy 😁
      // * Welcome to Appflowy 😁
      // After
      // * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁

      selection = Selection.single(path: [1], startOffset: 0);
      await editor.updateSelection(selection);

      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      expect(
        editor.documentSelection,
        Selection.single(path: [0, 0], startOffset: 0),
      );
      expect(editor.nodeAtPath([0])!.subtype, BuiltInAttributeKey.bulletedList);
      expect(editor.nodeAtPath([1])!.subtype, BuiltInAttributeKey.bulletedList);
      expect(editor.nodeAtPath([2]), null);
      expect(
          editor.nodeAtPath([0, 0])!.subtype, BuiltInAttributeKey.bulletedList);

      selection = Selection.single(path: [1], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      expect(
        editor.documentSelection,
        Selection.single(path: [0, 1], startOffset: 0),
      );
      expect(editor.nodeAtPath([0])!.subtype, BuiltInAttributeKey.bulletedList);
      expect(editor.nodeAtPath([1]), null);
      expect(editor.nodeAtPath([2]), null);
      expect(
          editor.nodeAtPath([0, 0])!.subtype, BuiltInAttributeKey.bulletedList);
      expect(
          editor.nodeAtPath([0, 1])!.subtype, BuiltInAttributeKey.bulletedList);

      // Before
      // * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      // After
      // * Welcome to Appflowy 😁
      //  * Welcome to Appflowy 😁
      //    * Welcome to Appflowy 😁
      document = editor.document;
      selection = Selection.single(path: [0, 0], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      expect(
        editor.documentSelection,
        Selection.single(path: [0, 0], startOffset: 0),
      );
      expect(editor.document.toJson(), document.toJson());

      selection = Selection.single(path: [0, 1], startOffset: 0);
      await editor.updateSelection(selection);
      await editor.pressLogicKey(LogicalKeyboardKey.tab);

      expect(
        editor.documentSelection,
        Selection.single(path: [0, 0, 0], startOffset: 0),
      );
      expect(
        editor.nodeAtPath([0])!.subtype,
        BuiltInAttributeKey.bulletedList,
      );
      expect(
        editor.nodeAtPath([0, 0])!.subtype,
        BuiltInAttributeKey.bulletedList,
      );
      expect(editor.nodeAtPath([0, 1]), null);
      expect(
        editor.nodeAtPath([0, 0, 0])!.subtype,
        BuiltInAttributeKey.bulletedList,
      );
    });
  });
}
