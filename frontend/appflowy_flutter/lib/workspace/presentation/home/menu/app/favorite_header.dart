import 'package:expandable/expandable.dart';
import 'package:flowy_infra/icon_data.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'menu_app.dart';

class FavoriteHeader extends StatelessWidget {
  const FavoriteHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MenuAppSizes.headerHeight,
      child: FlowyHover(
        style: HoverStyle(
          hoverColor: Theme.of(context).colorScheme.secondary,
        ),
        child: InkWell(
          onTap: () {
            ExpandableController.of(
              context,
              rebuildOnChange: false,
              required: true,
            )?.toggle();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _renderExpandedIcon(context),
              const Text("Favorites"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderExpandedIcon(BuildContext context) {
    return SizedBox(
      width: MenuAppSizes.headerHeight,
      height: MenuAppSizes.headerHeight,
      child: ExpandableIcon(
        theme: ExpandableThemeData(
          expandIcon: FlowyIconData.drop_down_show,
          collapseIcon: FlowyIconData.drop_down_hide,
          iconColor: Theme.of(context).colorScheme.tertiary,
          iconSize: MenuAppSizes.iconSize,
          iconPadding: const EdgeInsets.only(right: 10),
          hasIcon: false,
        ),
      ),
    );
  }
}
