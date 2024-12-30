import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

class FlowyTabItem extends StatelessWidget {
  const FlowyTabItem({
    super.key,
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  static const double mobileHeight = 40;
  static const EdgeInsets mobilePadding = EdgeInsets.symmetric(horizontal: 12);

  static const double desktopHeight = 26;
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(horizontal: 8);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: UniversalPlatform.isMobile ? mobileHeight : desktopHeight,
      child: Padding(
        padding: UniversalPlatform.isMobile ? mobilePadding : desktopPadding,
        child: FlowyText.regular(
          label,
          color: isSelected
              ? AFThemeExtension.of(context).textColor
              : Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
