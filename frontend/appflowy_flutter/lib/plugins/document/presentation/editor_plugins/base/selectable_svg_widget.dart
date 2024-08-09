import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class SelectableSvgWidget extends StatelessWidget {
  const SelectableSvgWidget({
    super.key,
    required this.data,
    required this.isSelected,
    required this.style,
  });

  final FlowySvgData data;
  final bool isSelected;
  final SelectionMenuStyle style;

  @override
  Widget build(BuildContext context) {
    return FlowySvg(
      data,
      size: const Size.square(16.0),
      color: isSelected
          ? style.selectionMenuItemSelectedIconColor
          : style.selectionMenuItemIconColor,
    );
  }
}

class SelectableIconWidget extends StatelessWidget {
  const SelectableIconWidget({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.style,
  });

  final IconData icon;
  final bool isSelected;
  final SelectionMenuStyle style;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 18.0,
      color: isSelected
          ? style.selectionMenuItemSelectedIconColor
          : style.selectionMenuItemIconColor,
    );
  }
}
