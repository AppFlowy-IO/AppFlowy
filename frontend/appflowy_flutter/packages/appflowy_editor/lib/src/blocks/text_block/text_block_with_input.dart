import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';

mixin TextBlockWithInput {
  EditorState get editorState;
  TextNode get textNode;

  Future<void> _onInsert(TextEditingDeltaInsertion insertion) async {
    Log.input.debug('[Insert]: $insertion');

    final tr = editorState.transaction
      ..insertText(
        textNode,
        insertion.insertionOffset,
        insertion.textInserted,
      );
    return editorState.apply(tr);
  }

  Future<void> _onDelete(TextEditingDeltaDeletion deletion) async {
    Log.input.debug('[Delete]: $deletion');

    // This function never be called, WHY?
  }

  Future<void> _onReplace(TextEditingDeltaReplacement replacement) async {
    Log.input.debug('[Replace]: $replacement');

    final tr = editorState.transaction
      ..replaceText(
        textNode,
        replacement.replacedRange.start,
        replacement.replacedRange.end - replacement.replacedRange.start,
        replacement.replacementText,
      );
    return editorState.apply(tr);
  }

  Future<void> _onNonTextUpdate(
    TextEditingDeltaNonTextUpdate nonTextUpdate,
  ) async {
    Log.input.debug('[NonTextUpdate]: $nonTextUpdate');
  }
}
