import 'package:app_flowy/plugins/grid/presentation/widgets/toolbar/sort_button.dart';
import 'package:flutter/material.dart';

import '../../../application/field/field_controller.dart';
import '../../layout/sizes.dart';
import 'filter_button.dart';
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
  const GridToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: GridSize.leadingHeaderPadding),
          const Spacer(),
          const FilterButton(),
          const SortButton(),
          const SettingButton(),
        ],
      ),
    );
  }
}
