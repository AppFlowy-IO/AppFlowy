import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/child_page_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/editor_transaction_handler.dart';

final _transactionHandlers = <EditorTransactionHandler>[
  SubPageTransactionHandler(),
  ChildPageTransactionHandler(),
];

/// Shared context for the editor plugins.
///
/// For example, the backspace command requires the focus node of the cover title.
/// so we need to use the shared context to get the focus node.
///
class SharedEditorContext {
  SharedEditorContext();

  static List<EditorTransactionHandler> get transactionHandlers =>
      _transactionHandlers;

  // The focus node of the cover title.
  // It's null when the cover title is not focused.
  FocusNode? coverTitleFocusNode;
}
