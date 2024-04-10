import 'package:flutter/material.dart';

import 'package:flowy_infra/theme_extension.dart';

/// This is used to create a uniform space and divider
/// between categories in settings.
///
class SettingsCategorySpacer extends StatelessWidget {
  const SettingsCategorySpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 32,
      color: AFThemeExtension.of(context).toggleOffFill,
    );
  }
}
