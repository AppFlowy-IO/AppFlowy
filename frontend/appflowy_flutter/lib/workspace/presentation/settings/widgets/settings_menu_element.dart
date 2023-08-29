import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class SettingsMenuElement extends StatelessWidget {
  const SettingsMenuElement({
    Key? key,
    required this.page,
    required this.label,
    required this.icon,
    required this.changeSelectedPage,
    required this.selectedPage,
  }) : super(key: key);

  final SettingsPage page;
  final SettingsPage selectedPage;
  final String label;
  final IconData icon;
  final Function changeSelectedPage;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      decoration: BoxDecoration(
        color:
            page == selectedPage ? Theme.of(context).colorScheme.primary : null,
        borderRadius: BorderRadius.circular(5),
      ),
      leftIcon: Icon(
        icon,
        size: 16,
        color: page == selectedPage
            ? Theme.of(context).colorScheme.onSurface
            : null,
      ),
      text: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: FlowyText.semibold(
          label,
          fontSize: FontSizes.s14,
          overflow: TextOverflow.ellipsis,
          color: page == selectedPage
              ? Theme.of(context).colorScheme.onSurface
              : null,
        ),
      ),
      onTap: () => changeSelectedPage(page),
    );
  }
}
