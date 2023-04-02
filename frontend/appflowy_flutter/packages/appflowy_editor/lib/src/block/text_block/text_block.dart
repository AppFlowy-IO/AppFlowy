import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/input/input_service.dart';
import 'package:appflowy_editor/src/block/base_component/shortcuts/shortcut_service.dart';
import 'package:appflowy_editor/src/block/base_component/widget/rich_text_with_selection.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:appflowy_editor/src/extensions/text_style_extension.dart';

typedef TextSpanDecorator = TextSpan Function(TextSpan textSpan);

class TextBlock extends StatefulWidget {
  const TextBlock({
    super.key,
    required this.delta,
    required this.path,
    this.onInsert,
    this.onDelete,
    this.onReplace,
    this.onNonTextUpdate,
    this.onDebugMode = true,
    this.onTap,
    this.onDoubleTap,
    this.shortcuts = const [],
    this.textSpanDecorator,
  });

  final Delta delta;
  final Path path;
  final bool onDebugMode;
  final Future<void> Function(Map<String, dynamic> values)? onTap;
  final Future<void> Function(Map<String, dynamic> values)? onDoubleTap;

  final List<ShortcutEvent> shortcuts;

  final Future<void> Function(TextEditingDeltaInsertion insertion)? onInsert;
  final Future<void> Function(TextEditingDeltaDeletion deletion)? onDelete;
  final Future<void> Function(TextEditingDeltaReplacement replacement)?
      onReplace;
  final Future<void> Function(TextEditingDeltaNonTextUpdate nonTextUpdate)?
      onNonTextUpdate;

  final TextSpanDecorator? textSpanDecorator;

  @override
  State<TextBlock> createState() => TextBlockState();
}

class TextBlockState extends State<TextBlock>
    implements SelectableState<TextBlock> {
  final GlobalKey _key = GlobalKey();

  late final _editorState = Provider.of<EditorState>(context, listen: false);

  TextInputService? _inputService;
  TextSelection? _cacheSelection;

  FocusNode? _focusNode;

  RichTextWithSelectionState get selectionState =>
      _key.currentState as RichTextWithSelectionState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        _editorState.service.selectionServiceV2
            .addListener(_onSelectionChanged);
      }
    });
  }

  @override
  void dispose() {
    _editorState.service.selectionServiceV2.removeListener(_onSelectionChanged);
    _closeInputService();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _buildTextSpan(widget.delta);
    final selection = _editorState.service.selectionServiceV2.selection;
    final textSelection = textSelectionFromEditorSelection(selection);
    _cacheSelection = textSelection;

    Widget child = MouseRegion(
      cursor: SystemMouseCursors.text,
      child: RichTextWithSelection(
        key: _key,
        text: text,
        textSelection: textSelection,
      ),
    );

    if (widget.shortcuts.isNotEmpty) {
      child = TextBlockShortcuts(
        focusNode: _focusNode ??= FocusNode(),
        textBlockState: this,
        shortcuts: widget.shortcuts,
        child: child,
      );
    }

    return child;
  }

  @override
  Position getPositionInOffset(Offset offset) {
    final textPosition = selectionState.getTextPositionInOffset(offset);
    return Position(
      path: widget.path,
      offset: textPosition.offset,
    );
  }

  @override
  Future<void> setSelectionV2(Selection? selection) async {
    if (selection == null) {
      selectionState.updateTextSelection(null);
      return;
    }
    final textSelection = textSelectionFromEditorSelection(selection);
    if (_cacheSelection == textSelection) {
      return;
    }
    _cacheSelection = textSelection;
    selectionState.updateTextSelection(textSelection);
  }

  void _buildDeltaInputServiceIfNeed() {
    _inputService ??= DeltaTextInputService(
      onInsert: widget.onInsert ?? _voidFutureCallback,
      onDelete: widget.onDelete ?? _voidFutureCallback,
      onReplace: widget.onReplace ?? _voidFutureCallback,
      onNonTextUpdate: widget.onNonTextUpdate ?? _voidFutureCallback,
    );
  }

  Future<void> _voidFutureCallback(dynamic value) async {}

  // TODO: DON'T attach the input service every time.
  void _attachInputService() {
    assert(_inputService != null && _cacheSelection != null);
    if (_cacheSelection == null) {
      return;
    }
    Log.input.debug('attach input service');
    final plainText = widget.delta.toPlainText();
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
      final rect = selectionState.getCaretRect(TextPosition(
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

  void _onSelectionChanged() {
    final selection = _editorState.service.selectionServiceV2.selection;
    setSelectionV2(selection);

    // if the selection.isCollapsed, we should show the input service
    if (selection != null &&
        selection.isSingle &&
        selection.start.path.equals(widget.path)) {
      // input
      _buildDeltaInputServiceIfNeed();
      _attachInputService();

      // shortcuts
      _focusNode?.requestFocus();
    } else {
      // input
      _closeInputService();

      // shortcuts
      _focusNode?.unfocus();
    }
  }

  TextSelection? textSelectionFromEditorSelection(Selection? selection) {
    if (selection == null) {
      return null;
    }

    final normalized = selection.normalized;
    final path = widget.path;
    if (path < normalized.start.path || path > normalized.end.path) {
      return null;
    }

    TextSelection? textSelection;
    final length = widget.delta.length;
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

  TextSpan _buildTextSpan(Delta delta) {
    List<TextSpan> textSpans = [];
    final style = _editorState.editorStyle;
    final textInserts = delta.whereType<TextInsert>();
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
          text: '${widget.path}',
          style: const TextStyle(
            backgroundColor: Colors.red,
            fontSize: 16.0,
          ),
        ),
      );
    }
    final textSpan = TextSpan(
      children: textSpans,
    );
    return (widget.textSpanDecorator ?? (v) => v).call(textSpan);
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
