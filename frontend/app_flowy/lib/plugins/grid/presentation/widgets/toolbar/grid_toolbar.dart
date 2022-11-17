import 'package:flutter/material.dart';

import '../../../application/field/field_controller.dart';
import '../../layout/sizes.dart';
import 'filter_button.dart';
import 'grid_setting.dart';
import 'setting_button.dart';

class GridToolbarContext {
  final String gridId;
  final GridFieldController fieldController;
  GridToolbarContext({
    required this.gridId,
    required this.fieldController,
  });
}

class GridToolbar extends StatelessWidget {
  final GridToolbarContext toolbarContext;
  const GridToolbar({required this.toolbarContext, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingContext = GridSettingContext(
      gridId: toolbarContext.gridId,
      fieldController: toolbarContext.fieldController,
    );
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(width: GridSize.leadingHeaderPadding),
          SettingButton(settingContext: settingContext),
          const Spacer(),
          FilterButton(),
        ],
      ),
    );
  }
}
