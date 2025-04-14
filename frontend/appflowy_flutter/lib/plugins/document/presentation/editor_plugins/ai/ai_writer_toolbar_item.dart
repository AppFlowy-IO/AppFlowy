import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'operations/ai_writer_entities.dart';

const _improveWritingToolbarItemId = 'appflowy.editor.ai_improve_writing';
const _aiWriterToolbarItemId = 'appflowy.editor.ai_writer';

final ToolbarItem improveWritingItem = ToolbarItem(
  id: _improveWritingToolbarItemId,
  group: 0,
  isActive: onlyShowInTextTypeAndExcludeTable,
  builder: (context, editorState, _, __, tooltipBuilder) =>
      ImproveWritingButton(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
  ),
);

final ToolbarItem aiWriterItem = ToolbarItem(
  id: _aiWriterToolbarItemId,
  group: 0,
  isActive: onlyShowInTextTypeAndExcludeTable,
  builder: (context, editorState, _, __, tooltipBuilder) =>
      AiWriterToolbarActionList(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
  ),
);

class AiWriterToolbarActionList extends StatefulWidget {
  const AiWriterToolbarActionList({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  State<AiWriterToolbarActionList> createState() =>
      _AiWriterToolbarActionListState();
}

class _AiWriterToolbarActionListState extends State<AiWriterToolbarActionList> {
  final popoverController = PopoverController();
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 2.0),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        setState(() {
          isSelected = false;
        });
        keepEditorFocusNotifier.decrease();
      },
      popupBuilder: (context) => buildPopoverContent(),
      child: buildChild(context),
    );
  }

  Widget buildPopoverContent() {
    return SeparatedColumn(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => const VSpace(4.0),
      children: [
        actionWrapper(AiWriterCommand.improveWriting),
        actionWrapper(AiWriterCommand.userQuestion),
        actionWrapper(AiWriterCommand.fixSpellingAndGrammar),
        // actionWrapper(AiWriterCommand.summarize),
        actionWrapper(AiWriterCommand.explain),
        divider(),
        actionWrapper(AiWriterCommand.makeLonger),
        actionWrapper(AiWriterCommand.makeShorter),
      ],
    );
  }

  Widget actionWrapper(AiWriterCommand command) {
    return SizedBox(
      height: 36,
      child: FlowyButton(
        leftIconSize: const Size.square(20),
        leftIcon: FlowySvg(command.icon),
        iconPadding: 12,
        text: FlowyText(
          command.i18n,
          figmaLineHeight: 20,
        ),
        onTap: () {
          popoverController.close();
          _insertAiNode(widget.editorState, command);
        },
      ),
    );
  }

  Widget divider() {
    return const Divider(
      thickness: 1.0,
      height: 1.0,
    );
  }

  Widget buildChild(BuildContext context) {
    final theme = AppFlowyTheme.of(context), iconScheme = theme.iconColorTheme;
    final child = FlowyIconButton(
      width: 48,
      height: 32,
      isSelected: isSelected,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.toolbar_ai_writer_m,
            size: Size.square(20),
            color: iconScheme.primary,
          ),
          HSpace(4),
          FlowySvg(
            FlowySvgs.toolbar_arrow_down_m,
            size: Size(12, 20),
            color: iconScheme.primary,
          ),
        ],
      ),
      onPressed: () {
        if (_isAIEnabled(widget.editorState)) {
          keepEditorFocusNotifier.increase();
          popoverController.show();
          setState(() {
            isSelected = true;
          });
        } else {
          showToastNotification(
            message: LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
          );
        }
      },
    );

    return widget.tooltipBuilder?.call(
          context,
          _aiWriterToolbarItemId,
          _isAIEnabled(widget.editorState)
              ? LocaleKeys.document_plugins_aiWriter_userQuestion.tr()
              : LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
          child,
        ) ??
        child;
  }
}

class ImproveWritingButton extends StatelessWidget {
  const ImproveWritingButton({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: FlowySvg(
        FlowySvgs.toolbar_ai_improve_writing_m,
        size: Size.square(20.0),
        color: theme.iconColorTheme.primary,
      ),
      onPressed: () {
        if (_isAIEnabled(editorState)) {
          keepEditorFocusNotifier.increase();
          _insertAiNode(editorState, AiWriterCommand.improveWriting);
        } else {
          showToastNotification(
            message: LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
          );
        }
      },
    );

    return tooltipBuilder?.call(
          context,
          _aiWriterToolbarItemId,
          _isAIEnabled(editorState)
              ? LocaleKeys.document_plugins_aiWriter_improveWriting.tr()
              : LocaleKeys.document_plugins_appflowyAIEditDisabled.tr(),
          child,
        ) ??
        child;
  }
}

void _insertAiNode(EditorState editorState, AiWriterCommand command) async {
  final selection = editorState.selection?.normalized;
  if (selection == null) {
    return;
  }

  final transaction = editorState.transaction
    ..insertNode(
      selection.end.path.next,
      aiWriterNode(
        selection: selection,
        command: command,
      ),
    )
    ..selectionExtraInfo = {selectionExtraInfoDisableToolbar: true};

  await editorState.apply(
    transaction,
    options: const ApplyOptions(
      recordUndo: false,
      inMemoryUpdate: true,
    ),
    withUpdateSelection: false,
  );
}

bool _isAIEnabled(EditorState editorState) {
  final documentContext = editorState.document.root.context;
  return documentContext == null ||
      !documentContext.read<DocumentBloc>().isLocalMode;
}

bool onlyShowInTextTypeAndExcludeTable(
  EditorState editorState,
) {
  return onlyShowInTextType(editorState) && notShowInTable(editorState);
}
