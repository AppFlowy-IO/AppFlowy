import 'package:app_flowy/workspace/application/grid/field/field_cell_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/log.dart';
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
            leftIcon: svgWidget(state.field.fieldType.iconName(), color: theme.iconColor),
            text: FlowyText.medium(state.field.name, fontSize: 12),
            padding: GridSize.cellContentInsets,
          );

          const line = Positioned(top: 0, bottom: 0, right: 0, child: _DragToExpandLine());

          return _CellContainer(
            width: state.field.width.toDouble(),
            child: Stack(
              alignment: Alignment.centerRight,
              fit: StackFit.expand,
              children: [button, line],
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

class _CellContainer extends StatelessWidget {
  final Widget child;
  final double width;
  const _CellContainer({
    required this.child,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader4, width: 0.4);
    final decoration = BoxDecoration(
        border: Border(
      top: borderSide,
      right: borderSide,
      bottom: borderSide,
    ));

    return Container(
      width: width,
      decoration: decoration,
      child: ConstrainedBox(constraints: const BoxConstraints.expand(), child: child),
    );
  }
}

class _DragToExpandLine extends StatelessWidget {
  const _DragToExpandLine({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return InkWell(
      onTap: () {},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragCancel: () {},
        onHorizontalDragUpdate: (value) {
          // context.read<FieldCellBloc>().add(FieldCellEvent.updateWidth(value.delta.dx));
          Log.info(value);
        },
        onHorizontalDragEnd: (end) {
          Log.info(end);
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
  }
}
