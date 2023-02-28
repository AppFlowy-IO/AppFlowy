import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_node_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

ToolbarItem smartEditItem = ToolbarItem(
  id: 'appflowy.toolbar.smart_edit',
  type: 0, // headmost
  validator: (editorState) {
    // All selected nodes must be text.
    final nodes = editorState.service.selectionService.currentSelectedNodes;
    return nodes.whereType<TextNode>().length == nodes.length;
  },
  itemBuilder: (context, editorState) {
    return _SmartEditWidget(
      editorState: editorState,
    );
  },
);

class _SmartEditWidget extends StatefulWidget {
  const _SmartEditWidget({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  State<_SmartEditWidget> createState() => _SmartEditWidgetState();
}

class _SmartEditWidgetState extends State<_SmartEditWidget> {
  @override
  Widget build(BuildContext context) {
    return PopoverActionList<SmartEditActionWrapper>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: SmartEditAction.values
          .map((action) => SmartEditActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return FlowyIconButton(
          tooltipText: 'Smart Edit',
          preferBelow: false,
          icon: const Icon(
            Icons.edit,
            size: 14,
          ),
          onPressed: () {
            controller.show();
          },
        );
      },
      onSelected: (action, controller) {
        controller.close();
        final selection =
            widget.editorState.service.selectionService.currentSelection.value;
        if (selection == null) {
          return;
        }
        final textNodes = widget
            .editorState.service.selectionService.currentSelectedNodes
            .whereType<TextNode>()
            .toList(growable: false);
        final input = widget.editorState.getTextInSelection(
          textNodes.normalized,
          selection.normalized,
        );
        final transaction = widget.editorState.transaction;
        transaction.insertNode(
          selection.normalized.end.path.next,
          Node(
            type: kSmartEditType,
            attributes: {
              kSmartEditInstructionType: action.inner.toInstruction,
              kSmartEditInputType: input,
            },
          ),
        );
        widget.editorState.apply(
          transaction,
          options: const ApplyOptions(
            recordUndo: false,
            recordRedo: false,
          ),
          withUpdateCursor: false,
        );
      },
    );
  }
}
