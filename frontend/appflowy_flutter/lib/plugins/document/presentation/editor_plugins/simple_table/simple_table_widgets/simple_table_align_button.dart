import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableAlignMenu extends StatefulWidget {
  const SimpleTableAlignMenu({
    super.key,
    required this.type,
    required this.tableCellNode,
    this.mutex,
  });

  final SimpleTableMoreActionType type;
  final Node tableCellNode;
  final PopoverMutex? mutex;

  @override
  State<SimpleTableAlignMenu> createState() => _SimpleTableAlignMenuState();
}

class _SimpleTableAlignMenuState extends State<SimpleTableAlignMenu> {
  @override
  Widget build(BuildContext context) {
    final align = switch (widget.type) {
      SimpleTableMoreActionType.column => widget.tableCellNode.columnAlign,
      SimpleTableMoreActionType.row => widget.tableCellNode.rowAlign,
    };
    return AppFlowyPopover(
      mutex: widget.mutex,
      child: SimpleTableBasicButton(
        leftIconSvg: align.leftIconSvg,
        text: LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
        onTap: () {},
      ),
      popupBuilder: (popoverContext) {
        void onClose() => PopoverContainer.of(popoverContext).closeAll();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAlignButton(context, TableAlign.left, onClose),
            _buildAlignButton(context, TableAlign.center, onClose),
            _buildAlignButton(context, TableAlign.right, onClose),
          ],
        );
      },
    );
  }

  Widget _buildAlignButton(
    BuildContext context,
    TableAlign align,
    VoidCallback onClose,
  ) {
    return SimpleTableBasicButton(
      leftIconSvg: align.leftIconSvg,
      text: align.name,
      onTap: () {
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            context.read<EditorState>().updateColumnAlign(
                  tableCellNode: widget.tableCellNode,
                  align: align,
                );
            break;
          case SimpleTableMoreActionType.row:
            context.read<EditorState>().updateRowAlign(
                  tableCellNode: widget.tableCellNode,
                  align: align,
                );
            break;
        }

        onClose();
      },
    );
  }
}
