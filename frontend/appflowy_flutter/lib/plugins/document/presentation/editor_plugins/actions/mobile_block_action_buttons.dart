import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_block_action_widget.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The ... button on the top right corner of a block.
///
/// Only works on mobile.
class MobileBlockActionButtons extends StatelessWidget {
  const MobileBlockActionButtons({
    super.key,
    required this.child,
    required this.editorState,
    required this.node,
  });

  final Widget child;
  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    if (!PlatformExtension.isMobile) {
      return child;
    }

    const padding = 5.0;
    return Stack(
      children: [
        child,
        Positioned(
          top: padding,
          right: padding,
          child: FlowyIconButton(
            icon: const FlowySvg(
              FlowySvgs.three_dots_s,
            ),
            width: 20.0,
            onPressed: () => _showBottomSheet(context),
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context) {
    showFlowyMobileBottomSheet(
      context,
      title: 'Actions',
      builder: (context) {
        return BlockActionBottomSheet(
          onAction: (action) async {
            context.pop();

            final transaction = editorState.transaction;
            switch (action) {
              case BlockActionBottomSheetType.delete:
                transaction.deleteNode(node);
                break;
              case BlockActionBottomSheetType.duplicate:
                transaction.insertNode(
                  node.path.next,
                  node.copyWith(),
                );
                break;
              case BlockActionBottomSheetType.insertAbove:
                final path = node.path;
                transaction.insertNode(
                  path,
                  paragraphNode(),
                );
                transaction.afterSelection = Selection.collapsed(
                  Position(
                    path: path,
                  ),
                );
                break;
              case BlockActionBottomSheetType.insertBelow:
                final path = node.path.next;
                transaction.insertNode(
                  path,
                  paragraphNode(),
                );
                transaction.afterSelection = Selection.collapsed(
                  Position(
                    path: path,
                  ),
                );
                break;
              default:
            }

            if (transaction.operations.isNotEmpty) {
              await editorState.apply(transaction);
            }
          },
        );
      },
    );
  }
}
