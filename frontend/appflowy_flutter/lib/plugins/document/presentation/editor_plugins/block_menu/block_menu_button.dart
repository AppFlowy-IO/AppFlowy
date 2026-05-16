import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MenuBlockButton extends StatelessWidget {
  const MenuBlockButton({
    super.key,
    required this.tooltip,
    required this.iconData,
    this.onTap,
  });

  final VoidCallback? onTap;
  final String tooltip;
  final FlowySvgData iconData;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      onTap: onTap,
      text: FlowyTooltip(
        message: tooltip,
        child: FlowySvg(
          iconData,
          size: const Size.square(16),
        ),
      ),
    );
  }
}
