import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({
    required super.node,
    required super.editorState,
    required super.key,
  }) : super.create();

  @override
  Widget build(BuildContext context) {
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
  Position end() {
    // TODO: implement end
    throw UnimplementedError();
  }

  @override
  Position start() {
    // TODO: implement start
    throw UnimplementedError();
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    // TODO: implement getRectsInSelection
    throw UnimplementedError();
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    // TODO: implement getSelectionInRange
    throw UnimplementedError();
  }

  @override
  Offset localToGlobal(Offset offset) {
    throw UnimplementedError();
  }

  @override
  Rect getCursorRectInPosition(Position position) {
    // TODO: implement getCursorRectInPosition
    throw UnimplementedError();
  }

  @override
  Position getPositionInOffset(Offset start) {
    // TODO: implement getPositionInOffset
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Image.network(
          src,
          width: MediaQuery.of(context).size.width,
        )
      ],
    );
  }
}
