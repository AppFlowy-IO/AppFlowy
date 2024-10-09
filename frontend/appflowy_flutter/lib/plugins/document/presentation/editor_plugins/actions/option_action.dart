import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

const optionActionColorDefaultColor = 'appflowy_theme_default_color';

enum OptionAction {
  delete,
  duplicate,
  turnInto,
  moveUp,
  moveDown,
  copyLinkToBlock,

  /// callout background color
  color,
  divider,
  align,
  depth;

  FlowySvgData get svg {
    switch (this) {
      case OptionAction.delete:
        return FlowySvgs.trash_s;
      case OptionAction.duplicate:
        return FlowySvgs.copy_s;
      case OptionAction.turnInto:
        return FlowySvgs.copy_s;
      case OptionAction.moveUp:
        return const FlowySvgData('editor/move_up');
      case OptionAction.moveDown:
        return const FlowySvgData('editor/move_down');
      case OptionAction.color:
        return const FlowySvgData('editor/color');
      case OptionAction.divider:
        return const FlowySvgData('editor/divider');
      case OptionAction.align:
        return FlowySvgs.m_aa_bulleted_list_s;
      case OptionAction.depth:
        return FlowySvgs.tag_s;
      case OptionAction.copyLinkToBlock:
        return FlowySvgs.share_tab_copy_s;
    }
  }

  String get description {
    switch (this) {
      case OptionAction.delete:
        return LocaleKeys.document_plugins_optionAction_delete.tr();
      case OptionAction.duplicate:
        return LocaleKeys.document_plugins_optionAction_duplicate.tr();
      case OptionAction.turnInto:
        return LocaleKeys.document_plugins_optionAction_turnInto.tr();
      case OptionAction.moveUp:
        return LocaleKeys.document_plugins_optionAction_moveUp.tr();
      case OptionAction.moveDown:
        return LocaleKeys.document_plugins_optionAction_moveDown.tr();
      case OptionAction.color:
        return LocaleKeys.document_plugins_optionAction_color.tr();
      case OptionAction.align:
        return LocaleKeys.document_plugins_optionAction_align.tr();
      case OptionAction.depth:
        return LocaleKeys.document_plugins_optionAction_depth.tr();
      case OptionAction.copyLinkToBlock:
        return LocaleKeys.document_plugins_optionAction_copyLinkToBlock.tr();
      case OptionAction.divider:
        throw UnsupportedError('Divider does not have description');
    }
  }
}

enum OptionAlignType {
  left,
  center,
  right;

  static OptionAlignType fromString(String? value) {
    switch (value) {
      case 'left':
        return OptionAlignType.left;
      case 'center':
        return OptionAlignType.center;
      case 'right':
        return OptionAlignType.right;
      default:
        return OptionAlignType.center;
    }
  }

  FlowySvgData get svg {
    switch (this) {
      case OptionAlignType.left:
        return FlowySvgs.align_left_s;
      case OptionAlignType.center:
        return FlowySvgs.align_center_s;
      case OptionAlignType.right:
        return FlowySvgs.align_right_s;
    }
  }

  String get description {
    switch (this) {
      case OptionAlignType.left:
        return LocaleKeys.document_plugins_optionAction_left.tr();
      case OptionAlignType.center:
        return LocaleKeys.document_plugins_optionAction_center.tr();
      case OptionAlignType.right:
        return LocaleKeys.document_plugins_optionAction_right.tr();
    }
  }
}

enum OptionDepthType {
  h1(1, 'H1'),
  h2(2, 'H2'),
  h3(3, 'H3'),
  h4(4, 'H4'),
  h5(5, 'H5'),
  h6(6, 'H6');

  const OptionDepthType(this.level, this.description);

  final String description;
  final int level;

  static OptionDepthType fromLevel(int? level) {
    switch (level) {
      case 1:
        return OptionDepthType.h1;
      case 2:
        return OptionDepthType.h2;
      case 3:
      default:
        return OptionDepthType.h3;
    }
  }
}

class DividerOptionAction extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(
        height: 1.0,
        thickness: 1.0,
      ),
    );
  }
}

