import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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
/// 5. register the plugin with `type` to `AppFlowyEditor` in `main.dart`.
/// 6. Congratulations!

class ImageNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return ImageNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'image';
      });
}

const double placeholderHeight = 132;

class ImageNodeWidget extends StatefulWidget {
  final Node node;
  final EditorState editorState;

  const ImageNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  State<ImageNodeWidget> createState() => _ImageNodeWidgetState();
}

class _ImageNodeWidgetState extends State<ImageNodeWidget> with Selectable {
  bool isHovered = false;
  Node get node => widget.node;
  EditorState get editorState => widget.editorState;
  String get src => widget.node.attributes['image_src'] as String;

  @override
  Position end() {
    return Position(path: node.path, offset: 0);
  }

  @override
  Position start() {
    return Position(path: node.path, offset: 0);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    return [];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    return Selection.collapsed(Position(path: node.path, offset: 0));
  }

  @override
  Offset localToGlobal(Offset offset) {
    throw UnimplementedError();
  }

  @override
  Position getPositionInOffset(Offset start) {
    return Position(path: node.path, offset: 0);
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _loadingBuilder(
      BuildContext context, Widget widget, ImageChunkEvent? evt) {
    if (evt == null) {
      return widget;
    }
    return Container(
      alignment: Alignment.center,
      height: placeholderHeight,
      child: const Text("Loading..."),
    );
  }

  Widget _errorBuilder(
      BuildContext context, Object obj, StackTrace? stackTrace) {
    return Container(
      alignment: Alignment.center,
      height: placeholderHeight,
      child: const Text("Error..."),
    );
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame == null) {
      return Container(
        alignment: Alignment.center,
        height: placeholderHeight,
        child: const Text("Loading..."),
      );
    }

    return child;
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
            onEnter: (event) {
              setState(() {
                isHovered = true;
              });
            },
            onExit: (event) {
              setState(() {
                isHovered = false;
              });
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  border: Border.all(
                    color: isHovered ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: Image.network(
                src,
                width: MediaQuery.of(context).size.width,
                frameBuilder: _frameBuilder,
                loadingBuilder: _loadingBuilder,
                errorBuilder: _errorBuilder,
              ),
            )),
      ],
    );
  }
}
