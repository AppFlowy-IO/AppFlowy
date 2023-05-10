import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class SelectableSvgWidget extends StatelessWidget {
  const SelectableSvgWidget({
    super.key,
    required this.name,
    required this.isSelected,
  });

  final String name;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return svgWidget(
      name,
      size: const Size.square(18.0),
      color: isSelected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onBackground,
    );
  }
}

class SelectableIconWidget extends StatelessWidget {
  const SelectableIconWidget({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Icon(
      icon,
      size: 18.0,
      color: isSelected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onBackground,
    );
  }
}
