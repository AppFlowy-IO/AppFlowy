# Testing

The directory structure of test files mirrors that of the code files, making it easy for us to map a file with the corresponding test and check if the test is updated.

For an overview of testing best practices in Flutter applications, please refer to Flutter's [introduction to widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction) as well as their [introduction to unit testing](https://docs.flutter.dev/cookbook/testing/unit/introduction).
There you will learn how to do such things as such as simulate a click as well as leverage the `test` and `expect` functions.

## Testing Basic Editor Functions

The example code below shows how to construct a document that will be used in our testing.

```dart
const text = 'Welcome to Appflowy 😁';
// Get the instance of the editor.
final editor = tester.editor;

// Insert an empty text node.
editor.insertEmptyTextNode();

// Insert a text node with the text string we defined earlier.
editor.insertTextNode(text);

// Insert the same text, but with the heading style.
editor.insertTextNode(text, attributes: {
    StyleKey.subtype: StyleKey.heading,
    StyleKey.heading: StyleKey.h1,
});

// Insert our text with the bulleted list style and the bold style.
// If you want to modify the style of the inserted text, you need to use the Delta parameter.
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

The `startTesting` function of the editor must be called before you begin your test.

```dart
await editor.startTesting();
```

Get the number of nodes in the document.

```dart
final length = editor.documentLength;
print(length);
```

Get the node of a defined path. In this case we are getting the first node of the document which is the text "Welcome to Appflowy 😁".

```dart
final firstTextNode = editor.nodeAtPath([0]) as TextNode;
```

Update the [Selection](https://github.com/AppFlowy-IO/AppFlowy/blob/main/frontend/app_flowy/packages/appflowy_editor/lib/src/document/selection.dart) so that our text "Welcome to Appflowy 😁" is selected. We will start our selection from the beginning of the string.

```dart
await editor.updateSelection(
    Selection.single(path: firstTextNode.path, startOffset: 0),
);
```

Get the current selection.

```dart
final selection = editor.documentSelection;
print(selection);
```

Next we will simulate the input of a shortcut key being pressed that will select all the text.

```dart
// Meta + A.
await editor.pressLogicKey(LogicalKeyboardKey.keyA, isMetaPressed: true);
// Meta + shift + S.
await editor.pressLogicKey(
    LogicalKeyboardKey.keyS,
    isMetaPressed: true,
    isShiftPressed: true,
);
```

We will then simulate text input.

```dart
// Insert 'Hello World' at the beginning of the first node.
editor.insertText(firstTextNode, 'Hello World', 0);
```

Once the text has been added, we can get information about the text node.

```dart
// Get the text of the first text node as plain text
final textAfterInserted = firstTextNode.toRawString();
print(textAfterInserted);
// Get the attributes of the text node
final attributes = firstTextNode.attributes;
print(attributes);
```

## A Complete Code Example

In the example code below we are going to test `select_all_handler.dart` by inserting 100 lines of text that read "Welcome to Appflowy 😁" and then simulating the "selectAll" shortcut key being pressed.

Afterwards, we will `expect` that the current selection of the editor is equal to the selection of all the lines that were generated.

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
