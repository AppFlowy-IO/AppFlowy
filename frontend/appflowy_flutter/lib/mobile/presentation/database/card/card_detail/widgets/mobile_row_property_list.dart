import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileRowPropertyList extends StatelessWidget {
  const MobileRowPropertyList({
    super.key,
    required this.databaseController,
    required this.cellBuilder,
  });

  final DatabaseController databaseController;
  final EditableCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowDetailBloc, RowDetailState>(
      builder: (context, state) {
        final List<CellContext> visibleCells =
            state.visibleCells.where((cell) => !_isCellPrimary(cell)).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleCells.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) => _PropertyCell(
            key: ValueKey('row_detail_${visibleCells[index].fieldId}'),
            cellContext: visibleCells[index],
            fieldController: databaseController.fieldController,
            cellBuilder: cellBuilder,
          ),
          separatorBuilder: (_, __) => const VSpace(22),
        );
      },
    );
  }

  bool _isCellPrimary(CellContext cell) =>
      databaseController.fieldController.getField(cell.fieldId)!.isPrimary;
}

class _PropertyCell extends StatefulWidget {
  const _PropertyCell({
    super.key,
    required this.cellContext,
    required this.fieldController,
    required this.cellBuilder,
  });

  final CellContext cellContext;
  final FieldController fieldController;
  final EditableCellBuilder cellBuilder;

  @override
  State<StatefulWidget> createState() => _PropertyCellState();
}

class _PropertyCellState extends State<_PropertyCell> {
  @override
  Widget build(BuildContext context) {
    final fieldInfo =
        widget.fieldController.getField(widget.cellContext.fieldId)!;
    final cell = widget.cellBuilder
        .buildStyled(widget.cellContext, EditableCellStyle.mobileRowDetail);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            FieldIcon(
              fieldInfo: fieldInfo,
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText.regular(
                fieldInfo.name,
                overflow: TextOverflow.ellipsis,
                fontSize: 14,
                figmaLineHeight: 16.0,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const VSpace(6),
        cell,
      ],
    );
  }
}
