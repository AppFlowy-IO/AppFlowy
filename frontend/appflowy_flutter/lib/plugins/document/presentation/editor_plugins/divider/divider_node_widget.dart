import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class DividerBlockKeys {
  const DividerBlockKeys._();

  static const String type = 'divider';
}

// creating a new callout node
Node dividerNode() {
  return Node(
    type: DividerBlockKeys.type,
  );
}

class DividerBlockComponentBuilder extends BlockComponentBuilder {
  const DividerBlockComponentBuilder({
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.lineColor = Colors.grey,
  });

  final EdgeInsets padding;
  final Color lineColor;

  @override
  Widget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return DividerBlockComponentWidget(
      key: node.key,
      node: node,
      padding: padding,
      lineColor: lineColor,
    );
  }

  @override
  bool validate(Node node) => node.children.isEmpty;
}

class DividerBlockComponentWidget extends StatefulWidget {
  const DividerBlockComponentWidget({
    Key? key,
    required this.node,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.lineColor = Colors.grey,
  }) : super(key: key);

  final Node node;
  final EdgeInsets padding;
  final Color lineColor;

  @override
  State<DividerBlockComponentWidget> createState() =>
      _DividerBlockComponentWidgetState();
}

class _DividerBlockComponentWidgetState
    extends State<DividerBlockComponentWidget> with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Container(
        height: 1,
        color: widget.lineColor,
      ),
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect? getCursorRectInPosition(Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

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
