import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class AddButton extends StatelessWidget {
  final Function(PluginBuilder) onSelected;

  const AddButton({
    Key? key,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<PopoverAction> actions = [];
    actions.addAll(
      pluginBuilders()
          .map((pluginBuilder) =>
              AddButtonActionWrapper(pluginBuilder: pluginBuilder))
          .toList(),
    );

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: actions,
      buildChild: (controller) {
        return FlowyIconButton(
          width: 22,
          onPressed: () => controller.show(),
          icon: svgWidget(
            "home/add",
            color: Theme.of(context).colorScheme.onSurface,
          ).padding(horizontal: 3, vertical: 3),
        );
      },
      onSelected: (action, controller) {
        if (action is AddButtonActionWrapper) {
          onSelected(action.pluginBuilder);
        }

        controller.close();
      },
    );
  }
}

class AddButtonActionWrapper extends ActionCell {
  final PluginBuilder pluginBuilder;

  AddButtonActionWrapper({required this.pluginBuilder});

  @override
  Widget? leftIcon(Color iconColor) =>
      svgWidget(pluginBuilder.menuIcon, color: iconColor);

  @override
  String get name => pluginBuilder.menuName;
}
