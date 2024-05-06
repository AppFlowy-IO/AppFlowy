import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

class SettingsMenuElement extends StatelessWidget {
  const SettingsMenuElement({
    super.key,
    required this.page,
    required this.label,
    required this.icon,
    required this.changeSelectedPage,
    required this.selectedPage,
  });

  final SettingsPage page;
  final SettingsPage selectedPage;
  final String label;
  final Widget icon;
  final Function changeSelectedPage;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      isSelected: () => page == selectedPage,
      resetHoverOnRebuild: false,
      style: HoverStyle(
        hoverColor: AFThemeExtension.of(context).greySelect,
        borderRadius: BorderRadius.circular(4),
      ),
      builder: (_, isHovering) => ListTile(
        dense: true,
        leading: iconWidget(
          isHovering || page == selectedPage
              ? Theme.of(context).colorScheme.onSurface
              : AFThemeExtension.of(context).textColor,
        ),
        onTap: () => changeSelectedPage(page),
        selected: page == selectedPage,
        selectedColor: Theme.of(context).colorScheme.onSurface,
        selectedTileColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        minLeadingWidth: 0,
        title: FlowyText.medium(
          label,
          fontSize: FontSizes.s14,
          overflow: TextOverflow.ellipsis,
          color: page == selectedPage
              ? Theme.of(context).colorScheme.onSurface
              : null,
        ),
      ),
    );
  }

  Widget iconWidget(Color color) => IconTheme(
        data: IconThemeData(color: color),
        child: icon,
      );
}
