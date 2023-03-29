import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/rich_text_with_selection.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class TextBlockBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return TextBlock(
      key: context.node.key,
      textNode: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class TextBlock extends StatefulWidget {
  const TextBlock({
    super.key,
    required this.textNode,
    this.onDebugMode = false,
    this.onTap,
    this.onDoubleTap,
  });

  final TextNode textNode;
  final bool onDebugMode;
  final Future<void> Function(Map<String, dynamic> values)? onTap;
  final Future<void> Function(Map<String, dynamic> values)? onDoubleTap;

  @override
  State<TextBlock> createState() => _TextBlockState();
}

class _TextBlockState extends State<TextBlock> with SelectableState {
  final GlobalKey _key = GlobalKey();
  RichTextWithSelectionState get _selectionState =>
      _key.currentState as RichTextWithSelectionState;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  TextSelection? _cacheSelection;

  @override
  void dispose() {
    editorState.service.selectionServiceV2.removeListerner(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    editorState.service.selectionServiceV2.addListenr(_onSelectionChanged);

    final selection = editorState.service.selectionServiceV2.selection;
    final textSelection = textSelectionFromEditorSelection(selection);

    final text = _buildTextSpan(widget.textNode);
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: RichTextWithSelection(
        key: _key,
        text: text,
        textSelection: textSelection,
      ),
    );
  }

  @override
  Position getPositionInOffset(Offset offset) {
    final textPosition = _selectionState.getTextPositionInOffset(offset);
    return Position(
      path: widget.textNode.path,
      offset: textPosition.offset,
    );
  }

  @override
  Future<void> setSelectionV2(Selection? selection) async {
    if (selection == null) {
      _selectionState.updateTextSelection(null);
      return;
    }
    final textSelection = textSelectionFromEditorSelection(selection);
    if (_cacheSelection == textSelection) {
      return;
    }
    _cacheSelection = textSelection;
    _selectionState.updateTextSelection(textSelection);
  }

  void _onSelectionChanged() {
    final selection = editorState.service.selectionServiceV2.selection;
    setSelectionV2(selection);
  }

  TextSelection? textSelectionFromEditorSelection(Selection? selection) {
    if (selection == null) {
      return null;
    }

    final normalized = selection.normalized;
    final path = widget.textNode.path;
    if (path < normalized.start.path || path > normalized.end.path) {
      return null;
    }

    TextSelection? textSelection;
    final length = widget.textNode.delta.length;
    if (normalized.isSingle) {
      if (path.equals(normalized.start.path)) {
        if (normalized.isCollapsed) {
          textSelection = TextSelection.collapsed(
            offset: normalized.startIndex,
          );
        } else {
          textSelection = TextSelection(
            baseOffset: normalized.startIndex,
            extentOffset: normalized.endIndex,
          );
        }
      }
    } else {
      if (path.equals(normalized.start.path)) {
        textSelection = TextSelection(
          baseOffset: normalized.startIndex,
          extentOffset: length,
        );
      } else if (path.equals(normalized.end.path)) {
        textSelection = TextSelection(
          baseOffset: 0,
          extentOffset: normalized.endIndex,
        );
      } else {
        textSelection = TextSelection(
          baseOffset: 0,
          extentOffset: length,
        );
      }
    }
    return textSelection;
  }

  TextSpan _buildTextSpan(TextNode textNode) {
    List<TextSpan> textSpans = [];
    final style = editorState.editorStyle;
    final textInserts = textNode.delta.whereType<TextInsert>();
    for (final textInsert in textInserts) {
      var textStyle = style.textStyle!;
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
          recognizer = _buildGestureRecognizer(
            {
              'href': attributes.href!,
            },
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
        if (attributes.color != null) {
          textStyle = textStyle.combine(
            TextStyle(color: attributes.color),
          );
        }
      }
      textSpans.add(
        TextSpan(
          text: textInsert.text,
          style: textStyle,
          recognizer: recognizer,
        ),
      );
    }
    if (widget.onDebugMode) {
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

  GestureRecognizer _buildGestureRecognizer(Map<String, dynamic> values) {
    Timer? timer;
    var tapCount = 0;
    final tapGestureRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        // implement a simple double tap logic
        tapCount += 1;
        timer?.cancel();

        if (tapCount == 2) {
          tapCount = 0;
          widget.onDoubleTap?.call(values);
          return;
        }

        timer = Timer(const Duration(milliseconds: 200), () {
          tapCount = 0;
          widget.onTap?.call(values);
        });
      };
    return tapGestureRecognizer;
  }
}
