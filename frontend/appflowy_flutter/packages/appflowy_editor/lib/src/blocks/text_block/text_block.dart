import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/input/input_service.dart';
import 'package:appflowy_editor/src/blocks/base_component/rich_text_with_selection.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

class TextBlock extends StatefulWidget {
  const TextBlock({
    super.key,
    required this.textNode,
    this.onDebugMode = true,
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

  late final _editorState = Provider.of<EditorState>(context, listen: false);

  TextInputService? _inputService;
  TextSelection? _cacheSelection;

  RichTextWithSelectionState get _selectionState =>
      _key.currentState as RichTextWithSelectionState;

  @override
  void dispose() {
    _editorState.service.selectionServiceV2.removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _editorState.service.selectionServiceV2.addListener(_onSelectionChanged);

    final selection = _editorState.service.selectionServiceV2.selection;
    final textSelection = _textSelectionFromEditorSelection(selection);

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
    final textSelection = _textSelectionFromEditorSelection(selection);
    if (_cacheSelection == textSelection) {
      return;
    }
    _cacheSelection = textSelection;
    _selectionState.updateTextSelection(textSelection);
  }

  void _buildDeltaInputServiceIfNeed() {
    _inputService ??= DeltaTextInputService(
      onInsert: _onInsert,
      onDelete: _onDelete,
      onReplace: _onReplace,
      onNonTextUpdate: _onNonTextUpdate,
    );
  }

  void _attachInputService() {
    assert(_inputService != null && _cacheSelection != null);
    if (_cacheSelection == null) {
      return;
    }
    Log.input.debug('attach input service');
    final plainText = widget.textNode.toPlainText();
    final value = TextEditingValue(
      text: plainText,
      selection: _cacheSelection!,
      composing:
          _inputService?.composingTextRange ?? const TextRange.collapsed(-1),
    );
    _inputService?.attach(value);
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final transform = renderBox.getTransformTo(null);
      final rect = _selectionState.getCaretRect(TextPosition(
        offset: _cacheSelection!.extentOffset,
      ));
      _inputService?.updateCaretPosition(size, transform, rect);
    }
  }

  void _closeInputService() {
    if (_inputService == null) {
      return;
    }
    Log.input.debug('close input service');
    _inputService?.close();
    _inputService = null;
  }

  Future<void> _onInsert(TextEditingDeltaInsertion insertion) async {
    Log.input.debug('[Insert]: $insertion');

    final tr = _editorState.transaction
      ..insertText(
        widget.textNode,
        insertion.insertionOffset,
        insertion.textInserted,
      );
    return _editorState.apply(tr);
  }

  Future<void> _onDelete(TextEditingDeltaDeletion deletion) async {
    Log.input.debug('[Delete]: $deletion');

    // This function never be called, WHY?
  }

  Future<void> _onReplace(TextEditingDeltaReplacement replacement) async {
    Log.input.debug('[Replace]: $replacement');

    final tr = _editorState.transaction
      ..replaceText(
        widget.textNode,
        replacement.replacedRange.start,
        replacement.replacedRange.end - replacement.replacedRange.start,
        replacement.replacementText,
      );
    return _editorState.apply(tr);
  }

  Future<void> _onNonTextUpdate(
    TextEditingDeltaNonTextUpdate nonTextUpdate,
  ) async {
    Log.input.debug('[NonTextUpdate]: $nonTextUpdate');
  }

  void _onSelectionChanged() {
    final selection = _editorState.service.selectionServiceV2.selection;
    setSelectionV2(selection);

    // if the selection.isCollapsed, we should show the input service
    if (selection != null &&
        selection.isSingle &&
        selection.start.path.equals(widget.textNode.path)) {
      _buildDeltaInputServiceIfNeed();
      _attachInputService();
    } else {
      _closeInputService();
    }
  }

  TextSelection? _textSelectionFromEditorSelection(Selection? selection) {
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
    final style = _editorState.editorStyle;
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
