import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/transaction_handler/block_transaction_handler.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';

class SubPageTransactionHandler extends BlockTransactionHandler {
  SubPageTransactionHandler() : super(type: SubPageBlockKeys.type);

  final List<String> _beingCreated = [];

  @override
  Future<void> onTransaction(
    BuildContext context,
    EditorState editorState,
    List<Node> added,
    List<Node> removed, {
    bool isCut = false,
    bool isUndoRedo = false,
    bool isPaste = false,
    bool isDraggingNode = false,
    String? parentViewId,
  }) async {
    if (isDraggingNode) {
      return;
    }

    for (final node in removed) {
      if (!context.mounted) return;
      await _subPageDeleted(context, node);
    }

    for (final node in added) {
      if (!context.mounted) return;
      await _subPageAdded(
        context,
        editorState,
        node,
        isCut: isCut,
        isPaste: isPaste,
        parentViewId: parentViewId,
      );
    }
  }

  Future<void> _subPageDeleted(
    BuildContext context,
    Node node,
  ) async {
    if (node.type != type) {
      return;
    }

    final view = node.attributes[SubPageBlockKeys.viewId];
    if (view == null) {
      return;
    }

    final result = await ViewBackendService.deleteView(viewId: view);
    result.fold(
      (_) {},
      (error) {
        Log.error(error);
        if (context.mounted) {
          showSnapBar(
            context,
            LocaleKeys.document_plugins_subPage_errors_failedDeletePage.tr(),
          );
        }
      },
    );
  }

  Future<void> _subPageAdded(
    BuildContext context,
    EditorState editorState,
    Node node, {
    bool isCut = false,
    bool isPaste = false,
    String? parentViewId,
  }) async {
    if (node.type != type || _beingCreated.contains(node.id)) {
      return;
    }

    final viewId = node.attributes[SubPageBlockKeys.viewId];
    if (viewId == null && parentViewId != null) {
      _beingCreated.add(node.id);

      // This is a new Node, we need to create the view
      final viewOrResult = await ViewBackendService.createView(
        layoutType: ViewLayoutPB.Document,
        parentViewId: parentViewId,
        name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
      );

      await viewOrResult.fold(
        (view) async {
          final transaction = editorState.transaction
            ..updateNode(node, {SubPageBlockKeys.viewId: view.id});
          await editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );
          editorState.reload();
        },
        (error) async {
          Log.error(error);
          showSnapBar(
            context,
            LocaleKeys.document_plugins_subPage_errors_failedCreatePage.tr(),
          );

          // Remove the node because it failed
          final transaction = editorState.transaction..deleteNode(node);
          await editorState.apply(
            transaction,
            withUpdateSelection: false,
            options: const ApplyOptions(recordUndo: false),
          );
        },
      );

      _beingCreated.remove(node.id);
    } else if (isPaste) {
      if (isCut && parentViewId != null) {
        await TrashService.putback(viewId);

        final viewOrResult = await ViewBackendService.moveViewV2(
          viewId: viewId,
          newParentId: parentViewId,
          prevViewId: null,
        );

        viewOrResult.fold(
          (_) {},
          (error) {
            Log.error(error);
            showSnapBar(
              context,
              LocaleKeys.document_plugins_subPage_errors_failedMovePage.tr(),
            );
          },
        );
      } else {
        final viewId = node.attributes[SubPageBlockKeys.viewId];
        if (viewId == null) {
          return;
        }

        final viewOrResult = await ViewBackendService.getView(viewId);
        return viewOrResult.fold(
          (view) async {
            final duplicatedViewOrResult = await ViewBackendService.duplicate(
              view: view,
              openAfterDuplicate: false,
              includeChildren: true,
              syncAfterDuplicate: true,
              parentViewId: parentViewId,
            );

            return duplicatedViewOrResult.fold(
              (view) async {
                final transaction = editorState.transaction
                  ..updateNode(node, {
                    SubPageBlockKeys.viewId: view.id,
                    SubPageBlockKeys.wasCut: false,
                    SubPageBlockKeys.wasCopied: false,
                  });
                await editorState.apply(
                  transaction,
                  withUpdateSelection: false,
                  options: const ApplyOptions(recordUndo: false),
                );
                editorState.reload();
              },
              (error) {
                Log.error(error);
                if (context.mounted) {
                  showSnapBar(
                    context,
                    LocaleKeys
                        .document_plugins_subPage_errors_failedDuplicatePage
                        .tr(),
                  );
                }
              },
            );
          },
          (error) async {
            Log.error(error);

            final transaction = editorState.transaction..deleteNode(node);
            await editorState.apply(
              transaction,
              withUpdateSelection: false,
              options: const ApplyOptions(recordUndo: false),
            );
            editorState.reload();
            if (context.mounted) {
              showSnapBar(
                context,
                LocaleKeys
                    .document_plugins_subPage_errors_failedDuplicateFindView
                    .tr(),
              );
            }
          },
        );
      }
    } else {
      // Try to restore from trash, and move to parent view
      await TrashService.putback(viewId);

      // Check if View needs to be moved
      if (parentViewId != null) {
        final view = (await ViewBackendService.getView(viewId)).toNullable();
        if (view == null) {
          return Log.error('View not found: $viewId');
        }

        if (view.parentViewId == parentViewId) {
          return;
        }

        await ViewBackendService.moveViewV2(
          viewId: viewId,
          newParentId: parentViewId,
          prevViewId: null,
        );
      }
    }
  }
}
