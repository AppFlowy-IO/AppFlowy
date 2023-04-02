import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';

mixin TextBlockWithInput {
  EditorState get editorState;

  Future<void> onInsert(TextEditingDeltaInsertion insertion) async {
    Log.input.debug('[Insert]: $insertion');
  }

  Future<void> onDelete(TextEditingDeltaDeletion deletion) async {
    Log.input.debug('[Delete]: $deletion');

    // This function never be called, WHY?
  }

  Future<void> onReplace(TextEditingDeltaReplacement replacement) async {
    Log.input.debug('[Replace]: $replacement');
  }

  Future<void> onNonTextUpdate(
    TextEditingDeltaNonTextUpdate nonTextUpdate,
  ) async {
    Log.input.debug('[NonTextUpdate]: $nonTextUpdate');
  }
}
