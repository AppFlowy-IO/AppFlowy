import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileLogoutButton extends StatelessWidget {
  const MobileLogoutButton({
    super.key,
    this.icon,
    required this.text,
    this.textColor,
    required this.onPressed,
  });

  final FlowySvgData? icon;
  final String text;
  final Color? textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(4),
          ),
          border: Border.all(
            color: textColor ?? style.colorScheme.outline,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SizedBox(
                // The icon could be in different height as original aspect ratio, we use a fixed sizebox to wrap it to make sure they all occupy the same space.
                width: 30,
                height: 30,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    child: FlowySvg(
                      icon!,
                      blendMode: null,
                    ),
                  ),
                ),
              ),
              const HSpace(8),
            ],
            FlowyText(
              text,
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
