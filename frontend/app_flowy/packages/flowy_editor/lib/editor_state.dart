import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/document/attributes.dart';
import 'package:flutter/material.dart';

import './document/state_tree.dart';
import './document/selection.dart';
import './operation/operation.dart';
import './operation/transaction.dart';
import './render/render_plugins.dart';

class EditorState {
  final StateTree document;
  final RenderPlugins renderPlugins;
  Selection? cursorSelection;

  EditorState({
    required this.document,
    required this.renderPlugins,
  });

  /// TODO: move to a better place.
  Widget build(BuildContext context) {
    return renderPlugins.buildWidget(
      context: NodeWidgetContext(
        buildContext: context,
        node: document.root,
        editorState: this,
      ),
    );
  }

  void apply(Transaction transaction) {
    for (final op in transaction.operations) {
      _applyOperation(op);
    }
    cursorSelection = transaction.afterSelection;
  }

  void _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.value);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path);
    } else if (op is TextEditOperation) {
      document.textEdit(op.path, op.delta);
    }
  }
}
