import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension SelectOptionColorExtension on SelectOptionColor {
  Color make(BuildContext context) {
    final theme = context.watch<AppTheme>();
    switch (this) {
      case SelectOptionColor.Purple:
        return theme.tint1;
      case SelectOptionColor.Pink:
        return theme.tint2;
      case SelectOptionColor.LightPink:
        return theme.tint3;
      case SelectOptionColor.Orange:
        return theme.tint4;
      case SelectOptionColor.Yellow:
        return theme.tint5;
      case SelectOptionColor.Lime:
        return theme.tint6;
      case SelectOptionColor.Green:
        return theme.tint7;
      case SelectOptionColor.Aqua:
        return theme.tint8;
      case SelectOptionColor.Blue:
        return theme.tint9;
      default:
        throw ArgumentError;
    }
  }

  String optionName() {
    switch (this) {
      case SelectOptionColor.Purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColor.Pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColor.LightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColor.Orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColor.Yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColor.Lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColor.Green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColor.Aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColor.Blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
      default:
        throw ArgumentError;
    }
  }
}

class SelectOptionTag extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback? onSelected;
  const SelectOptionTag({
    required this.name,
    required this.color,
    this.onSelected,
    this.isSelected = false,
    Key? key,
  }) : super(key: key);

  factory SelectOptionTag.fromSelectOption({
    required BuildContext context,
    required SelectOption option,
    VoidCallback? onSelected,
    bool isSelected = false,
  }) {
    return SelectOptionTag(
      name: option.name,
      color: option.color.make(context),
      isSelected: isSelected,
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      pressElevation: 1,
      label: FlowyText.medium(name, fontSize: 12, overflow: TextOverflow.ellipsis),
      selectedColor: color,
      backgroundColor: color,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      selected: true,
      onSelected: (_) {
        if (onSelected != null) {
          onSelected!();
        }
      },
    );
  }
}

class SelectOptionTagCell extends StatelessWidget {
  final List<Widget> children;
  final void Function(SelectOption) onSelected;
  final SelectOption option;
  const SelectOptionTagCell({
    required this.option,
    required this.onSelected,
    this.children = const [],
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Stack(
      fit: StackFit.expand,
      children: [
        FlowyHover(
          style: HoverStyle(hoverColor: theme.hover),
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    flex: 2,
                    child: SelectOptionTag.fromSelectOption(
                      context: context,
                      option: option,
                      onSelected: () => onSelected(option),
                    ),
                  ),
                  const Spacer(),
                  ...children,
                ],
              ),
            ),
            onTap: () => onSelected(option),
          ),
        ),
      ],
    );
  }
}
