import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// This button style is used in
// - Trash button
// - Template button
class SidebarFooterButton extends StatelessWidget {
  const SidebarFooterButton({
    super.key,
    required this.leftIcon,
    required this.leftIconSize,
    required this.text,
    required this.onTap,
  });

  final Widget leftIcon;
  final Size leftIconSize;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.workspaceSectionHeight,
      child: FlowyButton(
        leftIcon: leftIcon,
        leftIconSize: leftIconSize,
        margin: const EdgeInsets.all(4.0),
        expandText: false,
        text: Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: FlowyText(
            text,
            fontWeight: FontWeight.w400,
            figmaLineHeight: 18.0,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
