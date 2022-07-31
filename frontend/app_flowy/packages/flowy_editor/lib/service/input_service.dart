import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';

mixin FlowyInputService {
  void attach(TextEditingValue textEditingValue);
  void setTextEditingValue(TextEditingValue textEditingValue);
  void apply(List<TextEditingDelta> deltas);
  void close();
}

/// process input
class FlowyInput extends StatefulWidget {
  const FlowyInput({
    Key? key,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;

  @override
  State<FlowyInput> createState() => _FlowyInputState();
}

class _FlowyInputState extends State<FlowyInput>
    with FlowyInputService
    implements DeltaTextInputClient {
  TextInputConnection? _textInputConnection;

  EditorState get _editorState => widget.editorState;

  @override
  void initState() {
    super.initState();

    _editorState.service.selectionService.currentSelectedNodes
        .addListener(_onSelectedNodesChange);
  }

  @override
  void dispose() {
    _editorState.service.selectionService.currentSelectedNodes
        .removeListener(_onSelectedNodesChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }

  @override
  void attach(TextEditingValue textEditingValue) {
    if (_textInputConnection != null) {
      return;
    }

    _textInputConnection = TextInput.attach(
      this,
      const TextInputConfiguration(
        // TODO: customize
        enableDeltaModel: true,
        inputType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
      ),
    );

    _textInputConnection
      ?..show()
      ..setEditingState(textEditingValue);
  }

  @override
  void setTextEditingValue(TextEditingValue textEditingValue) {
    assert(_textInputConnection != null,
        'Must call `attach` before set textEditingValue');
    if (_textInputConnection != null) {
      _textInputConnection?.setEditingState(textEditingValue);
    }
  }

  @override
  void apply(List<TextEditingDelta> deltas) {
    // TODO: implement the detail
    for (final delta in deltas) {
      if (delta is TextEditingDeltaInsertion) {
        _applyInsert(delta);
      } else if (delta is TextEditingDeltaDeletion) {
      } else if (delta is TextEditingDeltaReplacement) {
        _applyReplacement(delta);
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        // We don't need to care the [TextEditingDeltaNonTextUpdate].
        // Do nothing.
      }
    }
  }

  void _applyInsert(TextEditingDeltaInsertion delta) {
    final selectionService = _editorState.service.selectionService;
    final currentSelection = selectionService.currentSelection;
    if (currentSelection == null) {
      return;
    }
    if (currentSelection.isSingle) {
      final textNode =
          selectionService.currentSelectedNodes.value.first as TextNode;
      TransactionBuilder(_editorState)
        ..insertText(
          textNode,
          delta.insertionOffset,
          delta.textInserted,
        )
        ..commit();
    } else {
      // TODO: implement
    }
  }

  void _applyReplacement(TextEditingDeltaReplacement delta) {
    final selectionService = _editorState.service.selectionService;
    final currentSelection = selectionService.currentSelection;
    if (currentSelection == null) {
      return;
    }
    if (currentSelection.isSingle) {
      final textNode =
          selectionService.currentSelectedNodes.value.first as TextNode;
      final length = delta.replacedRange.end - delta.replacedRange.start;
      TransactionBuilder(_editorState)
        ..replaceText(
            textNode, delta.replacedRange.start, length, delta.replacementText)
        ..commit();
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
    debugPrint(textEditingDeltas.map((delta) => delta.toString()).toString());

    apply(textEditingDeltas);
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  void _onSelectedNodesChange() {
    final nodes =
        _editorState.service.selectionService.currentSelectedNodes.value;
    final selection = _editorState.service.selectionService.currentSelection;
    // FIXME: upward.
    if (nodes.isNotEmpty && selection != null) {
      final textNodes = nodes.whereType<TextNode>();
      final text = textNodes.fold<String>(
          '', (sum, textNode) => '$sum${textNode.toRawString()}\n');
      attach(
        TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: selection.start.offset,
            extentOffset: selection.end.offset,
          ),
        ),
      );
    } else {
      close();
    }
  }
}
