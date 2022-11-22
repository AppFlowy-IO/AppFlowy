import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChoiceChipButton extends StatelessWidget {
  final Widget icon;
  final String name;

  const ChoiceChipButton({
    Key? key,
    required this.icon,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );
    return Row(
      children: [
        icon,
        FlowyText(name, fontSize: 12),
        arrow,
      ],
    );
  }
}
