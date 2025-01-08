import 'package:appflowy/ai/service/appflowy_ai_service.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/ai/util/ask_ai_node_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/ask_ai_action.dart';
import 'ask_ai_block_component.dart';

const _kAskAIToolbarItemId = 'appflowy.editor.ask_ai';

final ToolbarItem askAIItem = ToolbarItem(
  id: _kAskAIToolbarItemId,
  group: 0,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, _, __, tooltipBuilder) => AskAIActionList(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
  ),
);

class AskAIActionList extends StatefulWidget {
  const AskAIActionList({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  State<AskAIActionList> createState() => _AskAIActionListState();
}

class _AskAIActionListState extends State<AskAIActionList> {
  late bool isAIEnabled;

  EditorState get editorState => widget.editorState;

  @override
  void initState() {
    super.initState();
    _updateIsAIEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<AskAIActionWrapper>(
      offset: const Offset(-5, 5),
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: AskAIAction.values
          .map((action) => AskAIActionWrapper(action))
          .toList(),
      onClosed: () => keepEditorFocusNotifier.decrease(),
      buildChild: (controller) {
        keepEditorFocusNotifier.increase();
        final child = FlowyButton(
          text: FlowyText.regular(
            LocaleKeys.document_plugins_smartEdit.tr(),
            fontSize: 13.0,
            figmaLineHeight: 16.0,
            color: Colors.white,
          ),
          hoverColor: Colors.transparent,
          useIntrinsicWidth: true,
          leftIcon: const FlowySvg(
            FlowySvgs.toolbar_item_ai_s,
            size: Size.square(16.0),
            color: Colors.white,
          ),
          onTap: () {
            if (isAIEnabled) {
              keepEditorFocusNotifier.increase();
              controller.show();
            } else {
              showToastNotification(
                context,
                message:
                    LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
              );
            }
          },
        );

        if (widget.tooltipBuilder != null) {
          return widget.tooltipBuilder!(
            context,
            _kAskAIToolbarItemId,
            isAIEnabled
                ? LocaleKeys.document_plugins_smartEdit.tr()
                : LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
            child,
          );
        }

        return child;
      },
      onSelected: (action, controller) {
        controller.close();
        _insertAskAINode(action);
      },
    );
  }

  Future<void> _insertAskAINode(
    AskAIActionWrapper actionWrapper,
  ) async {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return;
    }

    final markdown = editorState.getMarkdownInSelection(selection);

    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.normalized.end.path.next,
      askAINode(
        action: actionWrapper.inner,
        content: markdown,
      ),
    );
    await editorState.apply(
      transaction,
      options: const ApplyOptions(
        recordUndo: false,
        inMemoryUpdate: true,
      ),
      withUpdateSelection: false,
    );
  }

  void _updateIsAIEnabled() {
    final documentContext = widget.editorState.document.root.context;
    isAIEnabled = documentContext == null ||
        !documentContext.read<DocumentBloc>().isLocalMode;
  }
}
