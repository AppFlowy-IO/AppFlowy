import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _kTextHeadingItemId = 'editor.text_heading';

final ToolbarItem customTextHeadingItem = ToolbarItem(
  id: _kTextHeadingItemId,
  group: 1,
  isActive: onlyShowInSingleSelectionAndTextType,
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
      offset: const Offset(-8.0, 2.0),
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
      width: 52,
      height: 32,
      isSelected: isSelected,
      hoverColor: AFThemeExtension.of(context).toolbarHoverColor,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.toolbar_text_format_m,
            size: Size.square(20),
            color: iconColor,
          ),
          FlowySvg(
            FlowySvgs.toolbar_arrow_down_m,
            size: Size.square(20),
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
          _kTextHeadingItemId,
          LocaleKeys.document_toolbar_textSize.tr(),
          child,
        ) ??
        child;
  }

  Widget buildPopoverContent() {
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
              onTap: () {
                command.onExecute(widget.editorState);
                popoverController.close();
              },
            ),
          );
        }),
      ),
    );
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

  void onExecute(EditorState editorState) {
    final selection = editorState.selection!;
    final node = editorState.getNodeAtPath(selection.start.path)!;
    final delta = (node.delta ?? Delta()).toJson();
    switch (this) {
      case text:
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
        break;
      case h1:
        onLevelChanged(editorState, 1);
        break;
      case h2:
        onLevelChanged(editorState, 2);
        break;
      case h3:
        onLevelChanged(editorState, 3);
        break;
    }
  }

  Future<void> onLevelChanged(EditorState editorState, int newLevel) async {
    final selection = editorState.selection!;
    final node = editorState.getNodeAtPath(selection.start.path)!;
    final delta = (node.delta ?? Delta()).toJson();
    final level = node.attributes[HeadingBlockKeys.level] ?? 1;
    final originLevel = level;
    final type = newLevel == originLevel && node.type == HeadingBlockKeys.type
        ? ParagraphBlockKeys.type
        : HeadingBlockKeys.type;

    if (type == HeadingBlockKeys.type) {
      // from paragraph to heading
      final newNode = node.copyWith(
        type: type,
        attributes: {
          HeadingBlockKeys.level: newLevel,
          blockComponentBackgroundColor:
              node.attributes[blockComponentBackgroundColor],
          blockComponentTextDirection:
              node.attributes[blockComponentTextDirection],
          blockComponentDelta: delta,
        },
      );
      final children = node.children.map((child) => child.deepCopy());

      final transaction = editorState.transaction;
      transaction.insertNodes(
        selection.start.path.next,
        [newNode, ...children],
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
    } else {
      // from heading to paragraph
      await editorState.formatNode(
        selection,
        (node) => node.copyWith(
          type: type,
          attributes: {
            HeadingBlockKeys.level: newLevel,
            blockComponentBackgroundColor:
                node.attributes[blockComponentBackgroundColor],
            blockComponentTextDirection:
                node.attributes[blockComponentTextDirection],
            blockComponentDelta: delta,
          },
        ),
      );
    }
  }
}
