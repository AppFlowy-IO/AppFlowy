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
        color: Colors.black,
      ),
      onTap: () {
        changeSelectedIndex(index);
      },
      selected: index == currentIndex,
      selectedColor: Colors.black,
      selectedTileColor: Colors.blue.shade700,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      minLeadingWidth: 0,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
