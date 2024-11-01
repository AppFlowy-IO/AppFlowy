import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/smart_edit_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kSmartEditToolbarItemId = 'appflowy.editor.smart_edit';

final ToolbarItem smartEditItem = ToolbarItem(
  id: _kSmartEditToolbarItemId,
  group: 0,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, _, __, tooltipBuilder) => SmartEditActionList(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
  ),
);

class SmartEditActionList extends StatefulWidget {
  const SmartEditActionList({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  State<SmartEditActionList> createState() => _SmartEditActionListState();
}

class _SmartEditActionListState extends State<SmartEditActionList> {
  bool isAIEnabled = true;

  @override
  void initState() {
    super.initState();
    isAIEnabled = _isAIEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<SmartEditActionWrapper>(
      offset: const Offset(-5, 5),
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: SmartEditAction.values
          .map((action) => SmartEditActionWrapper(action))
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
            _kSmartEditToolbarItemId,
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

    // support multiple paragraphs
    final input = _getTextInSelection(selection);

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

  List<String> _getTextInSelection(
    Selection selection,
  ) {
    final res = <String>[];
    if (selection.isCollapsed) {
      return res;
    }
    final nodes = widget.editorState.getNodesInSelection(selection);
    for (final node in nodes) {
      final delta = node.delta;
      if (delta == null) {
        continue;
      }
      final startIndex = node == nodes.first ? selection.startIndex : 0;
      final endIndex = node == nodes.last ? selection.endIndex : delta.length;
      res.add(delta.slice(startIndex, endIndex).toPlainText());
    }
    return res;
  }

  bool _isAIEnabled() {
    final documentContext = widget.editorState.document.root.context;
    if (documentContext == null) {
      return true;
    }
    return !documentContext.read<DocumentBloc>().isLocalMode;
  }
}
