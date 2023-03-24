import 'package:appflowy_editor/src/infra/log.dart';
import 'package:appflowy_editor/src/core/transform/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';

/// [AppFlowyInputService] is responsible for processing text input,
///   including text insertion, deletion and replacement.
///
/// Usually, this service can be obtained by the following code.
/// ```dart
/// final inputService = editorState.service.inputService;
///
/// /** update text editing value*/
/// inputService?.attach(...);
///
/// /** apply text editing deltas*/
/// inputService?.apply(...);
/// ```
///
abstract class AppFlowyInputService {
  /// Updates the [TextEditingValue] of the text currently being edited.
  ///
  /// Note that if there are IME-related requirements,
  ///   please config `composing` value within [TextEditingValue]
  void attach(TextEditingValue textEditingValue);

  /// Applies insertion, deletion and replacement
  ///   to the text currently being edited.
  ///
  /// For more information, please check [TextEditingDelta].
  void apply(List<TextEditingDelta> deltas);

  /// Closes the editing state of the text currently being edited.
  void close();
}

/// Processes text input
class AppFlowyInput extends StatefulWidget {
  const AppFlowyInput({
    Key? key,
    this.editable = true,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final bool editable;
  final Widget child;

  @override
  State<AppFlowyInput> createState() => _AppFlowyInputState();
}

class _AppFlowyInputState extends State<AppFlowyInput>
    implements AppFlowyInputService, DeltaTextInputClient {
  TextInputConnection? _textInputConnection;
  TextRange? _composingTextRange;

  EditorState get _editorState => widget.editorState;

  // Disable space shortcut on the Web platform.
  final Map<ShortcutActivator, Intent> _shortcuts = kIsWeb
      ? {
          LogicalKeySet(LogicalKeyboardKey.space):
              const DoNothingAndStopPropagationIntent(),
        }
      : {};

  @override
  void initState() {
    super.initState();

    if (widget.editable) {
      _editorState.service.selectionService.currentSelection
          .addListener(_onSelectionChange);
    }
  }

  @override
  void dispose() {
    if (widget.editable) {
      close();
      _editorState.service.selectionService.currentSelection
          .removeListener(_onSelectionChange);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: widget.child,
    );
  }

  @override
  void attach(TextEditingValue textEditingValue) {
    if (_textInputConnection == null ||
        _textInputConnection!.attached == false) {
      _textInputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          // TODO: customize
          enableDeltaModel: true,
          inputType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
        ),
      );
    }

    _textInputConnection!
      ..setEditingState(textEditingValue)
      ..show();
  }

  @override
  void apply(List<TextEditingDelta> deltas) {
    // TODO: implement the detail
    for (final delta in deltas) {
      _updateComposing(delta);

      if (delta is TextEditingDeltaInsertion) {
        _applyInsert(delta);
      } else if (delta is TextEditingDeltaDeletion) {
        _applyDelete(delta);
      } else if (delta is TextEditingDeltaReplacement) {
        _applyReplacement(delta);
      } else if (delta is TextEditingDeltaNonTextUpdate) {}
    }
  }

  void _updateComposing(TextEditingDelta delta) {
    if (delta is! TextEditingDeltaNonTextUpdate) {
      if (_composingTextRange != null &&
          delta.composing.end != -1 &&
          _composingTextRange!.start != -1) {
        _composingTextRange = TextRange(
          start: _composingTextRange!.start,
          end: delta.composing.end,
        );
      } else {
        _composingTextRange = delta.composing;
      }
    }
  }

  void _applyInsert(TextEditingDeltaInsertion delta) {
    final selectionService = _editorState.service.selectionService;
    final currentSelection = selectionService.currentSelection.value;
    if (currentSelection == null) {
      return;
    }
    if (currentSelection.isSingle) {
      final textNode = selectionService.currentSelectedNodes.first as TextNode;
      final transaction = _editorState.transaction;
      transaction.insertText(
        textNode,
        delta.insertionOffset,
        delta.textInserted,
      );
      _editorState.apply(transaction);
    } else {
      // TODO: implement
    }
  }

  void _applyDelete(TextEditingDeltaDeletion delta) {
    final selectionService = _editorState.service.selectionService;
    final currentSelection = selectionService.currentSelection.value;
    if (currentSelection == null) {
      return;
    }
    if (currentSelection.isSingle) {
      final textNode = selectionService.currentSelectedNodes.first as TextNode;
      final length = delta.deletedRange.end - delta.deletedRange.start;
      final transaction = _editorState.transaction;
      transaction.deleteText(textNode, delta.deletedRange.start, length);
      _editorState.apply(transaction);
    } else {
      // TODO: implement
    }
  }

  void _applyReplacement(TextEditingDeltaReplacement delta) {
    final selectionService = _editorState.service.selectionService;
    final currentSelection = selectionService.currentSelection.value;
    if (currentSelection == null) {
      return;
    }
    if (currentSelection.isSingle) {
      final textNode = selectionService.currentSelectedNodes.first as TextNode;
      final length = delta.replacedRange.end - delta.replacedRange.start;
      final transaction = _editorState.transaction;
      transaction.replaceText(
          textNode, delta.replacedRange.start, length, delta.replacementText);
      _editorState.apply(transaction);
    } else {
      // TODO: implement
    }
  }

  @override
  void close() {
    _textInputConnection?.close();
    _textInputConnection = null;
  }

  @override
  void connectionClosed() {
    // TODO: implement connectionClosed
  }

  @override
  // TODO: implement currentAutofillScope
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  // TODO: implement currentTextEditingValue
  TextEditingValue? get currentTextEditingValue => throw UnimplementedError();

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void showToolbar() {
    // TODO: implement showToolbar
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // TODO: implement updateEditingValue
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    Log.input
        .debug(textEditingDeltas.map((delta) => delta.toString()).toString());

    apply(textEditingDeltas);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  void _onSelectionChange() {
    final textNodes = _editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    final selection =
        _editorState.service.selectionService.currentSelection.value;
    // FIXME: upward and selection update.
    if (textNodes.isNotEmpty && selection != null) {
      final text = textNodes.fold<String>(
          '', (sum, textNode) => '$sum${textNode.toPlainText()}\n');
      attach(
        TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: selection.start.offset,
            extentOffset: selection.end.offset,
          ),
          composing: _composingTextRange ?? const TextRange.collapsed(-1),
        ),
      );
      if (textNodes.length == 1) {
        _updateCaretPosition(textNodes.first, selection);
      }
    } else {
      // https://github.com/flutter/flutter/issues/104944
      // Disable IME for the Web.
      if (kIsWeb) {
        close();
      }
    }
  }

  // TODO: support IME in linux / windows / ios / android
  // Only support macOS now.
  void _updateCaretPosition(TextNode textNode, Selection selection) {
    if (!selection.isCollapsed) {
      return;
    }
    final renderBox = textNode.renderBox;
    final selectable = textNode.selectable;
    if (renderBox != null && selectable != null) {
      final size = renderBox.size;
      final transform = renderBox.getTransformTo(null);
      final rect = selectable.getCursorRectInPosition(selection.end);
      if (rect != null) {
        _textInputConnection
          ?..setEditableSizeAndTransform(size, transform)
          ..setCaretRect(rect);
      }
    }
  }
}
