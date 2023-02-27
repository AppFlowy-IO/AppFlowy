import 'dart:math' as math;
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class ConditionButton extends StatelessWidget {
  final String conditionName;
  final VoidCallback onTap;
  const ConditionButton({
    required this.conditionName,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );

    return SizedBox(
      height: 20,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText(conditionName, fontSize: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        radius: const BorderRadius.all(Radius.circular(2)),
        rightIcon: arrow,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: onTap,
      ),
    );
  }
}
