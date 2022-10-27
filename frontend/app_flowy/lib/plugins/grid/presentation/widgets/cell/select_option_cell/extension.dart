import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension SelectOptionColorExtension on SelectOptionColorPB {
  Color make(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    switch (this) {
      case SelectOptionColorPB.Purple:
        return theme.tint1;
      case SelectOptionColorPB.Pink:
        return theme.tint2;
      case SelectOptionColorPB.LightPink:
        return theme.tint3;
      case SelectOptionColorPB.Orange:
        return theme.tint4;
      case SelectOptionColorPB.Yellow:
        return theme.tint5;
      case SelectOptionColorPB.Lime:
        return theme.tint6;
      case SelectOptionColorPB.Green:
        return theme.tint7;
      case SelectOptionColorPB.Aqua:
        return theme.tint8;
      case SelectOptionColorPB.Blue:
        return theme.tint9;
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
  final bool isSelected;
  final VoidCallback? onSelected;
  const SelectOptionTag({
    required this.name,
    required this.color,
    this.onSelected,
    this.isSelected = false,
    Key? key,
  }) : super(key: key);

  factory SelectOptionTag.fromOption({
    required BuildContext context,
    required SelectOptionPB option,
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
      label: FlowyText.medium(
        name,
        fontSize: 12,
        overflow: TextOverflow.clip,
      ),
      selectedColor: color,
      backgroundColor: color,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      selected: true,
      onSelected: (_) => onSelected?.call(),
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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
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
                  SelectOptionTag.fromOption(
                    context: context,
                    option: option,
                    onSelected: () => onSelected(option),
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
