import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_block_action_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The ... button shows on the top right corner of a block.
///
/// Default actions are:
/// - delete
/// - duplicate
/// - insert above
/// - insert below
///
/// Only works on mobile.
class MobileBlockActionButtons extends StatelessWidget {
  const MobileBlockActionButtons({
    super.key,
    this.extendActionWidgets = const [],
    this.showThreeDots = true,
    required this.node,
    required this.editorState,
    required this.child,
  });

  final Node node;
  final EditorState editorState;
  final List<Widget> extendActionWidgets;
  final Widget child;
  final bool showThreeDots;

  @override
  Widget build(BuildContext context) {
    if (!PlatformExtension.isMobile) {
      return child;
    }

    if (!showThreeDots) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showBottomSheet(context),
        child: child,
      );
    }

    const padding = 10.0;
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
    showMobileBottomSheet(
      context,
      showHeader: true,
      showCloseButton: true,
      title: LocaleKeys.document_plugins_action.tr(),
      builder: (context) {
        return BlockActionBottomSheet(
          extendActionWidgets: extendActionWidgets,
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
              case BlockActionBottomSheetType.insertBelow:
                final path = action == BlockActionBottomSheetType.insertAbove
                    ? node.path
                    : node.path.next;
                transaction
                  ..insertNode(
                    path,
                    paragraphNode(),
                  )
                  ..afterSelection = Selection.collapsed(
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
