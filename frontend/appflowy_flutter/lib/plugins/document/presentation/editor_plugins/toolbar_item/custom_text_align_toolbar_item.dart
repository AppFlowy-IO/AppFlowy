import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'toolbar_id_enum.dart';

final ToolbarItem customTextAlignItem = ToolbarItem(
  id: ToolbarId.textAlign.id,
  group: 4,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (
    context,
    editorState,
    highlightColor,
    iconColor,
    tooltipBuilder,
  ) {
    return TextAlignActionList(
      editorState: editorState,
      tooltipBuilder: tooltipBuilder,
      highlightColor: highlightColor,
    );
  },
);

class TextAlignActionList extends StatefulWidget {
  const TextAlignActionList({
    super.key,
    required this.editorState,
    required this.highlightColor,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;
  final Color highlightColor;

  @override
  State<TextAlignActionList> createState() => _TextAlignActionListState();
}

class _TextAlignActionListState extends State<TextAlignActionList> {
  final popoverController = PopoverController();

  bool isSelected = false;

  EditorState get editorState => widget.editorState;

  Color get highlightColor => widget.highlightColor;

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
    final iconColor = Theme.of(context).iconTheme.color;
    final child = FlowyIconButton(
      width: 48,
      height: 32,
      isSelected: isSelected,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.toolbar_alignment_m,
            size: Size.square(20),
            color: iconColor,
          ),
          HSpace(4),
          FlowySvg(
            FlowySvgs.toolbar_arrow_down_m,
            size: Size(12, 20),
            color: iconColor,
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
          ToolbarId.textAlign.id,
          LocaleKeys.document_toolbar_textAlign.tr(),
          child,
        ) ??
        child;
  }

  Widget buildPopoverContent() {
    return MouseRegion(
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(4.0),
        children: List.generate(TextAlignCommand.values.length, (index) {
          final command = TextAlignCommand.values[index];
          final selection = editorState.selection!;
          final nodes = editorState.getNodesInSelection(selection);
          final isHighlight = nodes.every(
            (n) => n.attributes[blockComponentAlign] == command.name,
          );

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
              rightIcon:
                  isHighlight ? FlowySvg(FlowySvgs.toolbar_check_m) : null,
              onTap: () {
                command.onAlignChanged(editorState);
                popoverController.close();
              },
            ),
          );
        }),
      ),
    );
  }
}

enum TextAlignCommand {
  left(FlowySvgs.toolbar_text_align_left_m),
  center(FlowySvgs.toolbar_text_align_center_m),
  right(FlowySvgs.toolbar_text_align_right_m);

  const TextAlignCommand(this.svg);

  final FlowySvgData svg;

  String get title {
    switch (this) {
      case left:
        return LocaleKeys.document_toolbar_alignLeft.tr();
      case center:
        return LocaleKeys.document_toolbar_alignCenter.tr();
      case right:
        return LocaleKeys.document_toolbar_alignRight.tr();
    }
  }

  Future<void> onAlignChanged(EditorState editorState) async {
    final selection = editorState.selection!;

    await editorState.updateNode(
      selection,
      (node) => node.copyWith(
        attributes: {
          ...node.attributes,
          blockComponentAlign: name,
        },
      ),
      selectionExtraInfo: {
        selectionExtraInfoDoNotAttachTextService: true,
        selectionExtraInfoDisableFloatingToolbar: true,
      },
    );
  }
}
