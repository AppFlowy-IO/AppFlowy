import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_node_widget.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

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
  bool isOpenAIEnabled = false;

  @override
  void initState() {
    super.initState();

    UserBackendService.getCurrentUserProfile().then((value) {
      setState(() {
        isOpenAIEnabled =
            value.fold((l) => l.openaiKey.isNotEmpty, (r) => false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<SmartEditActionWrapper>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: SmartEditAction.values
          .map((action) => SmartEditActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return FlowyIconButton(
          hoverColor: Colors.transparent,
          tooltipText: isOpenAIEnabled
              ? LocaleKeys.document_plugins_smartEdit.tr()
              : LocaleKeys.document_plugins_smartEditDisabled.tr(),
          preferBelow: false,
          icon: const Icon(
            Icons.lightbulb_outline,
            size: 13,
            color: Colors.white,
          ),
          onPressed: () {
            if (isOpenAIEnabled) {
              controller.show();
            } else {
              _showError(LocaleKeys.document_plugins_smartEditDisabled.tr());
            }
          },
        );
      },
      onSelected: (action, controller) {
        controller.close();
        _insertSmartEditNode(action);
      },
    );
  }

  Future<void> _insertSmartEditNode(
    SmartEditActionWrapper actionWrapper,
  ) async {
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
    while (input.last.isEmpty) {
      input.removeLast();
    }
    final transaction = widget.editorState.transaction;
    transaction.insertNode(
      selection.normalized.end.path.next,
      Node(
        type: kSmartEditType,
        attributes: {
          kSmartEditInstructionType: actionWrapper.inner.index,
          kSmartEditInputType: input.join('\n\n'),
        },
      ),
    );
    return widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordUndo: false,
        recordRedo: false,
      ),
      withUpdateCursor: false,
    );
  }

  Future<void> _showError(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          label: LocaleKeys.button_Cancel.tr(),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        content: FlowyText(message),
      ),
    );
  }
}
