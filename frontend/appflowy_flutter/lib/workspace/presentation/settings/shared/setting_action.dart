import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SettingAction extends StatelessWidget {
  const SettingAction({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconWidget = tooltip != null && tooltip!.isNotEmpty
        ? FlowyTooltip(message: tooltip, child: icon)
        : icon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 26,
        child: FlowyHover(
          resetHoverOnRebuild: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                iconWidget,
                if (label != null) ...[
                  const HSpace(4),
                  FlowyText.regular(label!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
