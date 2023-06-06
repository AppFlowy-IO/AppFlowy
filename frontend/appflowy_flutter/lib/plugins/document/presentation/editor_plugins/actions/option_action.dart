import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide FlowySvg;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
  align;

  String get assetName {
    switch (this) {
      case OptionAction.delete:
        return 'editor/delete';
      case OptionAction.duplicate:
        return 'editor/duplicate';
      case OptionAction.turnInto:
        return 'editor/turn_into';
      case OptionAction.moveUp:
        return 'editor/move_up';
      case OptionAction.moveDown:
        return 'editor/move_down';
      case OptionAction.color:
        return 'editor/color';
      case OptionAction.divider:
        return 'editor/divider';
      case OptionAction.align:
        return 'editor/align/center';
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

  String get assetName {
    switch (this) {
      case OptionAlignType.left:
        return 'editor/align/left';
      case OptionAlignType.center:
        return 'editor/align/center';
      case OptionAlignType.right:
        return 'editor/align/right';
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
      name: align.assetName,
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
      name: 'editor/color_formatter',
      size: Size.square(12),
    ).padding(all: 2.0);
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
        final selectedColor = bgColor?.toColor();

        final colors = [
          // clear background color.
          FlowyColorOption(
            color: Colors.transparent,
            name: LocaleKeys.document_plugins_optionAction_defaultColor.tr(),
          ),
          ...FlowyTint.values.map(
            (e) => FlowyColorOption(
              color: e.color(context),
              name: e.tintName(AppFlowyEditorLocalizations.current),
            ),
          ),
        ];

        return FlowyColorPicker(
          colors: colors,
          selected: selectedColor,
          border: Border.all(
            color: Theme.of(context).colorScheme.onBackground,
            width: 1,
          ),
          onTap: (color, index) async {
            final transaction = editorState.transaction;
            final backgroundColor =
                color == Colors.transparent ? null : color.toHex();
            transaction.updateNode(node, {
              blockComponentBackgroundColor: backgroundColor,
            });
            await editorState.apply(transaction);

            controller.close();
            parentController.close();
          },
        );
      };
}

class OptionActionWrapper extends ActionCell {
  OptionActionWrapper(this.inner);

  final OptionAction inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(name: inner.assetName);

  @override
  String get name => inner.description;
}

class OptionAlignWrapper extends ActionCell {
  OptionAlignWrapper(this.inner);

  final OptionAlignType inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(name: inner.assetName);

  @override
  String get name => inner.description;
}
