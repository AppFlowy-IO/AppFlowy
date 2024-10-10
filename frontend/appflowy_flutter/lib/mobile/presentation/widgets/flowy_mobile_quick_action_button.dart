import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileQuickActionButton extends StatelessWidget {
  const MobileQuickActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.text,
    this.textColor,
    this.iconColor,
    this.iconSize,
    this.enable = true,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final Size? iconSize;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    final iconSize = this.iconSize ?? const Size.square(18);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: enable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        overlayColor:
            enable ? null : const WidgetStatePropertyAll(Colors.transparent),
        splashColor: Colors.transparent,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FlowySvg(
                icon,
                size: iconSize,
                color: enable ? iconColor : Theme.of(context).disabledColor,
              ),
              HSpace(30 - iconSize.width),
              Expanded(
                child: FlowyText.regular(
                  text,
                  fontSize: 16,
                  color: enable ? textColor : Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
