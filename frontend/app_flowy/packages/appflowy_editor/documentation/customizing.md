# Customizing Editor Features

## Customizing Shortcut Events

We will use a simple example to illustrate how to quickly add a shortcut event.

In this example, text that starts and ends with an underscore ( \_ ) character will be rendered in italics for emphasis.  So typing `_xxx_` will automatically be converted into _xxx_.

Let's start with a blank document:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.topCenter,
      child: AppFlowyEditor(
        editorState: EditorState.empty(),
        keyEventHandlers: const [],
      ),
    ),
  );
}
```

At this point, nothing magic will happen after typing `_xxx_`.

![Before](./images/customizing_a_shortcut_event_before.gif)

Next, we will create a function to handle an underscore input.

```dart
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // Since we only need to handle the input of an 'underscore' character,
  // all inputs except `underscore` will be ignored immediately.
  if (event.logicalKey != LogicalKeyboardKey.underscore) {
    return KeyEventResult.ignored;
  }
};
```

Then, we need to determine if the currently selected node is a `TextNode` and the selection is collapsed.

```dart
// ...
FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // ...
  
  // Obtain the selection and selected nodes of the current document through the 'selectionService'
  // to determine whether the selection is collapsed and whether the selected node is a text node.
  final selectionService = editorState.service.selectionService;
  final selection = selectionService.currentSelection.value;
  final textNodes = selectionService.currentSelectedNodes.whereType<TextNode>();
  if (selection == null || !selection.isSingle || textNodes.length != 1) {
    return KeyEventResult.ignored;
  }
```

Now, we start dealing with handling the underscore. 

Look for the position of the previous underscore and 
1. if one is _not_ found, return without doing anything. 
2. if one is found, the text enclosed within the two underscores will be formatted to display in italics.

```dart
// ...
FlowyKeyEventHandler underscoreToItalicHandler = (editorState, event) {
  // ...

  final textNode = textNodes.first;
  final text = textNode.toRawString();
  // Determine if an 'underscore' already exists in the text node
  final previousUnderscore = text.indexOf('_');
  if (previousUnderscore == -1) {
    return KeyEventResult.ignored;
  }

  // Delete the previous 'underscore',
  // update the style of the text surrounded by the two underscores to 'italic',
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

Now our 'underscore handler' function is done and the only task left is to inject it into the AppFlowyEditor.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.topCenter,
      child: AppFlowyEditor(
        editorState: EditorState.empty(),
        keyEventHandlers: [
            underscoreToItalicHandler,
        ],
      ),
    ),
  );
}
```

![After](./images/customizing_a_shortcut_event_after.gif)

_TODO: provide the link to the example_

[Complete code example]()

## Customizing a Component
We will use a simple example to show how to quickly add a custom component.

In this example we will render an image from the network.

Let's start with a blank document:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.topCenter,
      child: AppFlowyEditor(
        editorState: EditorState.empty(),
        keyEventHandlers: const [],
      ),
    ),
  );
}
```

Next, we will choose a unique string for your custom node's type. 

We'll use `network_image` in this case. And we add `network_image_src` to the `attributes` to describe the link of the image.

```JSON
{
  "type": "network_image",
  "attributes": {
    "network_image_src": "https://docs.flutter.dev/assets/images/dash/dash-fainting.gif"
  }
}
```

Then, we create a class that inherits [NodeWidgetBuilder](../lib/src/service/render_plugin_service.dart). As shown in the autoprompt, we need to implement two functions:
1. one returns a widget 
2. the other verifies the correctness of the [Node](../lib/src/document/node.dart).


```dart
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class NetworkImageNodeWidgetBuilder extends NodeWidgetBuilder {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    throw UnimplementedError();
  }

  @override
  NodeValidator<Node> get nodeValidator => throw UnimplementedError();
}
```

Now, let's implement a simple image widget based on `Image`.

Note that the `State` object that is returned by the `Widget` must implement [Selectable](../lib/src/render/selection/selectable.dart) using the `with` keyword.

```dart
class _NetworkImageNodeWidget extends StatefulWidget {
  const _NetworkImageNodeWidget({
    Key? key,
    required this.node,
  }) : super(key: key);

  final Node node;

  @override
  State<_NetworkImageNodeWidget> createState() =>
      __NetworkImageNodeWidgetState();
}

class __NetworkImageNodeWidgetState extends State<_NetworkImageNodeWidget>
    with Selectable {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.node.attributes['network_image_src'],
      height: 200,
      loadingBuilder: (context, child, loadingProgress) =>
          loadingProgress == null ? child : const CircularProgressIndicator(),
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  List<Rect> getRectsInSelection(Selection selection) =>
      [Offset.zero & _renderBox.size];

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
}
```

Finally, we return `_NetworkImageNodeWidget` in the `build` function of `NetworkImageNodeWidgetBuilder`...

```dart
class NetworkImageNodeWidgetBuilder extends NodeWidgetBuilder {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _NetworkImageNodeWidget(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.type == 'network_image' &&
            node.attributes['network_image_src'] is String;
      };
}
```

... and register `NetworkImageNodeWidgetBuilder` in the `AppFlowyEditor`.
 
```dart
final editorState = EditorState(
  document: StateTree.empty()
    ..insert(
      [0],
      [
        TextNode.empty(),
        Node.fromJson({
          'type': 'network_image',
          'attributes': {
            'network_image_src':
                'https://docs.flutter.dev/assets/images/dash/dash-fainting.gif'
          }
        })
      ],
    ),
);
return AppFlowyEditor(
  editorState: editorState,
  customBuilders: {
    'network_image': NetworkImageNodeWidgetBuilder(),
  },
);
```

![Whew!](./images/customizing_a_component.gif)

_TODO: need a link to this code example_

Check out the [complete code]() file of this example.
