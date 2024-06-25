import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

final ToolbarItem smartEditItem = ToolbarItem(
  id: 'appflowy.editor.smart_edit',
  group: 0,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, _, __) => SmartEditActionList(
    editorState: editorState,
  ),
);

class SmartEditActionList extends StatefulWidget {
  const SmartEditActionList({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  State<SmartEditActionList> createState() => _SmartEditActionListState();
}

class _SmartEditActionListState extends State<SmartEditActionList> {
  bool isAIEnabled = false;

  @override
  void initState() {
    super.initState();

    UserBackendService.getCurrentUserProfile().then((value) {
      setState(() {
        isAIEnabled = value.fold(
          (userProfile) =>
              userProfile.authenticator == AuthenticatorPB.AppFlowyCloud,
          (_) => false,
        );
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
      onClosed: () => keepEditorFocusNotifier.decrease(),
      buildChild: (controller) {
        keepEditorFocusNotifier.increase();
        return FlowyIconButton(
          hoverColor: Colors.transparent,
          tooltipText: isAIEnabled
              ? LocaleKeys.document_plugins_smartEdit.tr()
              : LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
          preferBelow: false,
          icon: const Icon(
            Icons.lightbulb_outline,
            size: 15,
            color: Colors.white,
          ),
          onPressed: () {
            if (isAIEnabled) {
              controller.show();
            } else {
              showSnackBarMessage(
                context,
                LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
                showCancel: true,
              );
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
    final selection = widget.editorState.selection?.normalized;
    if (selection == null) {
      return;
    }
    final input = widget.editorState.getTextInSelection(selection);
    while (input.last.isEmpty) {
      input.removeLast();
    }
    final transaction = widget.editorState.transaction;
    transaction.insertNode(
      selection.normalized.end.path.next,
      smartEditNode(
        action: actionWrapper.inner,
        content: input.join('\n\n'),
      ),
    );
    await widget.editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordUndo: false,
      ),
      withUpdateSelection: false,
    );
  }
}
