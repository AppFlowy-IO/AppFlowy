import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class FlowyDivider extends StatelessWidget {
  const FlowyDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1.0,
      thickness: 1.0,
      color: AFThemeExtension.of(context).borderColor,
    );
  }
}
