import 'package:flutter/material.dart';

import 'package:appflowy_editor/appflowy_editor.dart';

/// A handler for transactions that involve a Block Component.
/// The [T] type is the type of data that this transaction handler takes.
///
/// In case of a block component, the [T] type should be a [Node].
/// In case of a mention component, the [T] type should be a [Map].
///
abstract class EditorTransactionHandler<T> {
  const EditorTransactionHandler({
    required this.type,
    this.livesInDelta = false,
  });

  /// The type of the block/mention that this handler is built for.
  /// It's used to determine whether to call any of the handlers on certain transactions.
  ///
  final String type;

  /// If the block is a "mention" type, it lives inside the [Delta] of a [Node].
  ///
  final bool livesInDelta;

  Future<void> onTransaction(
    BuildContext context,
    EditorState editorState,
    List<T> added,
    List<T> removed, {
    bool isCut = false,
    bool isUndoRedo = false,
    bool isPaste = false,
    bool isDraggingNode = false,
    String? parentViewId,
  });
}
