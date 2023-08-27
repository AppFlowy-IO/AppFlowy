import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_option_action.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'dart:math' as math;

const tableActions = <TableOptionAction>[
  TableOptionAction.addAfter,
  TableOptionAction.addBefore,
  TableOptionAction.delete,
  TableOptionAction.duplicate,
  TableOptionAction.clear,
];

class TableMenu extends StatelessWidget {
  const TableMenu({
    super.key,
    required this.node,
    required this.editorState,
    required this.position,
    required this.dir,
    this.onBuild,
    this.onClose,
  });

  final Node node;
  final EditorState editorState;
  final int position;
  final TableDirection dir;
  final VoidCallback? onBuild;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<PopoverAction>(
      direction: dir == TableDirection.col
          ? PopoverDirection.bottomWithCenterAligned
          : PopoverDirection.rightWithTopAligned,
      actions: tableActions
          .map((action) => TableOptionActionWrapper(action))
          .toList(),
      onPopupBuilder: onBuild,
      onClosed: onClose,
      onSelected: (action, controller) {
        if (action is TableOptionActionWrapper) {
          _onSelectAction(action.inner);
          controller.close();
        }
      },
      buildChild: (controller) => _buildOptionButton(controller, context),
    );
  }

  Widget _buildOptionButton(
    PopoverController controller,
    BuildContext context,
  ) {
    return Card(
      elevation: 1.0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => controller.show(),
          child: Transform.rotate(
            angle: dir == TableDirection.col ? math.pi / 2 : 0,
            child: const FlowySvg(
              FlowySvgs.drag_element_s,
              size: Size.square(18.0),
            ),
          ),
        ),
      ),
    );
  }

  void _onSelectAction(TableOptionAction action) {
    final transaction = editorState.transaction;
    switch (action) {
      case TableOptionAction.addAfter:
        TableActions.add(node, position + 1, transaction, dir);
        break;
      case TableOptionAction.addBefore:
        TableActions.add(node, position, transaction, dir);
        break;
      case TableOptionAction.delete:
        TableActions.delete(node, position, transaction, dir);
        break;
      case TableOptionAction.clear:
        TableActions.clear(node, position, transaction, dir);
        break;
      case TableOptionAction.duplicate:
        TableActions.duplicate(node, position, transaction, dir);
        break;
      default:
    }
    editorState.apply(transaction);
  }
}
