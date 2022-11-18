import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridFilterBloc, GridFilterState>(
      builder: (context, state) {
        final textColor = state.filters.isEmpty
            ? null
            : Theme.of(context).colorScheme.primary;

        return FlowyTextButton(
          LocaleKeys.grid_settings_filter.tr(),
          fontSize: 14,
          textColor: textColor,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () {},
        );
      },
    );
  }
}
