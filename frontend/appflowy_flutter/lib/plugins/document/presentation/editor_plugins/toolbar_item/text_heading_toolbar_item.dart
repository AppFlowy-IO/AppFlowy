import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension_v2.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'toolbar_id_enum.dart';

final ToolbarItem customTextHeadingItem = ToolbarItem(
  id: ToolbarId.textHeading.id,
  group: 1,
  isActive: onlyShowInSingleTextTypeSelectionAndExcludeTable,
  builder: (
    context,
    editorState,
    highlightColor,
    iconColor,
    tooltipBuilder,
  ) {
    return TextHeadingActionList(
      editorState: editorState,
      tooltipBuilder: tooltipBuilder,
    );
  },
);

class TextHeadingActionList extends StatefulWidget {
  const TextHeadingActionList({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  State<TextHeadingActionList> createState() => _TextHeadingActionListState();
}

class _TextHeadingActionListState extends State<TextHeadingActionList> {
  final popoverController = PopoverController();

  bool isSelected = false;

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
  }

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

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  Widget buildChild(BuildContext context) {
    final themeV2 = AFThemeExtensionV2.of(context);
    final child = FlowyIconButton(
      width: 48,
      height: 32,
      isSelected: isSelected,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.toolbar_text_format_m,
            size: Size.square(20),
            color: themeV2.icon_primary,
          ),
          HSpace(4),
          FlowySvg(
            FlowySvgs.toolbar_arrow_down_m,
            size: Size(12, 20),
            color: themeV2.icon_tertiary,
          ),
        ],
      ),
      onPressed: () {
        setState(() {
          isSelected = true;
        });
        showPopover();
      },
    );

    return widget.tooltipBuilder?.call(
          context,
          ToolbarId.textHeading.id,
          LocaleKeys.document_toolbar_textSize.tr(),
          child,
        ) ??
        child;
  }

  Widget buildPopoverContent() {
    final selectingCommand = getSelectingCommand();
    return MouseRegion(
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(4.0),
        children: List.generate(TextHeadingCommand.values.length, (index) {
          final command = TextHeadingCommand.values[index];
          return SizedBox(
            height: 36,
            child: FlowyButton(
              leftIconSize: const Size.square(20),
              leftIcon: FlowySvg(command.svg),
              iconPadding: 12,
              text: FlowyText(
                command.title,
                fontWeight: FontWeight.w400,
                figmaLineHeight: 20,
              ),
              rightIcon: selectingCommand == command
                  ? FlowySvg(FlowySvgs.toolbar_check_m)
                  : null,
              onTap: () {
                if (command == selectingCommand) return;
                command.onExecute(widget.editorState);
                popoverController.close();
              },
            ),
          );
        }),
      ),
    );
  }

  TextHeadingCommand? getSelectingCommand() {
    final editorState = widget.editorState;
    final selection = editorState.selection;
    if (selection == null || !selection.isSingle) {
      return null;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null || node.delta == null) {
      return null;
    }
    final nodeType = node.type;
    if (nodeType == ParagraphBlockKeys.type) return TextHeadingCommand.text;
    if (nodeType == HeadingBlockKeys.type) {
      final level = node.attributes[HeadingBlockKeys.level] ?? 1;
      if (level == 1) return TextHeadingCommand.h1;
      if (level == 2) return TextHeadingCommand.h2;
      if (level == 3) return TextHeadingCommand.h3;
    }
    return null;
  }
}

enum TextHeadingCommand {
  text(FlowySvgs.type_text_m),
  h1(FlowySvgs.type_h1_m),
  h2(FlowySvgs.type_h2_m),
  h3(FlowySvgs.type_h3_m);

  const TextHeadingCommand(this.svg);

  final FlowySvgData svg;

  String get title {
    switch (this) {
      case text:
        return AppFlowyEditorL10n.current.text;
      case h1:
        return LocaleKeys.document_toolbar_h1.tr();
      case h2:
        return LocaleKeys.document_toolbar_h2.tr();
      case h3:
        return LocaleKeys.document_toolbar_h3.tr();
    }
  }

  void onExecute(EditorState state) {
    switch (this) {
      case text:
        formatNodeToText(state);
        break;
      case h1:
        _turnInto(state, 1);
        break;
      case h2:
        _turnInto(state, 2);
        break;
      case h3:
        _turnInto(state, 3);
        break;
    }
  }

  Future<void> _turnInto(EditorState state, int level) async {
    final selection = state.selection!;
    final node = state.getNodeAtPath(selection.start.path)!;
    await BlockActionOptionCubit.turnIntoBlock(
      HeadingBlockKeys.type,
      node,
      state,
      level: level,
      keepSelection: true,
    );
  }
}

void formatNodeToText(EditorState editorState) {
  final selection = editorState.selection!;
  final node = editorState.getNodeAtPath(selection.start.path)!;
  final delta = (node.delta ?? Delta()).toJson();
  editorState.formatNode(
    selection,
    (node) => node.copyWith(
      type: ParagraphBlockKeys.type,
      attributes: {
        blockComponentDelta: delta,
        blockComponentBackgroundColor:
            node.attributes[blockComponentBackgroundColor],
        blockComponentTextDirection:
            node.attributes[blockComponentTextDirection],
      },
    ),
  );
}
