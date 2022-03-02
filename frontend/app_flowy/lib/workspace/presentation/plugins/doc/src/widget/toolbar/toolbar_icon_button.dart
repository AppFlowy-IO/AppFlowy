import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

const double defaultIconSize = 18;

class ToolbarIconButton extends StatelessWidget {
  final double width;
  final VoidCallback? onPressed;
  final bool isToggled;
  final String iconName;
  final String tooltipText;

  const ToolbarIconButton({
    Key? key,
    required this.onPressed,
    required this.isToggled,
    required this.width,
    required this.iconName,
    required this.tooltipText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      iconPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onPressed: onPressed,
      width: width,
      icon: svg(iconName, color: isToggled ? Theme.of(context).iconTheme.color : Theme.of(context).disabledColor),
      fillColor: isToggled == true ? Theme.of(context).primaryColor : Colors.grey.shade600,
      hoverColor: isToggled == true ? Colors.grey.shade500 : Theme.of(context).hoverColor,
    );
  }
}
