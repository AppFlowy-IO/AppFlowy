import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.secondary,
      width: 22,
      onPressed: () {
        ActionList(
          anchorContext: context,
          onSelected: onSelected,
        ).show(context);
      },
      icon: svgWidget(
        "home/add",
        color: Theme.of(context).colorScheme.onSurface,
      ).padding(horizontal: 3, vertical: 3),
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
      constraints: BoxConstraints(
        minWidth: 120,
        maxWidth: 280,
        minHeight: items.length * (CreateItem.height),
        maxHeight: items.length * (CreateItem.height),
      ),
    );
  }
}

class CreateItem extends StatelessWidget {
  static const double height = 30;
  static const double verticalPadding = 6;

  final PluginBuilder pluginBuilder;
  final Function(PluginBuilder) onSelected;
  const CreateItem({
    Key? key,
    required this.pluginBuilder,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = HoverStyle(
      hoverColor: Theme.of(context).colorScheme.secondary,
    );

    return FlowyHover(
      style: config,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(pluginBuilder),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 120,
            minHeight: CreateItem.height,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FlowyText.medium(
              pluginBuilder.menuName,
              fontSize: 12,
            ).padding(horizontal: 10),
          ),
        ),
      ),
    );
  }
}
