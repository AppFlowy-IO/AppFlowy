import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class SelectOptionColorList extends StatelessWidget {
  const SelectOptionColorList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _SelectOptionColorItem extends StatelessWidget {
  final SelectOptionColor option;
  final bool isSelected;
  const _SelectOptionColorItem({required this.option, required this.isSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    Widget? checkmark;
    if (isSelected) {
      checkmark = svg("grid/details", color: theme.iconColor);
    }

    final colorIcon = SizedBox.square(
      dimension: 16,
      child: Container(
        decoration: BoxDecoration(
          color: option.color(context),
          shape: BoxShape.circle,
        ),
      ),
    );

    return FlowyButton(
      text: FlowyText.medium(
        option.name(),
        fontSize: 12,
      ),
      hoverColor: theme.hover,
      leftIcon: colorIcon,
      rightIcon: checkmark,
      onTap: () {},
    );
  }
}

enum SelectOptionColor {
  purple,
  pink,
  lightPink,
  orange,
  yellow,
  lime,
  green,
  aqua,
  blue,
}

extension SelectOptionColorExtension on SelectOptionColor {
  Color color(BuildContext context) {
    final theme = context.watch<AppTheme>();
    switch (this) {
      case SelectOptionColor.purple:
        return theme.tint1;
      case SelectOptionColor.pink:
        return theme.tint2;
      case SelectOptionColor.lightPink:
        return theme.tint3;
      case SelectOptionColor.orange:
        return theme.tint4;
      case SelectOptionColor.yellow:
        return theme.tint5;
      case SelectOptionColor.lime:
        return theme.tint6;
      case SelectOptionColor.green:
        return theme.tint7;
      case SelectOptionColor.aqua:
        return theme.tint8;
      case SelectOptionColor.blue:
        return theme.tint9;
    }
  }

  String name() {
    switch (this) {
      case SelectOptionColor.purple:
        return LocaleKeys.grid_selectOption_purpleColor.tr();
      case SelectOptionColor.pink:
        return LocaleKeys.grid_selectOption_pinkColor.tr();
      case SelectOptionColor.lightPink:
        return LocaleKeys.grid_selectOption_lightPinkColor.tr();
      case SelectOptionColor.orange:
        return LocaleKeys.grid_selectOption_orangeColor.tr();
      case SelectOptionColor.yellow:
        return LocaleKeys.grid_selectOption_yellowColor.tr();
      case SelectOptionColor.lime:
        return LocaleKeys.grid_selectOption_limeColor.tr();
      case SelectOptionColor.green:
        return LocaleKeys.grid_selectOption_greenColor.tr();
      case SelectOptionColor.aqua:
        return LocaleKeys.grid_selectOption_aquaColor.tr();
      case SelectOptionColor.blue:
        return LocaleKeys.grid_selectOption_blueColor.tr();
    }
  }
}
