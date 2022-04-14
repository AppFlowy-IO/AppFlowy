import 'package:app_flowy/workspace/application/grid/field/field_cell_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_type_extension.dart';

import 'field_cell_action_sheet.dart';
import 'field_editor.dart';

class GridFieldCell extends StatelessWidget {
  final GridFieldCellContext cellContext;
  const GridFieldCell(this.cellContext, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return BlocProvider(
      create: (context) => FieldCellBloc(cellContext: cellContext)..add(const FieldCellEvent.initial()),
      child: BlocBuilder<FieldCellBloc, FieldCellState>(
        builder: (context, state) {
          final button = FlowyButton(
            hoverColor: theme.shader6,
            onTap: () => _showActionSheet(context),
            // rightIcon: svgWidget("editor/details", color: theme.iconColor),
            leftIcon: svgWidget(state.field.fieldType.iconName(), color: theme.iconColor),
            text: FlowyText.medium(state.field.name, fontSize: 12),
            padding: GridSize.cellContentInsets,
          );

          final line = InkWell(
            onTap: () {},
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragCancel: () {},
              onHorizontalDragUpdate: (value) {
                context.read<FieldCellBloc>().add(FieldCellEvent.updateWidth(value.delta.dx));
              },
              child: FlowyHover(
                style: HoverStyle(
                  hoverColor: theme.main1,
                  borderRadius: BorderRadius.zero,
                  contentMargin: const EdgeInsets.only(left: 5),
                ),
                builder: (_, onHover) => const SizedBox(width: 2),
              ),
            ),
          );

          final borderSide = BorderSide(color: theme.shader4, width: 0.4);
          final decoration = BoxDecoration(
              border: Border(
            top: borderSide,
            right: borderSide,
            bottom: borderSide,
          ));

          return Container(
            width: state.field.width.toDouble(),
            decoration: decoration,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: Stack(
                alignment: Alignment.centerRight,
                fit: StackFit.expand,
                children: [button, Positioned(top: 0, bottom: 0, right: 0, child: line)],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    final state = context.read<FieldCellBloc>().state;
    GridFieldCellActionSheet(
      cellContext: GridFieldCellContext(gridId: state.gridId, field: state.field),
      onEdited: () => _showFieldEditor(context),
    ).show(context);
  }

  void _showFieldEditor(BuildContext context) {
    final state = context.read<FieldCellBloc>().state;

    FieldEditor(
      gridId: state.gridId,
      fieldContextLoader: FieldContextLoaderAdaptor(
        gridId: state.gridId,
        field: state.field,
      ),
    ).show(context);
  }
}
