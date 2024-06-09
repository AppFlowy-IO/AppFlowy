import 'dart:math' as math;
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/theme_extension.dart';

import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class ConditionButton extends StatelessWidget {
  const ConditionButton({
    super.key,
    required this.conditionName,
    required this.onTap,
  });

  final String conditionName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: FlowySvg(
        FlowySvgs.arrow_left_s,
        color: AFThemeExtension.of(context).textColor,
      ),
    );

    return SizedBox(
      height: 20,
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText(
          conditionName,
          fontSize: 10,
          color: AFThemeExtension.of(context).textColor,
          overflow: TextOverflow.ellipsis,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        radius: const BorderRadius.all(Radius.circular(2)),
        rightIcon: arrow,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: onTap,
      ),
    );
  }
}
