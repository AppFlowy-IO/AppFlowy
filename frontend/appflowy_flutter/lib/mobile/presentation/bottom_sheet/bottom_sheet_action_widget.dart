import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BottomSheetActionWidget extends StatelessWidget {
  const BottomSheetActionWidget({
    super.key,
    this.svg,
    required this.text,
    required this.onTap,
    this.iconColor,
  });

  final FlowySvgData? svg;
  final String text;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        this.iconColor ?? Theme.of(context).colorScheme.onSurface;

    if (svg == null) {
      return OutlinedButton(
        style: Theme.of(context)
            .outlinedButtonTheme
            .style
            ?.copyWith(alignment: Alignment.center),
        onPressed: onTap,
        child: FlowyText(
          text,
          textAlign: TextAlign.center,
        ),
      );
    }

    return OutlinedButton.icon(
      icon: FlowySvg(
        svg!,
        size: const Size.square(22.0),
        color: iconColor,
      ),
      label: FlowyText(
        text,
        overflow: TextOverflow.ellipsis,
      ),
      style: Theme.of(context)
          .outlinedButtonTheme
          .style
          ?.copyWith(alignment: Alignment.centerLeft),
      onPressed: onTap,
    );
  }
}
