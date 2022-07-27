import 'dart:math';

import 'package:example/plugin/debuggable_rich_text.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SelectedTextNodeBuilder extends NodeWidgetBuilder {
  SelectedTextNodeBuilder.create({
    required super.node,
    required super.editorState,
    required super.key,
  }) : super.create() {
    nodeValidator = ((node) {
      return node.type == 'text';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SelectedTextNodeWidget(
      key: key,
      node: node,
      editorState: editorState,
    );
  }
}

class _SelectedTextNodeWidget extends StatefulWidget {
  final Node node;
  final EditorState editorState;

  const _SelectedTextNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  State<_SelectedTextNodeWidget> createState() =>
      _SelectedTextNodeWidgetState();
}

class _SelectedTextNodeWidgetState extends State<_SelectedTextNodeWidget>
    with Selectable {
  TextNode get node => widget.node as TextNode;
  EditorState get editorState => widget.editorState;

  final _textKey = GlobalKey();
  TextSelection? _textSelection;

  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    final localStart = _renderParagraph.globalToLocal(start);
    final localEnd = _renderParagraph.globalToLocal(end);
    final baseOffset = _getTextPositionAtOffset(localStart).offset;
    final extentOffset = _getTextPositionAtOffset(localEnd).offset;
    return Selection.single(
      path: node.path,
      startOffset: baseOffset,
      endOffset: extentOffset,
    );
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    assert(pathEquals(selection.start.path, selection.end.path));
    assert(pathEquals(selection.start.path, node.path));
    final textSelection = TextSelection(
      baseOffset: selection.start.offset,
      extentOffset: selection.end.offset,
    );
    return _computeSelectionRects(textSelection);
  }

  @override
  Rect getCursorRectInPosition(Position position) {
    final textSelection = TextSelection.collapsed(offset: position.offset);
    _textSelection = textSelection;
    return _computeCursorRect(textSelection.baseOffset);
  }

  @override
  Position getPositionInOffset(Offset start) {
    final localStart = _renderParagraph.globalToLocal(start);
    final baseOffset = _getTextPositionAtOffset(localStart).offset;
    return Position(path: node.path, offset: baseOffset);
  }

  @override
  TextSelection? getTextSelectionInSelection(Selection selection) {
    assert(selection.isCollapsed);
    if (!selection.isCollapsed) {
      return null;
    }
    return TextSelection(
      baseOffset: selection.start.offset,
      extentOffset: selection.end.offset,
    );
  }

  @override
  Position start() => Position(path: node.path, offset: 0);

  @override
  Position end() =>
      Position(path: node.path, offset: node.toRawString().length);

  @override
  Widget build(BuildContext context) {
    Widget richText;
    if (kDebugMode) {
      richText = DebuggableRichText(text: node.toTextSpan(), textKey: _textKey);
    } else {
      richText = RichText(key: _textKey, text: node.toTextSpan());
    }

    if (node.children.isEmpty) {
      return richText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: richText,
        ),
        if (node.children.isNotEmpty)
          ...node.children.map(
            (e) => editorState.renderPlugins.buildWidget(
              context: NodeWidgetContext(
                buildContext: context,
                node: e,
                editorState: editorState,
              ),
            ),
          ),
        const SizedBox(
          height: 5,
        ),
      ],
    );
  }

  TextPosition _getTextPositionAtOffset(Offset offset) {
    return _renderParagraph.getPositionForOffset(offset);
  }

  List<Rect> _computeSelectionRects(TextSelection textSelection) {
    final textBoxes = _renderParagraph.getBoxesForSelection(textSelection);
    return textBoxes.map((box) => box.toRect()).toList();
  }

  Rect _computeCursorRect(int offset) {
    final position = TextPosition(offset: offset);
    final cursorOffset =
        _renderParagraph.getOffsetForCaret(position, Rect.zero);
    final cursorHeight = _renderParagraph.getFullHeightForCaret(position);
    if (cursorHeight != null) {
      const cursorWidth = 2;
      return Rect.fromLTWH(
        cursorOffset.dx - (cursorWidth / 2),
        cursorOffset.dy,
        cursorWidth.toDouble(),
        cursorHeight.toDouble(),
      );
    } else {
      return Rect.zero;
    }
  }
}

extension on TextNode {
  TextSpan toTextSpan() => TextSpan(
      children: delta.operations
          .whereType<TextInsert>()
          .map((op) => op.toTextSpan())
          .toList());
}

extension on TextInsert {
  TextSpan toTextSpan() {
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    TextDecoration? decoration;
    GestureRecognizer? gestureRecognizer;
    Color color = Colors.black;
    Color highLightColor = Colors.transparent;
    double fontSize = 16.0;
    final attributes = this.attributes;
    if (attributes?['bold'] == true) {
      fontWeight = FontWeight.bold;
    }
    if (attributes?['italic'] == true) {
      fontStyle = FontStyle.italic;
    }
    if (attributes?['underline'] == true) {
      decoration = TextDecoration.underline;
    }
    if (attributes?['strikethrough'] == true) {
      decoration = TextDecoration.lineThrough;
    }
    if (attributes?['highlight'] is String) {
      highLightColor = Color(int.parse(attributes!['highlight']));
    }
    if (attributes?['href'] is String) {
      color = const Color.fromARGB(255, 55, 120, 245);
      decoration = TextDecoration.underline;
      gestureRecognizer = TapGestureRecognizer()
        ..onTap = () {
          launchUrlString(attributes?['href']);
        };
    }
    final heading = attributes?['heading'] as String?;
    if (heading != null) {
      // TODO: make it better
      if (heading == 'h1') {
        fontSize = 30.0;
      } else if (heading == 'h2') {
        fontSize = 20.0;
      }
      fontWeight = FontWeight.bold;
    }
    return TextSpan(
      text: content,
      style: TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: color,
        fontSize: fontSize,
        backgroundColor: highLightColor,
      ),
      recognizer: gestureRecognizer,
    );
  }
}

class FlowyPainter extends CustomPainter {
  final List<Rect> _rects;
  final Paint _paint;

  FlowyPainter({
    Key? key,
    required Color color,
    required List<Rect> rects,
    bool fill = false,
  })  : _rects = rects,
        _paint = Paint()..color = color {
    _paint.style = fill ? PaintingStyle.fill : PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in _rects) {
      canvas.drawRect(
        rect,
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
