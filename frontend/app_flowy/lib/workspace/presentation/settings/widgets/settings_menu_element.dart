import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class SettingsMenuElement extends StatelessWidget {
  const SettingsMenuElement({
    Key? key,
    required this.index,
    required this.label,
    required this.icon,
    required this.changeSelectedIndex,
    required this.currentIndex,
  }) : super(key: key);

  final int index;
  final int currentIndex;
  final String label;
  final IconData icon;
  final Function changeSelectedIndex;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 16,
        color: index == currentIndex
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface,
      ),
      onTap: () {
        changeSelectedIndex(index);
      },
      selected: index == currentIndex,
      selectedColor: Theme.of(context).colorScheme.onSurface,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      hoverColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      minLeadingWidth: 0,
      title: FlowyText.semibold(
        label,
        fontSize: FontSizes.s14,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
