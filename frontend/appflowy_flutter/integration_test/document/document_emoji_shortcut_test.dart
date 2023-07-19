import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('emoji shortcut in document', () {
    testWidgets('insert emoji', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      await insertingEmoji(tester);
      await insertingEmojiWithArrowKeys(tester);
    });
  });
}

// search the emoji list with keyword 'grinning' and insert emoji
Future<void> insertingEmoji(
  WidgetTester tester,
) async {
  // create a new document
  final id = uuid();
  final name = 'document_$id';
  await tester.createNewPageWithName(
    ViewLayoutPB.Document,
    name,
  );

  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);

  // open ':' menu
  await tester.ime.insertCharacter(":");

  // type 'grinning'
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyG);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyR);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyI);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyI);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyN);
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyG);
  await tester.wait(500);

  // insert emoji
  await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
  final editorState = tester.editor.getCurrentEditorState();
  final text = editorState.document.last!.delta!.toPlainText();
  expect(text, "😃");
}

// search the emoji list with keyword 's'
// press the key combination [right, down, left, up]
// insert the emoji
Future<void> insertingEmojiWithArrowKeys(
  WidgetTester tester,
) async {
  // create a new document
  final id = uuid();
  final name = 'document_$id';
  await tester.createNewPageWithName(
    ViewLayoutPB.Document,
    name,
  );

  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);

  // open ':' menu
  await tester.ime.insertCharacter(":");

  // type 's'
  await tester.simulateKeyEvent(LogicalKeyboardKey.keyS);
  await tester.wait(500);

  // perform arrow key movements
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowLeft);
  await tester.simulateKeyEvent(LogicalKeyboardKey.arrowUp);

  // insert emoji
  await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
  final editorState = tester.editor.getCurrentEditorState();
  final text = editorState.document.last!.delta!.toPlainText();
  expect(text, "😃");
}
