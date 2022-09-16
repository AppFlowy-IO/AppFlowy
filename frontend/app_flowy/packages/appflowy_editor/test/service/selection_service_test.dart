import 'package:appflowy_editor/appflowy_editor.dart';
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
  });
}
