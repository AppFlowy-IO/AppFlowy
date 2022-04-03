import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectionBadge extends StatelessWidget {
  final SelectOption option;
  const SelectionBadge({required this.option, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: option.color.make(context),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: FlowyText.medium(option.name, fontSize: 12),
    );
  }
}

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
