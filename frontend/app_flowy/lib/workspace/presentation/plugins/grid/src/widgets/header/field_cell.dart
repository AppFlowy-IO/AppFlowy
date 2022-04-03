import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_type_extension.dart';

import 'field_cell_action_sheet.dart';
import 'field_editor.dart';

class GridFieldCell extends StatelessWidget {
  final GridFieldCellContext fieldCellContext;
  const GridFieldCell(this.fieldCellContext, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final field = fieldCellContext.field;

    final button = FlowyButton(
      hoverColor: theme.hover,
      onTap: () => _showActionSheet(context),
      rightIcon: svgWidget("editor/details", color: theme.iconColor),
      leftIcon: svgWidget(field.fieldType.iconName(), color: theme.iconColor),
      text: FlowyText.medium(field.name, fontSize: 12),
      padding: GridSize.cellContentInsets,
    );

    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    final decoration = BoxDecoration(border: Border(top: borderSide, right: borderSide, bottom: borderSide));

    return Container(
      width: field.width.toDouble(),
      decoration: decoration,
      child: button,
    );
  }

  void _showActionSheet(BuildContext context) {
    GridFieldCellActionSheet(
      fieldCellContext: fieldCellContext,
      onEdited: () => _showFieldEditor(context),
    ).show(context);
  }

  void _showFieldEditor(BuildContext context) {
    FieldEditor(
      gridId: fieldCellContext.gridId,
      fieldContextLoader: FieldContextLoaderAdaptor(fieldCellContext),
    ).show(context);
  }
}
