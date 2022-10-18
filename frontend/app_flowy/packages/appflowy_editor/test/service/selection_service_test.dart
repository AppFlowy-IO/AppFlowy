import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/service/context_menu/context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('selection_service.dart', () {
    testWidgets('Single tap test ', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final secondTextNode = editor.nodeAtPath([1]);
      final finder = find.byKey(secondTextNode!.key!);

      final rect = tester.getRect(finder);
      // tap at the beginning
      await tester.tapAt(rect.centerLeft);
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );

      // tap at the ending
      await tester.tapAt(rect.centerRight);
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: text.length),
      );
    });

    testWidgets('Test double tap', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final secondTextNode = editor.nodeAtPath([1]);
      final finder = find.byKey(secondTextNode!.key!);

      final rect = tester.getRect(finder);
      // double tap
      await tester.tapAt(rect.centerLeft + const Offset(10.0, 0.0));
      await tester.tapAt(rect.centerLeft + const Offset(10.0, 0.0));
      await tester.pump();
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0, endOffset: 7),
      );
    });

    testWidgets('Test triple tap', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final secondTextNode = editor.nodeAtPath([1]);
      final finder = find.byKey(secondTextNode!.key!);

      final rect = tester.getRect(finder);
      // triple tap
      await tester.tapAt(rect.centerLeft + const Offset(10.0, 0.0));
      await tester.tapAt(rect.centerLeft + const Offset(10.0, 0.0));
      await tester.tapAt(rect.centerLeft + const Offset(10.0, 0.0));
      await tester.pump();
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0, endOffset: text.length),
      );
    });

    testWidgets('Test secondary tap', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      final secondTextNode = editor.nodeAtPath([1]) as TextNode;
      final finder = find.byKey(secondTextNode.key!);

      final rect = tester.getRect(finder);
      // secondary tap
      await tester.tapAt(
        rect.centerLeft + const Offset(10.0, 0.0),
        buttons: kSecondaryButton,
      );
      await tester.pump();

      const welcome = 'Welcome';
      expect(
        editor.documentSelection,
        Selection.single(
          path: [1],
          startOffset: 0,
          endOffset: welcome.length,
        ), // Welcome
      );

      final contextMenu = find.byType(ContextMenu);
      expect(contextMenu, findsOneWidget);

      // test built in context menu items

      // cut
      await tester.tap(find.text('Cut'));
      await tester.pump();
      expect(
        secondTextNode.toPlainText(),
        text.replaceAll(welcome, ''),
      );

      // TODO: the copy and paste test is not working during test env.
    });
  });
}
