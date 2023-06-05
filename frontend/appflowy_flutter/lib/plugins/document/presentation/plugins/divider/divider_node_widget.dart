import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const String kDividerType = 'divider';

class DividerWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(final NodeWidgetContext<Node> context) {
    return _DividerWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (final node) {
        return true;
      };
}

class _DividerWidget extends StatefulWidget {
  const _DividerWidget({
    final Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_DividerWidget> createState() => _DividerWidgetState();
}

class _DividerWidgetState extends State<_DividerWidget> with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        color: Colors.grey,
      ),
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(final Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.borderLine;

  @override
  Rect? getCursorRectInPosition(final Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(final Selection selection) =>
      [Offset.zero & _renderBox.size];

  @override
  Selection getSelectionInRange(final Offset start, final Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(final Offset offset) => _renderBox.localToGlobal(offset);
}
