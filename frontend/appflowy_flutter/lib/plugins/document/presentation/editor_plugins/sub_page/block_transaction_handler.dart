import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_transaction_handler/block_transaction_handler.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';

class SubPageBlockTransactionHandler extends BlockTransactionHandler {
  SubPageBlockTransactionHandler() : super(blockType: SubPageBlockKeys.type);

  final List<String> _beingCreated = [];

  @override
  void onCopy() {
    debugPrint('SubPageBlockTransactionHandler.onCopy');
  }

  @override
  void onCut() {
    debugPrint('SubPageBlockTransactionHandler.onCut');
  }

  @override
  void onRedo(
    BuildContext context,
    EditorState editorState,
    List<Node> before,
    List<Node> after,
  ) {
    debugPrint('SubPageBlockTransactionHandler.onRedo');
    _handleUndoRedo(context, editorState, before, after);
  }

  @override
  void onUndo(
    BuildContext context,
    EditorState editorState,
    List<Node> before,
    List<Node> after,
  ) {
    debugPrint('SubPageBlockTransactionHandler.onUndo');
    _handleUndoRedo(context, editorState, before, after);
  }

  void _handleUndoRedo(
    BuildContext context,
    EditorState editorState,
    List<Node> before,
    List<Node> after,
  ) {
    final additions = after.where((e) => !before.contains(e)).toList();
    final removals = before.where((e) => !after.contains(e)).toList();

    // Removals goes to trash
    for (final node in removals) {
      _subPageDeleted(context, editorState, node);
    }

    // Additions are moved to this view
    for (final node in additions) {
      _subPageAdded(context, editorState, node);
    }
  }

  @override
  void onTransaction(
    BuildContext context,
    EditorState editorState,
    List<Node> added,
    List<Node> removed, {
    bool isUndo = false,
    bool isRedo = false,
    String? parentViewId,
  }) {
    debugPrint('SubPageBlockTransactionHandler.onTransaction');

    for (final node in removed) {
      _subPageDeleted(context, editorState, node);
    }

    for (final node in added) {
      _subPageAdded(context, editorState, node, parentViewId);
    }
  }

  Future<void> _subPageDeleted(
    BuildContext context,
    EditorState editorState,
    Node node,
  ) async {
    if (node.type != blockType) {
      return;
    }

    debugPrint('SubPageBlockTransactionHandler._subPageDeleted');

    final view = node.attributes[SubPageBlockKeys.viewId];
    if (view == null) {
      return;
    }

    // We move the view to Trash
    final result = await ViewBackendService.deleteView(viewId: view);
    result.fold(
      (_) {},
      (error) {
        Log.error(error);
        if (context.mounted) {
          showSnapBar(context, 'Failed to move page to trash');
        }
      },
    );
  }

  Future<void> _subPageAdded(
    BuildContext context,
    EditorState editorState,
    Node node, [
    String? parentViewId,
  ]) async {
    if (node.type != blockType || _beingCreated.contains(node.id)) {
      return;
    }

    debugPrint('SubPageBlockTransactionHandler._subPageAdded');

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
        (error) {
          Log.error(error);
          showSnapBar(context, 'Failed to create sub page');
        },
      );

      _beingCreated.remove(node.id);
    } else {
      final newAttributes = node.attributes;
      newAttributes[SubPageBlockKeys.wasCut] = true;

      // We update the wasCut attribute to true to signify the view was moved.
      // In this particular case it shares behavior with cut, as it moves the view from Trash
      // to the current view (if applicable).
      final transaction = editorState.transaction
        ..deleteNode(node)
        ..insertNode(node.path.next, node.copyWith(attributes: newAttributes));
      await editorState.apply(
        transaction,
        withUpdateSelection: false,
        options: const ApplyOptions(recordUndo: false),
      );
    }
  }
}
