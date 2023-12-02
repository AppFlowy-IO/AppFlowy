import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_block_action_widget.dart';
import 'package:appflowy/plugins/base/color/color_picker_screen.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final mobileBlockSettingsToolbarItem = MobileToolbarItem.action(
  itemIconBuilder: (_, editorState, __) {
    return onlyShowInSingleSelectionAndTextType(editorState)
        ? const FlowySvg(FlowySvgs.three_dots_s)
        : null;
  },
  actionHandler: (_, editorState) async {
    // show the settings page
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final context = node?.context;
    if (node == null || context == null) {
      return;
    }

    await _showBlockActionSheet(
      context,
      editorState,
      node,
      selection,
    );
  },
);

Future<void> _showBlockActionSheet(
  BuildContext context,
  EditorState editorState,
  Node node,
  Selection selection,
) async {
  final result = await showMobileBottomSheet<bool>(
    context,
    showDragHandle: true,
    showCloseButton: true,
    showHeader: true,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
    title: LocaleKeys.document_plugins_action.tr(),
    builder: (context) {
      return BlockActionBottomSheet(
        extendActionWidgets: [
          const VSpace(8),
          Row(
            children: [
              Expanded(
                child: BottomSheetActionWidget(
                  svg: FlowySvgs.m_color_m,
                  text: LocaleKeys.document_plugins_optionAction_color.tr(),
                  onTap: () async {
                    final option = await context.push<FlowyColorOption?>(
                      Uri(
                        path: MobileColorPickerScreen.routeName,
                        queryParameters: {
                          MobileColorPickerScreen.pageTitle: LocaleKeys
                              .document_plugins_optionAction_color
                              .tr(),
                        },
                      ).toString(),
                    );
                    if (option != null) {
                      final transaction = editorState.transaction;
                      transaction.updateNode(node, {
                        blockComponentBackgroundColor: option.id,
                      });
                      await editorState.apply(transaction);
                    }
                    if (context.mounted) {
                      context.pop(true);
                    }
                  },
                ),
              ),
              // more options ...
            ],
          ),
        ],
        onAction: (action) async {
          context.pop(true);

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

  if (result != true) {
    // restore the selection
    editorState.selection = selection;
  }
}
