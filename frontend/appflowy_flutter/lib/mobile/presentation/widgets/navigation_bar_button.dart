import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NavigationBarButton extends StatelessWidget {
  const NavigationBarButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.enable = true,
  });

  final String text;
  final FlowySvgData icon;
  final VoidCallback onTap;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enable ? 1.0 : 0.3,
      child: Container(
        height: 40,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0x3F1F2329)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: FlowyButton(
          useIntrinsicWidth: true,
          expandText: false,
          iconPadding: 8,
          leftIcon: FlowySvg(icon),
          onTap: enable ? onTap : null,
          text: FlowyText(
            text,
            fontSize: 15.0,
            figmaLineHeight: 18.0,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
