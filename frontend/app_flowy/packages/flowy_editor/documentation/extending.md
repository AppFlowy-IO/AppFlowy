# How to extends

## Extending a custom shortcut event
we will use a simple example to describe how to quickly extend shortcut event.

For example, typing `_xxx_` will be converted into _xxx_.

To start with, we build the simplest example, just a blank document.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.topCenter,
      child: FlowyEditor(
        editorState: EditorState.empty(),
        keyEventHandlers: const [],
      ),
    ),
  );
}
```

Nothing will happen after typing `_xxx_`.

![Before](./images/custom_a_shortcut_key_before.gif)

Next, we will create a function to handler underscore input.

```dart
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // Since we only need to handler the input of `underscore`.
  // All inputs except `underscore` will be ignored directly.
  if (event.logicalKey != LogicalKeyboardKey.underscore) {
    return KeyEventResult.ignored;
  }
};
```

Then, we need to determine if the currently selected node is `TextNode` and is a single-select case, because for the multi-select case, underscore input should be considered as replacement.

```dart
// ...
FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // ...
  
  // Obtaining the selection and selected nodes of the current document through `selectionService`.
  // And determine whether it is a single selection and whether the selected node is a text node.
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }
```

Now, we start working on underscore logic by looking for the position of the previous underscore and returning if not found. If found, the text wrapped in the two underscores will be converted info italic.

```dart
// ...
FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // ...

  final textNode = textNodes.first;
  final text = textNode.toRawString();
  // Determine if `underscore` already exists in the text node
  final previousUnderscore = text.indexOf('_');
  if (previousUnderscore == -1) {
    return KeyEventResult.ignored;
  }

  // Delete the previous `underscore`,
  // update the style of the text surrounded by two underscores to `italic`,
  // and update the cursor position.
  TransactionBuilder(editorState)
    ..deleteText(textNode, previousUnderscore, 1)
    ..formatText(
      textNode,
      previousUnderscore,
      selection.end.offset - previousUnderscore - 1,
      {'italic': true},
    )
    ..afterSelection = Selection.collapsed(
      Position(path: textNode.path, offset: selection.end.offset - 1),
    )
    ..commit();

  return KeyEventResult.handled;
};
```

So far, the 'underscore handler' function has completed and only needs to be injected info AppFlowyEditor.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.topCenter,
      child: FlowyEditor(
        editorState: EditorState.empty(),
        keyEventHandlers: [
            underscoreToItalicHandler,
        ],
      ),
    ),
  );
}
```

![After](./images/custom_a_shortcut_key_after.gif)

[Complete code example]()

## Extending a custom component
we will use a simple example to describe how to quickly extend custom component.
/// 1. define your custom type in example.json
///   For example I need to define an image plugin, then I define type equals
///   "image", and add "image_src" into "attributes".
///   {
///     "type": "image",
///     "attributes", { "image_src": "https://s1.ax1x.com/2022/07/28/vCgz1x.png" }
///   }
/// 2. create a class extends [NodeWidgetBuilder]
/// 3. override the function `Widget build(NodeWidgetContext<Node> context)`
///     and return a widget to render. The returned widget should be
///     a StatefulWidget and mixin with [Selectable].
///
/// 4. override the getter `nodeValidator`
///     to verify the data structure in [Node].
/// 5. register the plugin with `type` to `flowy_editor` in `main.dart`.
/// 6. Congratulations!
1. define your custom `type`. 