import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

class FlowyDivider extends StatelessWidget {
  const FlowyDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).isLightMode
        ? const Color(0x141F2329)
        : const Color(0x14FFFFFF);
    return Divider(
      height: 1.0,
      thickness: 1.0,
      color: color,
    );
  }
}
