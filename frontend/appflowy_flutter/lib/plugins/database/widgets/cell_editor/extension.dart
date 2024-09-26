import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

extension SelectOptionColorExtension on SelectOptionColorPB {
  Color toColor(BuildContext context) {
    switch (this) {
      case SelectOptionColorPB.Purple:
        return AFThemeExtension.of(context).tint1;
      case SelectOptionColorPB.Pink:
        return AFThemeExtension.of(context).tint2;
      case SelectOptionColorPB.LightPink:
        return AFThemeExtension.of(context).tint3;
      case SelectOptionColorPB.Orange:
        return AFThemeExtension.of(context).tint4;
      case SelectOptionColorPB.Yellow:
        return AFThemeExtension.of(context).tint5;
      case SelectOptionColorPB.Lime:
        return AFThemeExtension.of(context).tint6;
      case SelectOptionColorPB.Green:
        return AFThemeExtension.of(context).tint7;
      case SelectOptionColorPB.Aqua:
        return AFThemeExtension.of(context).tint8;
      case SelectOptionColorPB.Blue:
        return AFThemeExtension.of(context).tint9;
      default:
        throw ArgumentError;
    }
  }

  String colorName() {
    switch (this) {
      case SelectOptionColorPB.Purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColorPB.Pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColorPB.LightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColorPB.Orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColorPB.Yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColorPB.Lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColorPB.Green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColorPB.Aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColorPB.Blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
      default:
        throw ArgumentError;
    }
  }
}

class SelectOptionTag extends StatelessWidget {
  const SelectOptionTag({
    super.key,
    this.option,
    this.name,
    this.fontSize,
    this.color,
    this.textStyle,
    this.onRemove,
    this.textAlign,
    this.isExpanded = false,
    this.borderRadius,
    required this.padding,
  }) : assert(option != null || name != null && color != null);

  final SelectOptionPB? option;
  final String? name;
  final double? fontSize;
  final Color? color;
  final TextStyle? textStyle;
  final void Function(String)? onRemove;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final TextAlign? textAlign;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final optionName = option?.name ?? name!;
    final optionColor = option?.color.toColor(context) ?? color!;
    final text = FlowyText.medium(
      optionName,
      fontSize: fontSize,
      overflow: TextOverflow.ellipsis,
      color: AFThemeExtension.of(context).textColor,
      textAlign: textAlign,
    );

    return Container(
      padding: onRemove == null ? padding : padding.copyWith(right: 2.0),
      decoration: BoxDecoration(
        color: optionColor,
        borderRadius: borderRadius ??
            BorderRadius.circular(UniversalPlatform.isDesktopOrWeb ? 6 : 11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isExpanded ? Expanded(child: text) : Flexible(child: text),
          if (onRemove != null) ...[
            const HSpace(4),
            FlowyIconButton(
              width: 16.0,
              onPressed: () => onRemove?.call(optionName),
              hoverColor: Colors.transparent,
              icon: const FlowySvg(FlowySvgs.close_s),
            ),
          ],
        ],
      ),
    );
  }
}