class AlignOptionAction extends PopoverActionCell {
  AlignOptionAction({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return FlowySvg(
      align.svg,
      size: const Size.square(12),
    ).padding(all: 2.0);
  }

  @override
  String get name {
    return LocaleKeys.document_plugins_optionAction_align.tr();
  }

  @override
  PopoverActionCellBuilder get builder =>
      (context, parentController, controller) {
        final selection = editorState.selection?.normalized;
        if (selection == null) {
          return const SizedBox.shrink();
        }
        final node = editorState.getNodeAtPath(selection.start.path);
        if (node == null) {
          return const SizedBox.shrink();
        }
        final children = buildAlignOptions(context, (align) async {
          await onAlignChanged(align);
          controller.close();
          parentController.close();
        });
        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              children: children,
            ),
          ),
        );
      };

  List<Widget> buildAlignOptions(
    BuildContext context,
    void Function(OptionAlignType) onTap,
  ) {
    return OptionAlignType.values.map((e) => OptionAlignWrapper(e)).map((e) {
      final leftIcon = e.leftIcon(Theme.of(context).colorScheme.onSurface);
      final rightIcon = e.rightIcon(Theme.of(context).colorScheme.onSurface);
      return HoverButton(
        onTap: () => onTap(e.inner),
        itemHeight: ActionListSizes.itemHeight,
        leftIcon: leftIcon,
        name: e.name,
        rightIcon: rightIcon,
      );
    }).toList();
  }

  OptionAlignType get align {
    final selection = editorState.selection;
    if (selection == null) {
      return OptionAlignType.center;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final align = node?.attributes['align'];
    return OptionAlignType.fromString(align);
  }

  Future<void> onAlignChanged(OptionAlignType align) async {
    if (align == this.align) {
      return;
    }
    final selection = editorState.selection;
    if (selection == null) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final transaction = editorState.transaction;
    transaction.updateNode(node, {
      'align': align.name,
    });
    await editorState.apply(transaction);
  }
}

class ColorOptionAction extends PopoverActionCell {
  ColorOptionAction({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return const FlowySvg(
      FlowySvgs.color_format_m,
      size: Size.square(16),
    );
  }

  @override
  String get name => LocaleKeys.document_plugins_optionAction_color.tr();

  @override
  Widget Function(
    BuildContext context,
    PopoverController parentController,
    PopoverController controller,
  ) get builder => (context, parentController, controller) {
        final selection = editorState.selection?.normalized;
        if (selection == null) {
          return const SizedBox.shrink();
        }
        final node = editorState.getNodeAtPath(selection.start.path);
        if (node == null) {
          return const SizedBox.shrink();
        }
        final bgColor =
            node.attributes[blockComponentBackgroundColor] as String?;
        final selectedColor = bgColor?.tryToColor();
        // get default background color for callout block from themeExtension
        final defaultColor = node.type == CalloutBlockKeys.type
            ? AFThemeExtension.of(context).calloutBGColor
            : Colors.transparent;
        final colors = [
          // reset to default background color
          FlowyColorOption(
            color: defaultColor,
            i18n: LocaleKeys.document_plugins_optionAction_defaultColor.tr(),
            id: optionActionColorDefaultColor,
          ),
          ...FlowyTint.values.map(
            (e) => FlowyColorOption(
              color: e.color(context),
              i18n: e.tintName(AppFlowyEditorL10n.current),
              id: e.id,
            ),
          ),
        ];

        return FlowyColorPicker(
          colors: colors,
          selected: selectedColor,
          border: Border.all(
            color: AFThemeExtension.of(context).onBackground,
          ),
          onTap: (option, index) async {
            final transaction = editorState.transaction;
            transaction.updateNode(node, {
              blockComponentBackgroundColor: option.id,
            });
            await editorState.apply(transaction);

            controller.close();
            parentController.close();
          },
        );
      };
}

class DepthOptionAction extends PopoverActionCell {
  DepthOptionAction({required this.editorState});

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return FlowySvg(
      OptionAction.depth.svg,
      size: const Size.square(12),
    ).padding(all: 2.0);
  }

  @override
  String get name => LocaleKeys.document_plugins_optionAction_depth.tr();

  @override
  PopoverActionCellBuilder get builder =>
      (context, parentController, controller) {
        final children = buildDepthOptions(context, (depth) async {
          await onDepthChanged(depth);
          controller.close();
          parentController.close();
        });

        return SizedBox(
          width: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      };

  List<Widget> buildDepthOptions(
    BuildContext context,
    Future<void> Function(OptionDepthType) onTap,
  ) {
    return OptionDepthType.values
        .map((e) => OptionDepthWrapper(e))
        .map(
          (e) => HoverButton(
            onTap: () => onTap(e.inner),
            itemHeight: ActionListSizes.itemHeight,
            name: e.name,
          ),
        )
        .toList();
  }

  OptionDepthType depth(Node node) {
    final level = node.attributes[OutlineBlockKeys.depth];
    return OptionDepthType.fromLevel(level);
  }

  Future<void> onDepthChanged(OptionDepthType depth) async {
    final selection = editorState.selection;
    final node = selection != null
        ? editorState.getNodeAtPath(selection.start.path)
        : null;

    if (node == null || depth == this.depth(node)) return;

    final transaction = editorState.transaction;
    transaction.updateNode(
      node,
      {OutlineBlockKeys.depth: depth.level},
    );
    await editorState.apply(transaction);
  }
}

class OptionDepthWrapper extends ActionCell {
  OptionDepthWrapper(this.inner);

  final OptionDepthType inner;

  @override
  String get name => inner.description;
}

class OptionActionWrapper extends ActionCell {
  OptionActionWrapper(this.inner);

  final OptionAction inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(inner.svg);

  @override
  String get name => inner.description;
}

class OptionAlignWrapper extends ActionCell {
  OptionAlignWrapper(this.inner);

