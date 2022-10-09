import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
import 'package:appflowy_editor/src/extensions/text_style_extension.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';

import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';

const _kRichTextDebugMode = false;

typedef FlowyTextSpanDecorator = TextSpan Function(TextSpan textSpan);

class FlowyRichText extends StatefulWidget {
  const FlowyRichText({
    Key? key,
    this.cursorHeight,
    this.cursorWidth = 1.0,
    this.lineHeight = 1.0,
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
  final double lineHeight;
  final FlowyTextSpanDecorator? textSpanDecorator;
  final String placeholderText;
  final FlowyTextSpanDecorator? placeholderTextSpanDecorator;

  @override
  State<FlowyRichText> createState() => _FlowyRichTextState();
}

class _FlowyRichTextState extends State<FlowyRichText> with SelectableMixin {
  var _textKey = GlobalKey();
  final _placeholderTextKey = GlobalKey();

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
    assert(selection.isSingle &&
        selection.start.path.equals(widget.textNode.path));

    final textSelection = TextSelection(
      baseOffset: selection.start.offset,
      extentOffset: selection.end.offset,
    );
    final rects = _renderParagraph
        .getBoxesForSelection(textSelection, boxHeightStyle: BoxHeightStyle.max)
        .map((box) => box.toRect())
        .toList(growable: false);
    if (rects.isEmpty) {
      // If the rich text widget does not contain any text,
      // there will be no selection boxes,
      // so we need to return to the default selection.
      return [Rect.fromLTWH(0, 0, 0, _renderParagraph.size.height)];
    }
    return rects;
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
      child: widget.textNode.toPlainText().isEmpty
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
      text: widget.placeholderTextSpanDecorator != null
          ? widget.placeholderTextSpanDecorator!(textSpan)
          : textSpan,
    );
  }

  Widget _buildSingleRichText(BuildContext context) {
    final textSpan = _textSpan;
    return RichText(
      key: _textKey,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      text: widget.textSpanDecorator != null
          ? widget.textSpanDecorator!(textSpan)
          : textSpan,
    );
  }

  TextSpan get _placeholderTextSpan {
    final style = widget.editorState.editorStyle.textStyle;
    return TextSpan(
      children: [
        TextSpan(
          text: widget.placeholderText,
          style: style.defaultPlaceholderTextStyle,
        ),
      ],
    );
  }

  TextSpan get _textSpan {
    var offset = 0;
    List<TextSpan> textSpans = [];
    final style = widget.editorState.editorStyle.textStyle;
    final textInserts = widget.textNode.delta.whereType<TextInsert>();
    for (final textInsert in textInserts) {
      var textStyle = style.defaultTextStyle;
      GestureRecognizer? recognizer;
      final attributes = textInsert.attributes;
      if (attributes != null) {
        if (attributes.bold == true) {
          textStyle = textStyle.combine(style.bold);
        }
        if (attributes.italic == true) {
          textStyle = textStyle.combine(style.italic);
        }
        if (attributes.underline == true) {
          textStyle = textStyle.combine(style.underline);
        }
        if (attributes.strikethrough == true) {
          textStyle = textStyle.combine(style.strikethrough);
        }
        if (attributes.href != null) {
          textStyle = textStyle.combine(style.href);
          recognizer = _buildTapHrefGestureRecognizer(
            attributes.href!,
            Selection.single(
              path: widget.textNode.path,
              startOffset: offset,
              endOffset: offset + textInsert.length,
            ),
          );
        }
        if (attributes.code == true) {
          textStyle = textStyle.combine(style.code);
        }
        if (attributes.backgroundColor != null) {
          textStyle = textStyle.combine(
            TextStyle(backgroundColor: attributes.backgroundColor),
          );
        }
      }
      offset += textInsert.length;
      textSpans.add(
        TextSpan(
          text: textInsert.content,
          style: textStyle,
          recognizer: recognizer,
        ),
      );
    }
    if (_kRichTextDebugMode) {
      textSpans.add(
        TextSpan(
          text: '${widget.textNode.path}',
          style: const TextStyle(
            backgroundColor: Colors.red,
            fontSize: 16.0,
          ),
        ),
      );
    }
    return TextSpan(
      children: textSpans,
    );
  }

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
