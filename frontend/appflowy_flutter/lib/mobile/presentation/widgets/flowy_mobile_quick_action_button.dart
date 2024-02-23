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
    this.enable = true,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final String text;
  final Color? textColor;
  final Color? iconColor;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          if (enable) {
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(12),
        overlayColor:
            enable ? null : const MaterialStatePropertyAll(Colors.transparent),
        splashColor: Colors.transparent,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FlowySvg(
                icon,
                size: const Size.square(20),
                color: enable ? iconColor : Theme.of(context).disabledColor,
              ),
              const HSpace(12),
              Expanded(
                child: FlowyText(
                  text,
                  fontSize: 15,
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
