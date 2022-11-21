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
          const SettingButton(),
          const Spacer(),
          FilterButton(),
        ],
      ),
    );
  }
}
