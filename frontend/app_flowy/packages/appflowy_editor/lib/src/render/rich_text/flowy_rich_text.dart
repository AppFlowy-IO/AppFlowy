import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';

typedef FlowyTextSpanDecorator = TextSpan Function(TextSpan textSpan);

class FlowyRichText extends StatefulWidget {
  const FlowyRichText({
    Key? key,
    this.cursorHeight,
    this.cursorWidth = 1.0,
    this.textSpanDecorator,
    this.placeholderText = ' ',
    this.placeholderTextSpanDecorator,
    required this.textNode,
    required this.editorState,
  }) : super(key: key);

  final TextNode textNode;
  final EditorState editorState;
  final double? cursorHeight;
  final double cursorWidth;
  final FlowyTextSpanDecorator? textSpanDecorator;
  final String placeholderText;
  final FlowyTextSpanDecorator? placeholderTextSpanDecorator;

  @override
  State<FlowyRichText> createState() => _FlowyRichTextState();
}

class _FlowyRichTextState extends State<FlowyRichText> with Selectable {
  final _textKey = GlobalKey();
  final _placeholderTextKey = GlobalKey();

  final _lineHeight = 1.5;

  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  RenderParagraph get _placeholderRenderParagraph =>
      _placeholderTextKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  Widget build(BuildContext context) {
    return _buildRichText(context);
  }

  @override
  Position start() => Position(path: widget.textNode.path, offset: 0);

  @override
  Position end() => Position(
      path: widget.textNode.path, offset: widget.textNode.delta.length);

  @override
  Rect? getCursorRectInPosition(Position position) {
    final textPosition = TextPosition(offset: position.offset);
    final cursorOffset =
        _renderParagraph.getOffsetForCaret(textPosition, Rect.zero);
    final cursorHeight = widget.cursorHeight ??
        _renderParagraph.getFullHeightForCaret(textPosition) ??
        _placeholderRenderParagraph.getFullHeightForCaret(textPosition) ??
        16.0; // default height

    final rect = Rect.fromLTWH(
      cursorOffset.dx - (widget.cursorWidth / 2),
      cursorOffset.dy,
      widget.cursorWidth,
      cursorHeight,
    );
    return rect;
  }

  @override
  Position getPositionInOffset(Offset start) {
    final offset = _renderParagraph.globalToLocal(start);
    final baseOffset = _renderParagraph.getPositionForOffset(offset).offset;
    return Position(path: widget.textNode.path, offset: baseOffset);
  }

  @override
  Selection? getWorldBoundaryInOffset(Offset offset) {
    final localOffset = _renderParagraph.globalToLocal(offset);
    final textPosition = _renderParagraph.getPositionForOffset(localOffset);
    final textRange = _renderParagraph.getWordBoundary(textPosition);
    final start = Position(path: widget.textNode.path, offset: textRange.start);
    final end = Position(path: widget.textNode.path, offset: textRange.end);
    return Selection(start: start, end: end);
  }

  @override
  List<Rect> getRectsInSelection(Selection selection) {
    assert(pathEquals(selection.start.path, selection.end.path) &&
        pathEquals(selection.start.path, widget.textNode.path));

    final textSelection = TextSelection(
      baseOffset: selection.start.offset,
      extentOffset: selection.end.offset,
    );
    return _renderParagraph
        .getBoxesForSelection(textSelection, boxHeightStyle: BoxHeightStyle.max)
        .map((box) => box.toRect())
        .toList();
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    final localStart = _renderParagraph.globalToLocal(start);
    final localEnd = _renderParagraph.globalToLocal(end);
    final baseOffset = _renderParagraph.getPositionForOffset(localStart).offset;
    final extentOffset = _renderParagraph.getPositionForOffset(localEnd).offset;
    return Selection.single(
      path: widget.textNode.path,
      startOffset: baseOffset,
      endOffset: extentOffset,
    );
  }

  Widget _buildRichText(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: widget.textNode.toRawString().isEmpty
          ? Stack(
              children: [
                _buildPlaceholderText(context),
                _buildSingleRichText(context),
              ],
            )
          : _buildSingleRichText(context),
    );
  }

  Widget _buildPlaceholderText(BuildContext context) {
    final textSpan = _placeholderTextSpan;
    return RichText(
      key: _placeholderTextKey,
      textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
      text: widget.textSpanDecorator != null
          ? widget.textSpanDecorator!(textSpan)
          : textSpan,
    );
  }

  Widget _buildSingleRichText(BuildContext context) {
    final textSpan = _textSpan;
    return RichText(
      key: _textKey,
      textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
      text: widget.textSpanDecorator != null
          ? widget.textSpanDecorator!(textSpan)
          : textSpan,
    );
  }

  // unused now.
  // Widget _buildRichTextWithChildren(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildSingleRichText(context),
  //       ...widget.textNode.children
  //           .map(
  //             (child) => widget.editorState.service.renderPluginService
  //                 .buildPluginWidget(
  //               NodeWidgetContext(
  //                 context: context,
  //                 node: child,
  //                 editorState: widget.editorState,
  //               ),
  //             ),
  //           )
  //           .toList()
  //     ],
  //   );
  // }

  @override
  Offset localToGlobal(Offset offset) {
    return _renderParagraph.localToGlobal(offset);
  }

  TextSpan get _textSpan => TextSpan(
        children: widget.textNode.delta
            .whereType<TextInsert>()
            .map((insert) => RichTextStyle(
                  attributes: insert.attributes ?? {},
                  text: insert.content,
                  height: _lineHeight,
                ).toTextSpan())
            .toList(growable: false),
      );

  TextSpan get _placeholderTextSpan => TextSpan(children: [
        RichTextStyle(
          text: widget.placeholderText,
          attributes: {
            StyleKey.color: '0xFF707070',
          },
          height: _lineHeight,
        ).toTextSpan()
      ]);
}
