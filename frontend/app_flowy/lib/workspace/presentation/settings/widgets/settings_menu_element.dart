import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return ListTile(
      leading: Icon(
        icon,
        size: 16,
        color: index == currentIndex ? Colors.black : theme.textColor,
      ),
      onTap: () {
        changeSelectedIndex(index);
      },
      selected: index == currentIndex,
      selectedColor: Colors.black,
      selectedTileColor: theme.main2,
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
