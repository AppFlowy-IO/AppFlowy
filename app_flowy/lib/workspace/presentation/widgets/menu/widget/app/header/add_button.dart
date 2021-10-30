import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

class AddButton extends StatelessWidget {
  final Function(ViewType) onSelected;
  const AddButton({
    Key? key,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 22,
      onPressed: () {
        ActionList(
          anchorContext: context,
          onSelected: onSelected,
        ).show(context);
      },
      icon: svg("home/add").padding(horizontal: 3, vertical: 3),
    );
  }
}

class ActionList {
  final Function(ViewType) onSelected;
  final BuildContext anchorContext;
  final String _identifier = 'DisclosureButtonActionList';

  const ActionList({required this.anchorContext, required this.onSelected});

  void show(BuildContext buildContext) {
    final items = ViewType.values.where((element) => element != ViewType.Blank).map((ty) {
      return CreateItem(
          viewType: ty,
          onSelected: (viewType) {
            FlowyOverlay.of(buildContext).remove(_identifier);
            onSelected(viewType);
          });
    }).toList();

    ListOverlay.showWithAnchor(
      buildContext,
      identifier: _identifier,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      anchorContext: anchorContext,
      anchorDirection: AnchorDirection.bottomRight,
      maxWidth: 120,
      maxHeight: 80,
    );
  }
}

class CreateItem extends StatelessWidget {
  final ViewType viewType;
  final Function(ViewType) onSelected;
  const CreateItem({
    Key? key,
    required this.viewType,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final config = HoverDisplayConfig(hoverColor: theme.hover);

    return FlowyHover(
      config: config,
      builder: (context, onHover) {
        return GestureDetector(
          onTap: () => onSelected(viewType),
          child: FlowyText.medium(
            viewType.name,
            fontSize: 12,
          ).padding(horizontal: 10, vertical: 6),
        );
      },
    );
  }
}
