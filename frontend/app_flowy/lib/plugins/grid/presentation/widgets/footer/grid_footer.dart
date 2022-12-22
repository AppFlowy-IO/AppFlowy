import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridAddRowButton extends StatelessWidget {
  const GridAddRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText.medium(LocaleKeys.grid_row_newRow.tr()),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onTap: () => context.read<GridBloc>().add(const GridEvent.createRow()),
      leftIcon: svgWidget(
        "home/add",
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
