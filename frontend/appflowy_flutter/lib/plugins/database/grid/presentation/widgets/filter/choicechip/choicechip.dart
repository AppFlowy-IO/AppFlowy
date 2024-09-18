import 'dart:math' as math;

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import '../filter_info.dart';

class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    super.key,
    required this.filterInfo,
    this.filterDesc = '',
    this.onTap,
  });

  final FilterInfo filterInfo;
  final String filterDesc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final buttonText = filterDesc.isEmpty
        ? filterInfo.fieldInfo.field.name
        : "${filterInfo.fieldInfo.field.name}: $filterDesc";

    return SizedBox(
      height: 28,
      child: FlowyButton(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.fromBorderSide(
            BorderSide(
              color: AFThemeExtension.of(context).toggleOffFill,
            ),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        useIntrinsicWidth: true,
        text: FlowyText(
          buttonText,
          lineHeight: 1.0,
          color: AFThemeExtension.of(context).textColor,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        radius: const BorderRadius.all(Radius.circular(14)),
        leftIcon: FlowySvg(
          filterInfo.fieldInfo.fieldType.svgData,
          color: Theme.of(context).iconTheme.color,
        ),
        rightIcon: const _ChoicechipDownArrow(),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: onTap,
      ),
    );
  }
}

class _ChoicechipDownArrow extends StatelessWidget {
  const _ChoicechipDownArrow();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 2,
      child: FlowySvg(
        FlowySvgs.arrow_left_s,
        color: AFThemeExtension.of(context).textColor,
      ),
    );
  }
}
