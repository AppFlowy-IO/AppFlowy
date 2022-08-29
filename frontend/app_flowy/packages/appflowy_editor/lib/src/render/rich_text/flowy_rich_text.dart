import 'dart:async';
import 'dart:ui';

import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:flutter/gestures.dart';
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
  var _textKey = GlobalKey();
  final _placeholderTextKey = GlobalKey();

  final _lineHeight = 1.5;

  RenderParagraph get _renderParagraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph;

  RenderParagraph get _placeholderRenderParagraph =>
      _placeholderTextKey.currentContext?.findRenderObject() as RenderParagraph;

  @override
  void didUpdateWidget(covariant FlowyRichText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // https://github.com/flutter/flutter/issues/110342
    if (_textKey.currentWidget is RichText) {
      // Force refresh the RichText widget.
      _textKey = GlobalKey();
    }
  }

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

    var cursorHeight = _renderParagraph.getFullHeightForCaret(textPosition);
    var cursorOffset =
        _renderParagraph.getOffsetForCaret(textPosition, Rect.zero);
    if (cursorHeight == null) {
      cursorHeight =
          _placeholderRenderParagraph.getFullHeightForCaret(textPosition);
      cursorOffset = _placeholderRenderParagraph.getOffsetForCaret(
          textPosition, Rect.zero);
    }
    if (cursorHeight != null) {
      // workaround: Calling the `getFullHeightForCaret` function will return
      // the full height of rich text component instead of the plain text
      // if we set the line height.
      // So need to divide by the line height to get the expected value.
      //
      // And the default height of plain text is too short. Add a magic height
      // to expand it.
      const magicHeight = 3.0;
      cursorOffset = cursorOffset.translate(
          0, (cursorHeight - cursorHeight / _lineHeight) / 2.0);
      cursorHeight /= _lineHeight;
      cursorHeight += magicHeight;
    }
    final rect = Rect.fromLTWH(
      cursorOffset.dx - (widget.cursorWidth / 2),
      cursorOffset.dy,
      widget.cursorWidth,
      widget.cursorHeight ?? cursorHeight ?? 16.0,
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

  @override
  Offset localToGlobal(Offset offset) {
    return _renderParagraph.localToGlobal(offset);
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

  TextSpan get _textSpan {
    var offset = 0;
    return TextSpan(
      children: widget.textNode.delta.whereType<TextInsert>().map((insert) {
        GestureRecognizer? gestureRecognizer;
        if (insert.attributes?[StyleKey.href] != null) {
          gestureRecognizer = _buildTapHrefGestureRecognizer(
            insert.attributes![StyleKey.href],
            Selection.single(
              path: widget.textNode.path,
              startOffset: offset,
              endOffset: offset + insert.length,
            ),
          );
        }
        offset += insert.length;
        final textSpan = RichTextStyle(
          attributes: insert.attributes ?? {},
          text: insert.content,
          height: _lineHeight,
          gestureRecognizer: gestureRecognizer,
        ).toTextSpan();
        return textSpan;
      }).toList(growable: false),
    );
  }

  TextSpan get _placeholderTextSpan => TextSpan(children: [
        RichTextStyle(
          text: widget.placeholderText,
          attributes: {
            StyleKey.color: '0xFF707070',
          },
          height: _lineHeight,
        ).toTextSpan()
      ]);

  GestureRecognizer _buildTapHrefGestureRecognizer(
      String href, Selection selection) {
    Timer? timer;
    var tapCount = 0;
    final tapGestureRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        // implement a simple double tap logic
        tapCount += 1;
        timer?.cancel();

        if (tapCount == 2) {
          tapCount = 0;
          safeLaunchUrl(href);
          return;
        }

        timer = Timer(const Duration(milliseconds: 200), () {
          tapCount = 0;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            showLinkMenu(
              context,
              widget.editorState,
              customSelection: selection,
            );
          });
        });
      };
    return tapGestureRecognizer;
  }
}
