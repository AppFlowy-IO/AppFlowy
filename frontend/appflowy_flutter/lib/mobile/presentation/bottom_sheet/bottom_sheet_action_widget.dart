import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

class BottomSheetActionWidget extends StatelessWidget {
  const BottomSheetActionWidget({
    super.key,
    required this.svg,
    required this.text,
    required this.onTap,
    this.iconColor,
  });

  final FlowySvgData svg;
  final String text;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        this.iconColor ?? Theme.of(context).colorScheme.onBackground;

    return OutlinedButton.icon(
      icon: FlowySvg(
        svg,
        size: const Size.square(22.0),
        color: iconColor,
      ),
      label: Text(text),
      style: Theme.of(context)
          .outlinedButtonTheme
          .style
          ?.copyWith(alignment: Alignment.centerLeft),
      onPressed: onTap,
    );
  }
}
