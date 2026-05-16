import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// A handler for transactions that involve a Block Component.
///
/// This is a subclass of [EditorTransactionHandler] that is used for block components.
/// Specifically this transaction handler only needs to concern itself with changes to
/// a [Node], and doesn't care about text deltas.
///
abstract class BlockTransactionHandler extends EditorTransactionHandler<Node> {
  const BlockTransactionHandler({required super.type})
      : super(livesInDelta: false);
}
