import 'package:flutter/material.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

/// A handler for transactions that involve a Block Component.
///
abstract class BlockTransactionHandler {
  const BlockTransactionHandler({required this.blockType});

  /// The type of the block that this handler is built for.
  /// It's used to determine whether to call any of the handlers on certain transactions.
  ///
  final String blockType;

  void onCut();

  void onCopy();

  void onTransaction(
    BuildContext context,
    EditorState editorState,
    List<Node> added,
    List<Node> removed, {
    bool isUndo = false,
    bool isRedo = false,
    String? parentViewId,
  });

  void onUndo(
    BuildContext context,
    EditorState editorState,
    List<Node> before,
    List<Node> after,
  );

  void onRedo(
    BuildContext context,
    EditorState editorState,
    List<Node> before,
    List<Node> after,
  );

  bool canHandleTransaction(Node node) => node.type == blockType;
}
