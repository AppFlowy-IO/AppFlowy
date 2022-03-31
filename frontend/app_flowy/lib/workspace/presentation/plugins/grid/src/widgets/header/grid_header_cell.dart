import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_detail_pannel.dart';

class GridHeaderCell extends StatelessWidget {
  final GridFieldData fieldData;
  const GridHeaderCell(this.fieldData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final button = FlowyButton(
      hoverColor: theme.hover,
      onTap: () => FieldDetailPannel.show(context, fieldData),
      rightIcon: svg("editor/details", color: theme.iconColor),
      text: Padding(padding: GridSize.cellContentInsets, child: FlowyText.medium(fieldData.field.name, fontSize: 12)),
    );

    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    final decoration = BoxDecoration(border: Border(top: borderSide, right: borderSide, bottom: borderSide));

    return Container(
      width: fieldData.field.width.toDouble(),
      decoration: decoration,
      padding: GridSize.headerContentInsets,
      child: button,
    );
  }
}
