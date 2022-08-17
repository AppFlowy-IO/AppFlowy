# Testing

> The directory structure of test files is consistent with the code files, making it easy for us to map a file with the corresponding test and check if the test is updated

## Testing Functions

**Construct a document for testing**
```dart
const text = 'Welcome to Appflowy 😁';
// Get the instance of editor.
final editor = tester.editor;
// Insert empty text node.
editor.insertEmptyTextNode();
// Insert text node with string.
editor.insertTextNode(text);
// Insert text node with heading style.
editor.insertTextNode(text, attributes: {
    StyleKey.subtype: StyleKey.heading,
    StyleKey.heading: StyleKey.h1,
});
// Insert text node with bulleted list style and bold style.
editor.insertTextNode(
    '',
    attributes: {
        StyleKey.subtype: StyleKey.bulletedList,
    },
    delta: Delta([
        TextInsert(text, {StyleKey.bold: true}),
    ]),
);
```

**The `startTesting` function must be called before testing**.
```dart
await editor.startTesting();
```

**Get the number of nodes in the document**
```dart
final length = editor.documentLength;
print(length);
```

**Get the node of a defined path**
```dart
final firstTextNode = editor.nodeAtPath([0]) as TextNode;
```

**Update selection**
```dart
await editor.updateSelection(
    Selection.single(path: firstTextNode.path, startOffset: 0),
);
```

**Get the selection**
```dart
final selection = editor.documentSelection;
print(selection);
```

**Simulate shortcut event inputs**
```dart
// Command + A.
await editor.pressLogicKey(LogicalKeyboardKey.keyA, isMetaPressed: true);
// Command + shift + S.
await editor.pressLogicKey(
    LogicalKeyboardKey.keyS, 
    isMetaPressed: true, 
    isShiftPressed: true,
);
```

**Simulate a text input**
```dart
// Insert 'Hello World' at the beginning of the first node.
editor.insertText(firstTextNode, 'Hello World', 0);
```

**Get information about the text node**
```dart
// Get plain text.
final textAfterInserted = firstTextNode.toRawString();
print(textAfterInserted);
// Get attributes.
final attributes = firstTextNode.attributes;
print(attributes);
```

## Example
For example, we are going to test `select_all_handler.dart`


```dart
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('select_all_handler_test.dart', () {
    testWidgets('Presses Command + A in the document', (tester) async {
      const lines = 100;
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
    });
  });
}
```

For more information about testing, such as simulating a click, please refer to [An introduction to widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction) 
