import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

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

  String optionName() {
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
  final String name;
  final Color color;
  final VoidCallback? onSelected;
  final void Function(String)? onRemove;
  const SelectOptionTag({
    required this.name,
    required this.color,
    this.onSelected,
    this.onRemove,
    Key? key,
  }) : super(key: key);

  factory SelectOptionTag.fromOption({
    required BuildContext context,
    required SelectOptionPB option,
    VoidCallback? onSelected,
    Function(String)? onRemove,
  }) {
    return SelectOptionTag(
      name: option.name,
      color: option.color.toColor(context),
      onSelected: onSelected,
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding =
        const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0);
    if (onRemove != null) {
      padding = padding.copyWith(right: 2.0);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: Corners.s6Border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FlowyText.medium(
              name,
              overflow: TextOverflow.ellipsis,
              color: AFThemeExtension.of(context).textColor,
            ),
          ),
          if (onRemove != null) ...[
            const HSpace(2),
            FlowyIconButton(
              width: 18.0,
              onPressed: () => onRemove?.call(name),
              hoverColor: Colors.transparent,
              icon: const FlowySvg(
                FlowySvgs.close_s,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class SelectOptionTagCell extends StatelessWidget {
  final List<Widget> children;
  final void Function(SelectOptionPB) onSelected;
  final SelectOptionPB option;
  const SelectOptionTagCell({
    required this.option,
    required this.onSelected,
    this.children = const [],
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      style: HoverStyle(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
      ),
      child: InkWell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: SelectOptionTag.fromOption(
                    context: context,
                    option: option,
                    onSelected: () => onSelected(option),
                  ),
                ),
              ),
            ),
            ...children,
          ],
        ),
        // TODO(richard): find alternative solution to onTapDown
        onTapDown: (_) => onSelected(option),
      ),
    );
  }
}