  final OptionAlignType inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(inner.svg);

  @override
  String get name => inner.description;
}

class TurnIntoOptionAction extends CustomActionCell {
  TurnIntoOptionAction({
    required this.editorState,
  });

  final EditorState editorState;
  final PopoverController innerController = PopoverController();

  @override
  Widget buildWithContext(BuildContext context, PopoverController controller) {
    return AppFlowyPopover(
      asBarrier: true,
      controller: innerController,
      popupBuilder: (context) => _buildTurnIntoOptionMenu(context),
      direction: PopoverDirection.rightWithCenterAligned,
      offset: const Offset(10, 0),
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: HoverButton(
        itemHeight: ActionListSizes.itemHeight,
        // todo(lucas): replace the svg with the correct one
        leftIcon: const FlowySvg(FlowySvgs.copy_s),
        name: LocaleKeys.document_plugins_optionAction_turnInto.tr(),
        onTap: () {
          innerController.show();
        },
      ),
    );
  }

  Widget _buildTurnIntoOptionMenu(BuildContext context) {
    final selection = editorState.selection?.normalized;
    // the selection may not be collapsed, for example, if a block contains some children,
    // the selection will be the start from the current block and end at the last child block.
    // we should take care of this case:
    // converting a block that contains children to a heading block,
    //  we should move all the children under the heading block.
    if (selection == null) {
      return const SizedBox.shrink();
    }

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _buildTurnIntoOptions(context, node),
    );
  }

  List<Widget> _buildTurnIntoOptions(BuildContext context, Node node) {
    final children = <Widget>[];

    for (final type in EditorOptionActionType.turnInto.supportTypes) {
      if (type != HeadingBlockKeys.type) {
        children.add(
          _buildTurnIntoOption(
            context,
            type,
            node,
          ),
        );
      } else {
        // support h4-6
        for (final i in [1, 2, 3]) {
          children.add(
            _buildTurnIntoOption(
              context,
              type,
              node,
              level: i,
            ),
          );
        }
      }
    }

    return children;
  }

  Widget _buildTurnIntoOption(
    BuildContext context,
    String type,
    Node node, {
    int? level,
  }) {
    final name = _buildLocalization(
      type,
      level: level,
    );
    final leftIcon = _buildLeftIcon(
      type,
      level: level,
    );
    final rightIcon = _buildRightIcon(
      type,
      node,
      level: level,
    );

    return HoverButton(
      name: name,
      leftIcon: FlowySvg(leftIcon),
      rightIcon: rightIcon,
      itemHeight: ActionListSizes.itemHeight,
      onTap: () {},
    );
  }

  Widget? _buildRightIcon(
    String type,
    Node node, {
    int? level,
  }) {
    if (type != node.type) {
      return null;
    }

    if (node.type == HeadingBlockKeys.type) {
      final nodeLevel = node.attributes[HeadingBlockKeys.level] ?? 1;
      if (level != nodeLevel) {
        return null;
      }
    }

    return const FlowySvg(
      FlowySvgs.workspace_selected_s,
      blendMode: null,
    );
  }

  FlowySvgData _buildLeftIcon(
    String type, {
    int? level,
  }) {
    if (type == ParagraphBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_text_s;
    } else if (type == HeadingBlockKeys.type) {
      switch (level) {
        case 1:
          return FlowySvgs.slash_menu_icon_h1_s;
        case 2:
          return FlowySvgs.slash_menu_icon_h2_s;
        case 3:
          return FlowySvgs.slash_menu_icon_h3_s;
        // support h4-h6
        default:
          return FlowySvgs.slash_menu_icon_text_s;
      }
    } else if (type == QuoteBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_quote_s;
    } else if (type == BulletedListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_bulleted_list_s;
    } else if (type == NumberedListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_numbered_list_s;
    } else if (type == TodoListBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_checkbox_s;
    } else if (type == CalloutBlockKeys.type) {
      return FlowySvgs.slash_menu_icon_callout_s;
    }

    throw UnimplementedError('Unsupported block type: $type');
  }

  String _buildLocalization(
    String type, {
    int? level,
  }) {
    switch (type) {
      case ParagraphBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_text.tr();
      case HeadingBlockKeys.type:
        switch (level) {
          case 1:
            return LocaleKeys.document_slashMenu_name_heading1.tr();
          case 2:
            return LocaleKeys.document_slashMenu_name_heading2.tr();
          case 3:
            return LocaleKeys.document_slashMenu_name_heading3.tr();
          default:
            return LocaleKeys.document_slashMenu_name_text.tr();
        }
      case QuoteBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_quote.tr();
      case BulletedListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_bulletedList.tr();
      case NumberedListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_numberedList.tr();
      case TodoListBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_todoList.tr();
      case CalloutBlockKeys.type:
        return LocaleKeys.document_slashMenu_name_callout.tr();
    }

    throw UnimplementedError('Unsupported block type: $type');
  }
}
