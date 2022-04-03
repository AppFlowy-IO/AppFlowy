import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'grid_setting.dart';

class GridToolbar extends StatelessWidget {
  final String gridId;
  const GridToolbar({required this.gridId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(width: GridSize.leadingHeaderPadding),
          _SettingButton(settingContext: GridSettingContext(gridId: gridId)),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SettingButton extends StatelessWidget {
  final GridSettingContext settingContext;
  const _SettingButton({required this.settingContext, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 22,
      onPressed: () => GridSettingList(settingContext: settingContext).show(context),
      icon: svgWidget("grid/setting/setting").padding(horizontal: 3, vertical: 3),
    );
  }
}
