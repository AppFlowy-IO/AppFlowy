import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:flowy_infra/theme_extension.dart';

import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    final borderSide = BorderSide(
      color: AFThemeExtension.of(context).toggleOffFill,
    );

    final decoration = BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
    );

    return SizedBox(
      height: 28,
      child: FlowyButton(
        decoration: decoration,
        useIntrinsicWidth: true,
        text: FlowyText(
          filterInfo.fieldInfo.field.name,
          color: AFThemeExtension.of(context).textColor,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        radius: const BorderRadius.all(Radius.circular(14)),
        leftIcon: FlowySvg(
          filterInfo.fieldInfo.fieldType.svgData,
          color: Theme.of(context).iconTheme.color,
        ),
        rightIcon: _ChoicechipFilterDesc(filterDesc: filterDesc),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: onTap,
      ),
    );
  }
}

class _ChoicechipFilterDesc extends StatelessWidget {
  const _ChoicechipFilterDesc({this.filterDesc = ''});

  final String filterDesc;

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: FlowySvg(
        FlowySvgs.arrow_left_s,
        color: AFThemeExtension.of(context).textColor,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          if (filterDesc.isNotEmpty) FlowyText(': $filterDesc'),
          arrow,
        ],
      ),
    );
  }
}
