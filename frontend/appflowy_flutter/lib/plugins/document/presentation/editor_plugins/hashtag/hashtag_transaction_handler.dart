import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'hashtag_block_keys.dart';

class HashtagTransactionHandler extends EditorTransactionHandler<Map<String, dynamic>> {
  HashtagTransactionHandler()
      : super(
          type: HashtagBlockKeys.hashtag,
          livesInDelta: true,
        );

  @override
  Future<void> onTransaction(
    BuildContext context,
    String viewId,
    EditorState editorState,
    List<Map<String, dynamic>> added,
    List<Map<String, dynamic>> removed, {
    bool isCut = false,
    bool isUndoRedo = false,
    bool isPaste = false,
    bool isDraggingNode = false,
    bool isTurnInto = false,
    String? parentViewId,
  }) async {
    // Versão inicial:
    // não faz sync com backend nem efeitos laterais.
    // Serve apenas para o editor reconhecer oficialmente este tipo
    // e para termos um ponto de extensão preparado.
    return;
  }
}