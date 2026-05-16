import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class FlowyDivider extends StatelessWidget {
  const FlowyDivider({
    super.key,
    this.padding,
  });

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Divider(
        height: 1.0,
        thickness: 1.0,
        color: AFThemeExtension.of(context).borderColor,
      ),
    );
  }
}
