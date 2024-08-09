import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class SelectableSvgWidget extends StatelessWidget {
  const SelectableSvgWidget({
    super.key,
    required this.data,
    required this.isSelected,
    required this.style,
    this.size,
    this.padding,
  });

  final FlowySvgData data;
  final bool isSelected;
  final SelectionMenuStyle style;
  final Size? size;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final child = FlowySvg(
      data,
      size: size ?? const Size.square(16.0),
      color: isSelected
          ? style.selectionMenuItemSelectedIconColor
          : style.selectionMenuItemIconColor,
    );

    if (padding != null) {
      return Padding(padding: padding!, child: child);
    } else {
      return child;
    }
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
