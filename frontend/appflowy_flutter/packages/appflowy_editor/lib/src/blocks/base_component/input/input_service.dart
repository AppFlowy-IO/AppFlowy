import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';

abstract class TextInputService {
  TextInputService({
    required this.onInsert,
    required this.onDelete,
    required this.onReplace,
    required this.onNonTextUpdate,
  });

  Future<void> Function(TextEditingDeltaInsertion insertion) onInsert;
  Future<void> Function(TextEditingDeltaDeletion deletion) onDelete;
  Future<void> Function(TextEditingDeltaReplacement replacement) onReplace;
  Future<void> Function(TextEditingDeltaNonTextUpdate nonTextUpdate)
      onNonTextUpdate;

  TextRange? composingTextRange;
  void updateCaretPosition(Size size, Matrix4 transform, Rect rect);

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

class DeltaTextInputService extends TextInputService
    implements DeltaTextInputClient {
  DeltaTextInputService({
    required super.onInsert,
    required super.onDelete,
    required super.onReplace,
    required super.onNonTextUpdate,
  });

  TextInputConnection? textInputConnection;
  @override
  TextRange? composingTextRange;

  @override
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue => throw UnimplementedError();

  @override
  void apply(List<TextEditingDelta> deltas) {
    for (final delta in deltas) {
      _updateComposing(delta);

      if (delta is TextEditingDeltaInsertion) {
        onInsert(delta);
      } else if (delta is TextEditingDeltaDeletion) {
        onDelete(delta);
      } else if (delta is TextEditingDeltaReplacement) {
        onReplace(delta);
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        onNonTextUpdate(delta);
      }
    }
  }

  @override
  void attach(TextEditingValue textEditingValue) {
    if (textInputConnection == null || textInputConnection!.attached == false) {
      textInputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          enableDeltaModel: true,
          inputType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
        ),
      );
    }

    textInputConnection!
      ..setEditingState(textEditingValue)
      ..show();
  }

  @override
  void close() {
    textInputConnection?.close();
    textInputConnection = null;
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    Log.input.debug(
      textEditingDeltas.map((delta) => delta.toString()).toString(),
    );
    apply(textEditingDeltas);
  }

  // TODO: support IME in linux / windows / ios / android
  // Only support macOS now.
  @override
  void updateCaretPosition(Size size, Matrix4 transform, Rect rect) {
    textInputConnection
      ?..setEditableSizeAndTransform(size, transform)
      ..setCaretRect(rect);
  }

  @override
  void connectionClosed() {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void performAction(TextInputAction action) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void showToolbar() {}

  @override
  void updateEditingValue(TextEditingValue value) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  void _updateComposing(TextEditingDelta delta) {
    if (delta is! TextEditingDeltaNonTextUpdate) {
      if (composingTextRange != null &&
          composingTextRange!.start != -1 &&
          delta.composing.end != -1) {
        composingTextRange = TextRange(
          start: composingTextRange!.start,
          end: delta.composing.end,
        );
      } else {
        composingTextRange = delta.composing;
      }
    }
  }
}
