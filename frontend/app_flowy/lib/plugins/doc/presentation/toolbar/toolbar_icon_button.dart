import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return FlowyIconButton(
      iconPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onPressed: onPressed,
      width: width,
      icon: isToggled == true
          ? svgWidget(iconName, color: Colors.white)
          : svgWidget(iconName, color: theme.iconColor),
      fillColor: isToggled == true ? theme.main1 : theme.shader6,
      hoverColor: isToggled == true ? theme.main1 : theme.hover,
      tooltipText: tooltipText,
    );
  }
}
