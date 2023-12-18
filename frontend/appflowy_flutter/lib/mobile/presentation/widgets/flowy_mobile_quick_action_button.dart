import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileQuickActionButton extends StatelessWidget {
  const MobileQuickActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.text,
    this.color,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            FlowySvg(icon, size: const Size.square(20), color: color),
            const HSpace(8),
            FlowyText(text, fontSize: 15, color: color),
          ],
        ),
      ),
    );
  }
}
