import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_writer_block_component.dart';
import 'operations/ai_writer_entities.dart';

const _improveWritingToolbarItemId = 'appflowy.editor.ai_improve_writing';
const _aiWriterToolbarItemId = 'appflowy.editor.ai_writer';

final ToolbarItem improveWritingItem = ToolbarItem(
  id: _improveWritingToolbarItemId,
  group: 0,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, _, __, tooltipBuilder) =>
      ImproveWritingButton(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
  ),
);

final ToolbarItem aiWriterItem = ToolbarItem(
  id: _aiWriterToolbarItemId,
  group: 0,
  isActive: onlyShowInSingleSelectionAndTextType,
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

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(-8.0, 2.0),
      margin: const EdgeInsets.all(8.0),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      popupBuilder: (context) => buildPopoverContent(),
      child: buildChild(),
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
      height: 30.0,
      child: FlowyButton(
        leftIcon: FlowySvg(
          command.icon,
          size: const Size.square(16),
        ),
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

  Widget buildChild() {
    final child = FlowyIconButton(
      hoverColor: Colors.transparent,
      width: 36,
      height: 24,
      icon: Row(
        children: [
          const FlowySvg(
            FlowySvgs.ai_sparks_s,
            size: Size.square(16.0),
            color: Color(0xFFD08EED),
          ),
          const FlowySvg(
            FlowySvgs.ai_source_drop_down_s,
            size: Size.square(12),
            color: Color(0xFF8F959E),
          ),
        ],
      ),
      iconPadding: const EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 2.0,
      ),
      onPressed: () {
        if (_isAIEnabled(widget.editorState)) {
          keepEditorFocusNotifier.increase();
          popoverController.show();
        } else {
          showToastNotification(
            context,
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
    final child = FlowyIconButton(
      hoverColor: Colors.transparent,
      width: 24,
      icon: const FlowySvg(
        FlowySvgs.ai_improve_writing_s,
        size: Size.square(16.0),
        color: Color(0xFFD08EED),
      ),
      iconPadding: const EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 2.0,
      ),
      onPressed: () {
        if (_isAIEnabled(editorState)) {
          keepEditorFocusNotifier.increase();
        } else {
          showToastNotification(
            context,
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
    ..afterSelection = selection
    ..selectionExtraInfo = {selectionExtraInfoDisableToolbar: true};

  await editorState.apply(
    transaction,
    options: const ApplyOptions(
      recordUndo: false,
      inMemoryUpdate: true,
    ),
  );
}

bool _isAIEnabled(EditorState editorState) {
  final documentContext = editorState.document.root.context;
  return documentContext == null ||
      !documentContext.read<DocumentBloc>().isLocalMode;
}
