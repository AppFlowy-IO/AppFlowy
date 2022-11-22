import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChoiceChipButton extends StatelessWidget {
  final FilterInfo filterInfo;

  const ChoiceChipButton({
    Key? key,
    required this.filterInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final arrow = Transform.rotate(
      angle: -math.pi / 2,
      child: svgWidget("home/arrow_left"),
    );
    final borderSide = BorderSide(
      color: AFThemeExtension.of(context).toggleOffFill,
      width: 1.0,
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
        text: FlowyText(filterInfo.field.name, fontSize: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        radius: const BorderRadius.all(Radius.circular(14)),
        leftIcon: svgWidget(
          filterInfo.field.fieldType.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
        rightIcon: arrow,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
      ),
    );
  }
}
