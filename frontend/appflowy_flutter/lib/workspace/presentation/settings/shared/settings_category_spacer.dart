import 'package:flutter/material.dart';

/// This is used to create a uniform space and divider
/// between categories in settings.
///
class SettingsCategorySpacer extends StatelessWidget {
  const SettingsCategorySpacer({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 32, color: Color(0xFFF2F2F2));
}
