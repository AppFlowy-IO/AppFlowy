import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/flowy_keyboard_service.dart';
import 'package:flutter/material.dart';

FlowyKeyEventHandler deleteSingleImageNode = (editorState, event) {
  final selectNodes = editorState.selectedNodes;
  if (selectNodes.length != 1 || selectNodes.first.type != 'image') {
    return KeyEventResult.ignored;
  }
  TransactionBuilder(editorState)
    ..deleteNode(selectNodes.first)
    ..commit();
  return KeyEventResult.handled;
};

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({
    required super.node,
    required super.editorState,
    required super.key,
  }) : super.create();

  @override
  Widget build(BuildContext buildContext) {
    return _ImageNodeWidget(
      key: key,
      node: node,
      editorState: editorState,
    );
  }
}

class _ImageNodeWidget extends StatefulWidget {
  final Node node;
  final EditorState editorState;

  const _ImageNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  State<_ImageNodeWidget> createState() => __ImageNodeWidgetState();
}

class __ImageNodeWidgetState extends State<_ImageNodeWidget> with Selectable {
  Node get node => widget.node;
  EditorState get editorState => widget.editorState;
  String get src => widget.node.attributes['image_src'] as String;

  @override
  List<Rect> getSelectionRectsInSelection(Offset start, Offset end) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final boxOffset = renderBox.localToGlobal(Offset.zero);
    return [boxOffset & size];
  }

  @override
  Rect getCursorRect(Offset start) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = Size(5, renderBox.size.height);
    final boxOffset = renderBox.localToGlobal(Offset.zero);
    final cursorOffset =
        Offset(renderBox.size.width + boxOffset.dx, boxOffset.dy);
    return cursorOffset & size;
  }

  @override
  TextSelection? getTextSelection() {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Image.network(src),
        if (node.children.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map(
                  (e) => editorState.renderPlugins.buildWidget(
                    context: NodeWidgetContext(
                      buildContext: context,
                      node: e,
                      editorState: editorState,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
