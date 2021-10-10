import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/material.dart';

enum MenuItemType {
  userProfile,
  dashboard,
  favorites,
  app,
}

abstract class MenuItem extends StatelessWidget {
  const MenuItem({Key? key}) : super(key: key);

  MenuItemType get type;
}

class MenuList extends StatelessWidget {
  final List<MenuItem> menuItems;
  const MenuList({required this.menuItems, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableTheme(
      data: ExpandableThemeData(useInkWell: true, animationDuration: Durations.medium),
      child: Expanded(
        child: ListView.separated(
          itemCount: menuItems.length,
          separatorBuilder: (context, index) {
            if (index == 0) {
              return const VSpace(29);
            } else {
              return const VSpace(24);
            }
          },
          physics: const BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return menuItems[index];
          },
        ),
      ),
    );
  }
}
