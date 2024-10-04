import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/block_transaction_handler/block_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/block_transaction_handler.dart';

final _transactionHandlers = [SubPageBlockTransactionHandler()];

/// Shared context for the editor plugins.
///
/// For example, the backspace command requires the focus node of the cover title.
/// so we need to use the shared context to get the focus node.
class SharedEditorContext {
  SharedEditorContext();

  static List<BlockTransactionHandler> get transactionHandlers =>
      _transactionHandlers;

  // The focus node of the cover title.
  // It's null when the cover title is not focused.
  FocusNode? coverTitleFocusNode;
}
