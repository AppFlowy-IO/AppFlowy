import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

const String kDottedDividerType = 'dotted_divider';

class DottedDividerWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _DottedDividerWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class _DottedDividerWidget extends StatefulWidget {
  const _DottedDividerWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_DottedDividerWidget> createState() => _DottedDividerWidgetState();
}

class _DottedDividerWidgetState extends State<_DottedDividerWidget>
    with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(),
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
  CursorStyle get cursorStyle => CursorStyle.borderLine;

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



// class DottedDividerWidgetBuilder extends NodeWidgetBuilder<Node> {
//   @override
//   Widget build(NodeWidgetContext<Node> context) {
//     return _DottedDividerWidget(
//       key: context.node.key,
//       node: context.node,
//       editorState: context.editorState,
//     );
//   }

//   @override
//   NodeValidator<Node> get nodeValidator => (node) {
//         return true;
//       };
// }

// class _DottedDividerWidget extends StatefulWidget {
//   const _DottedDividerWidget({
//     Key? key,
//     required this.node,
//     required this.editorState,
//   }) : super(key: key);

//   final Node node;
//   final EditorState editorState;

//   @override
//   State<_DottedDividerWidget> createState() => _DottedDividerWidgetState();
// }

// class _DottedDividerWidgetState extends State<_DottedDividerWidget>
//     with SelectableMixin {
//   RenderBox get _renderBox => context.findRenderObject() as RenderBox;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: CustomPaint(
//         painter: DottedLinePainter(
//             editorState: widget.editorState, node: widget.node),
//         child: const SizedBox(height: 1),
//       ),
//     );
//   }

//   @override
//   Position start() => Position(path: widget.node.path, offset: 0);

//   @override
//   Position end() => Position(path: widget.node.path, offset: 1);

//   @override
//   Position getPositionInOffset(Offset start) => end();

//   @override
//   bool get shouldCursorBlink => false;

//   @override
//   CursorStyle get cursorStyle => CursorStyle.borderLine;

//   @override
//   Rect? getCursorRectInPosition(Position position) {
//     final size = _renderBox.size;
//     return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
//   }

//   @override
//   List<Rect> getRectsInSelection(Selection selection) =>
//       [Offset.zero & _renderBox.size];

//   @override
//   Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
//         path: widget.node.path,
//         startOffset: 0,
//         endOffset: 1,
//       );

//   @override
//   Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
// }

// class DottedLinePainter extends CustomPainter {
//   const DottedLinePainter({
//     Key? key,
//     required this.node,
//     required this.editorState,
//   }) : super();

//   final Node node;
//   final EditorState editorState;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.grey
//       ..strokeWidth = 1
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;
    
//     ui.Path _path = ui.Path();
//     const dashWidth = 5;
//     const dashSpace = 3;

//     for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
//       _path.moveTo(i + node.path[0], 0,);
//       _path.lineTo(i + node.path[0] + dashWidth, 0,);
//     }
//     canvas.drawPath(_path, paint);
//   }

//   @override
//   bool shouldRepaint(DottedLinePainter oldDelegate) => false;
// }
