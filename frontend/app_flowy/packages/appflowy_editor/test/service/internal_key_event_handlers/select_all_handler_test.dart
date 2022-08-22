import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('select_all_handler_test.dart', () {
    testWidgets('Presses Command + A in small document', (tester) async {
      await _testSelectAllHandler(tester, 10);
    });

    testWidgets('Presses Command + A in small document', (tester) async {
      await _testSelectAllHandler(tester, 1000);
    });
  });
}

Future<void> _testSelectAllHandler(WidgetTester tester, int lines) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor;
  for (var i = 0; i < lines; i++) {
    editor.insertTextNode(text);
  }
  await editor.startTesting();
  await editor.pressLogicKey(LogicalKeyboardKey.keyA, isMetaPressed: true);

  expect(
    editor.documentSelection,
    Selection(
      start: Position(path: [0], offset: 0),
      end: Position(path: [lines - 1], offset: text.length),
    ),
  );
}
