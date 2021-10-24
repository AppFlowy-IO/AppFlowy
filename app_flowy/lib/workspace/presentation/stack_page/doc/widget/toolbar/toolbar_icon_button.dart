import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double defaultIconSize = 18;

class ToolbarIconButton extends StatelessWidget {
  final double width;
  final VoidCallback? onPressed;
  final bool isToggled;
  final String iconName;

  const ToolbarIconButton(
      {Key? key, required this.onPressed, required this.isToggled, required this.width, required this.iconName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      iconPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onPressed: onPressed,
      width: width,
      icon: isToggled == true ? svg(iconName, color: Colors.white) : svg(iconName),
      fillColor: isToggled == true ? theme.main1 : theme.shader6,
      hoverColor: isToggled == true ? theme.main1 : theme.shader5,
    );
  }
}
