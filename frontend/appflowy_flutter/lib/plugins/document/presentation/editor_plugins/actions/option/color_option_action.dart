import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const optionActionColorDefaultColor = 'appflowy_theme_default_color';

class ColorOptionAction extends CustomActionCell {
  ColorOptionAction({
    required this.editorState,
  });

  final EditorState editorState;
  final PopoverController innerController = PopoverController();

  @override
  Widget buildWithContext(
    BuildContext context,
    PopoverController controller,
    PopoverMutex? mutex,
  ) {
    return AppFlowyPopover(
      asBarrier: true,
      controller: innerController,
      mutex: mutex,
      popupBuilder: (context) => _buildColorOptionMenu(
        context,
        controller,
      ),
      direction: PopoverDirection.rightWithCenterAligned,
      offset: const Offset(10, 0),
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: HoverButton(
        itemHeight: ActionListSizes.itemHeight,
        leftIcon: const FlowySvg(
          FlowySvgs.color_format_m,
          size: Size.square(15),
        ),
        name: LocaleKeys.document_plugins_optionAction_color.tr(),
        onTap: () {
          innerController.show();
        },
      ),
    );
  }

  Widget _buildColorOptionMenu(
    BuildContext context,
    PopoverController controller,
  ) {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return const SizedBox.shrink();
    }

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return const SizedBox.shrink();
    }

    return _buildColorOptions(context, node, controller);
  }

  Widget _buildColorOptions(
    BuildContext context,
    Node node,
    PopoverController controller,
  ) {
    final selection = editorState.selection?.normalized;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return const SizedBox.shrink();
    }
    final bgColor = node.attributes[blockComponentBackgroundColor] as String?;
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

        innerController.close();
        controller.close();
      },
    );
  }
}
