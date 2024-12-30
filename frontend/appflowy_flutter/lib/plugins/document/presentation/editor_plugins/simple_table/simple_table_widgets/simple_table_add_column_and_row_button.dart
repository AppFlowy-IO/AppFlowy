import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableAddColumnAndRowHoverButton extends StatelessWidget {
  const SimpleTableAddColumnAndRowHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().isHoveringOnTableArea,
      builder: (context, isHoveringOnTableArea, child) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringTableCell, child) {
            bool shouldShow = isHoveringOnTableArea;
            if (hoveringTableCell != null &&
                SimpleTableConstants.enableHoveringLogicV2) {
              shouldShow = hoveringTableCell.isLastCellInTable;
            }
            return shouldShow
                ? Positioned(
                    bottom:
                        SimpleTableConstants.addColumnAndRowButtonBottomPadding,
                    right: SimpleTableConstants.addColumnButtonPadding,
                    child: SimpleTableAddColumnAndRowButton(
                      onTap: () {
                        // cancel the selection to avoid flashing the selection
                        editorState.selection = null;

                        editorState.addColumnAndRowInTable(node);
                      },
                    ),
                  )
                : const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class SimpleTableAddColumnAndRowButton extends StatelessWidget {
  const SimpleTableAddColumnAndRowButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewRowAndColumn
          .tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: SimpleTableConstants.addColumnAndRowButtonWidth,
            height: SimpleTableConstants.addColumnAndRowButtonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addColumnAndRowButtonCornerRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}
