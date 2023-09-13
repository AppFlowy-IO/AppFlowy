import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  final IconData icon;
  final Function changeSelectedPage;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      resetHoverOnRebuild: false,
      style: HoverStyle(
        hoverColor: Theme.of(context).colorScheme.primary,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 16,
          color: page == selectedPage
              ? Theme.of(context).colorScheme.onSurface
              : null,
        ),
        onTap: () {
          changeSelectedPage(page);
        },
        selected: page == selectedPage,
        selectedColor: Theme.of(context).colorScheme.onSurface,
        selectedTileColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        minLeadingWidth: 0,
        title: FlowyText.semibold(
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
}
