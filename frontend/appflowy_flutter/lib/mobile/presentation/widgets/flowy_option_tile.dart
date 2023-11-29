import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// used in cell editor

class FlowyOptionTile extends StatelessWidget {
  const FlowyOptionTile._({
    this.showTopBorder = true,
    this.showBottomBorder = true,
    this.text,
    this.controller,
    this.leftIcon,
    this.onTap,
    this.leading,
    this.textFieldPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
    ),
  });

  factory FlowyOptionTile.text({
    required String text,
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? leading,
    void Function()? onTap,
  }) {
    return FlowyOptionTile._(
      text: text,
      controller: null,
      onTap: onTap,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leftIcon: leftIcon,
      leading: leading,
    );
  }

  factory FlowyOptionTile.textField({
    required TextEditingController controller,
    EdgeInsets textFieldPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
    ),
    bool showTopBorder = true,
    bool showBottomBorder = true,
    Widget? leftIcon,
    Widget? leading,
  }) {
    return FlowyOptionTile._(
      controller: controller,
      textFieldPadding: textFieldPadding,
      text: null,
      onTap: null,
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      leftIcon: leftIcon,
      leading: leading,
    );
  }

  final bool showTopBorder;
  final bool showBottomBorder;
  final String? text;
  final TextEditingController? controller;
  final EdgeInsets textFieldPadding;
  final void Function()? onTap;
  final Widget? leftIcon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionDecorateBox(
      showTopBorder: showTopBorder,
      showBottomBorder: showBottomBorder,
      child: Row(
        children: [
          if (text != null)
            FlowyButton(
              useIntrinsicWidth: true,
              text: FlowyText(
                text!,
                fontSize: 16.0,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              leftIcon: leftIcon,
              leftIconSize: const Size.square(24.0),
              iconPadding: 8.0,
              onTap: onTap,
            ),
          if (controller != null) ...[
            if (leftIcon != null) leftIcon!,
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(height: 52.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: textFieldPadding,
                  ),
                  onChanged: (value) {},
                  onSubmitted: (value) {},
                ),
              ),
            ),
          ],
          const Spacer(),
          leading ?? const SizedBox.shrink(),
          const HSpace(12.0),
        ],
      ),
    );
  }
}
