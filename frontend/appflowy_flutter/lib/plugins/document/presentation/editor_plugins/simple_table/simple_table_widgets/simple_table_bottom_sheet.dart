import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/_simple_table_bottom_sheet_actions.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Note: This widget is only used for mobile.
class SimpleTableBottomSheet extends StatelessWidget {
  const SimpleTableBottomSheet({
    super.key,
    required this.type,
    required this.node,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node node;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // copy, cut, paste, delete
        SimpleTableQuickActions(
          type: type,
          node: node,
          editorState: editorState,
        ),
        const VSpace(12),
        // insert row, insert column
        SimpleTableInsertActions(
          type: type,
          tableCellNode: node,
          editorState: editorState,
        ),
        const VSpace(16),
        // action buttons
        SimpleTableActionButtons(
          type: type,
          tableCellNode: node,
          editorState: editorState,
        ),
      ],
    );
  }
}
