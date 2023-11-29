import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// used in cell editor
class FlowyOptionTile extends StatelessWidget {
  const FlowyOptionTile({
    super.key,
    this.showTopBorder = true,
    this.showBottomBorder = true,
    required this.text,
    required this.leftIcon,
    this.onTap,
  });

  final bool showTopBorder;
  final bool showBottomBorder;
  final String text;
  final Widget leftIcon;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionDecorateBox(
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      child: FlowyButton(
        text: FlowyText(
          text,
          fontSize: 16.0,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 16.0,
        ),
        leftIcon: leftIcon,
        leftIconSize: const Size.square(24.0),
        iconPadding: 8.0,
        onTap: onTap,
      ),
    );
  }
}
