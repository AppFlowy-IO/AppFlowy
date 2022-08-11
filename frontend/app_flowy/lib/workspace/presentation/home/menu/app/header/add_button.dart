import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

class AddButton extends StatelessWidget {
  final Function(PluginBuilder) onSelected;
  const AddButton({
    Key? key,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 22,
      onPressed: () {
        ActionList(
          anchorContext: context,
          onSelected: onSelected,
        ).show(context);
      },
      icon: svgWidget("home/add", color: theme.iconColor)
          .padding(horizontal: 3, vertical: 3),
    );
  }
}

class ActionList {
  final Function(PluginBuilder) onSelected;
  final BuildContext anchorContext;
  final String _identifier = 'DisclosureButtonActionList';

  const ActionList({required this.anchorContext, required this.onSelected});

  void show(BuildContext buildContext) {
    final items = pluginBuilders().map(
      (pluginBuilder) {
        return CreateItem(
          pluginBuilder: pluginBuilder,
          onSelected: (builder) {
            onSelected(builder);
            FlowyOverlay.of(buildContext).remove(_identifier);
          },
        );
      },
    ).toList();

    ListOverlay.showWithAnchor(
      buildContext,
      identifier: _identifier,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      anchorContext: anchorContext,
      anchorDirection: AnchorDirection.bottomRight,
      width: 120,
      height: 80,
    );
  }
}

class CreateItem extends StatelessWidget {
  final PluginBuilder pluginBuilder;
  final Function(PluginBuilder) onSelected;
  const CreateItem({
    Key? key,
    required this.pluginBuilder,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final config = HoverStyle(hoverColor: theme.hover);

    return FlowyHover(
      style: config,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(pluginBuilder),
        child: FlowyText.medium(
          pluginBuilder.menuName,
          color: theme.textColor,
          fontSize: 12,
        ).padding(horizontal: 10, vertical: 6),
      ),
    );
  }
}
