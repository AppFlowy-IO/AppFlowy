import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

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
    final theme = AppFlowyTheme.of(context);
    return AFBaseButton(
      onTap: () => changeSelectedPage(page),
      padding: EdgeInsets.all(theme.spacing.m),
      borderRadius: theme.borderRadius.m,
      borderColor: (_, __, ___, ____) => Colors.transparent,
      backgroundColor: (_, isHovering, __) {
        if (isHovering) {
          return theme.fillColorScheme.contentHover;
        } else if (page == selectedPage) {
          return theme.fillColorScheme.themeSelect;
        }
        return theme.fillColorScheme.content;
      },
      builder: (_, __, ___) {
        return Row(
          children: [
            icon,
            HSpace(theme.spacing.m),
            Text(
              label,
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  // return FlowyHover(
  //   isSelected: () => page == selectedPage,
  //   resetHoverOnRebuild: false,
  //   style: HoverStyle(
  //     hoverColor: AFThemeExtension.of(context).greyHover,
  //     borderRadius: BorderRadius.circular(4),
  //   ),
  //   builder: (_, isHovering) => ListTile(
  //     dense: true,
  //     leading: iconWidget(
  //       isHovering || page == selectedPage
  //           ? Theme.of(context).colorScheme.onSurface
  //           : AFThemeExtension.of(context).textColor,
  //     ),
  //     onTap: () => changeSelectedPage(page),
  //     selected: page == selectedPage,
  //     selectedColor: Theme.of(context).colorScheme.onSurface,
  //     selectedTileColor: Theme.of(context).colorScheme.primary,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(5),
  //     ),
  //     minLeadingWidth: 0,
  //     title: FlowyText.medium(
  //       label,
  //       fontSize: FontSizes.s14,
  //       overflow: TextOverflow.ellipsis,
  //       color: page == selectedPage
  //           ? Theme.of(context).colorScheme.onSurface
  //           : null,
  //     ),
  //   ),
  // );
}
