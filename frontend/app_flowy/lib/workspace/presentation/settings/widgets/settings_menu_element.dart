import 'package:flowy_infra/theme.dart';
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
    return ListTile(
      leading: Icon(
        icon,
        size: 16,
        color: index == currentIndex ? Colors.black : Theme.of(context).iconTheme.color,
      ),
      onTap: () {
        changeSelectedIndex(index);
      },
      selected: index == currentIndex,
      selectedColor: Colors.black,
      selectedTileColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      minLeadingWidth: 0,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
