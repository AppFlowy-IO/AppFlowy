import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/select_option_editor.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

enum OptionAction {
  delete,
  duplicate,
  turnInto,
  moveUp,
  moveDown,
  color,
  divider,
  align,
}

enum OptionAlignType {
  left,
  center,
  right;

  String get name {
    switch (this) {
      case OptionAlignType.left:
        return 'left';
      case OptionAlignType.center:
        return 'center';
      case OptionAlignType.right:
        return 'right';
    }
  }
}

class DividerOptionAction extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context) {
    return const Divider(
      height: 1.0,
      thickness: 1.0,
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
      name: 'editor/align/$align',
      size: const Size.square(12),
    ).padding(all: 2.0);
  }

  @override
  String get name {
    return LocaleKeys.document_plugins_optionAction_align.tr();
  }

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
        final List<Widget> children =
            OptionAlignType.values.map((e) => OptionAlignWrapper(e)).map((e) {
          final leftIcon = e.leftIcon(Theme.of(context).colorScheme.onSurface);
          final rightIcon =
              e.rightIcon(Theme.of(context).colorScheme.onSurface);
          return HoverButton(
            onTap: () async {
              await onAlignChanged(e.inner);
              controller.close();
              parentController.close();
            },
            itemHeight: ActionListSizes.itemHeight,
            leftIcon: leftIcon,
            name: e.name,
            rightIcon: rightIcon,
          );
        }).toList();

        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              children: children,
            ),
          ),
        );
      };

  String get align {
    final selection = editorState.selection;
    if (selection == null) {
      return 'center';
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final align = node?.attributes['align'];
    return align ?? 'center';
  }

  Future<void> onAlignChanged(OptionAlignType align) async {
    final name = align.name;
    if (name == this.align) {
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
      'align': name,
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
      name: 'editor/color_formatter',
      size: Size.square(12),
    ).padding(all: 2.0);
  }

  @override
  String get name {
    return LocaleKeys.document_plugins_optionAction_color.tr();
  }

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
        final selectedColor = convertHexToSelectOptionColorPB(
          bgColor,
          context,
        );

        return SelectOptionColorList(
          selectedColor: selectedColor,
          onSelectedColor: (color) async {
            final nodes = editorState.getNodesInSelection(selection);
            final transaction = editorState.transaction;
            for (final node in nodes) {
              transaction.updateNode(node, {
                blockComponentBackgroundColor: color.toColor(context).toHex(),
              });
            }
            await editorState.apply(transaction);

            controller.close();
            parentController.close();
          },
        );
      };

  SelectOptionColorPB? convertHexToSelectOptionColorPB(
    String? hexColor,
    BuildContext context,
  ) {
    if (hexColor == null) {
      return null;
    }
    for (final value in SelectOptionColorPB.values) {
      if (value.toColor(context).toHex() == hexColor) {
        return value;
      }
    }
    return null;
  }
}

class OptionActionWrapper extends ActionCell {
  OptionActionWrapper(this.inner);

  final OptionAction inner;

  @override
  Widget? leftIcon(Color iconColor) {
    var name = '';
    // TODO: add icons.
    switch (inner) {
      case OptionAction.delete:
        name = 'editor/delete';
        break;
      case OptionAction.duplicate:
        name = 'editor/duplicate';
        break;
      case OptionAction.turnInto:
        name = 'editor/turn_into';
        break;
      case OptionAction.moveUp:
        name = 'editor/move_up';
        break;
      case OptionAction.moveDown:
        name = 'editor/move_down';
        break;
      case OptionAction.align:
        name = 'editor/align/center';
      default:
        throw UnimplementedError();
    }
    if (name.isEmpty) {
      return null;
    }
    return FlowySvg(name: name);
  }

  @override
  String get name {
    var description = '';
    switch (inner) {
      case OptionAction.delete:
        description = LocaleKeys.document_plugins_optionAction_delete.tr();
        break;
      case OptionAction.duplicate:
        description = LocaleKeys.document_plugins_optionAction_duplicate.tr();
        break;
      case OptionAction.turnInto:
        description = LocaleKeys.document_plugins_optionAction_turnInto.tr();
        break;
      case OptionAction.moveUp:
        description = LocaleKeys.document_plugins_optionAction_moveUp.tr();
        break;
      case OptionAction.moveDown:
        description = LocaleKeys.document_plugins_optionAction_moveDown.tr();
        break;
      case OptionAction.color:
        description = LocaleKeys.document_plugins_optionAction_color.tr();
        break;
      case OptionAction.align:
        description = LocaleKeys.document_plugins_optionAction_align.tr();
        break;
      case OptionAction.divider:
        throw UnimplementedError();
    }
    return description;
  }
}

class OptionAlignWrapper extends ActionCell {
  OptionAlignWrapper(this.inner);

  final OptionAlignType inner;

  @override
  Widget? leftIcon(Color iconColor) {
    var name = '';
    // TODO: add icons.
    switch (inner) {
      case OptionAlignType.left:
        name = 'editor/align/left';
        break;
      case OptionAlignType.center:
        name = 'editor/align/center';
        break;
      case OptionAlignType.right:
        name = 'editor/align/right';
        break;
      default:
        throw UnimplementedError();
    }
    if (name.isEmpty) {
      return null;
    }
    return FlowySvg(name: name);
  }

  @override
  String get name {
    var description = '';
    switch (inner) {
      case OptionAlignType.left:
        description = LocaleKeys.document_plugins_optionAction_left.tr();
        break;
      case OptionAlignType.center:
        description = LocaleKeys.document_plugins_optionAction_center.tr();
        break;
      case OptionAlignType.right:
        description = LocaleKeys.document_plugins_optionAction_right.tr();
        {}
        break;
      default:
        throw UnimplementedError();
    }
    return description;
  }
}
