import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/mobile_cell_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';

class MobileGridRow extends StatefulWidget {
  const MobileGridRow({
    super.key,
    required this.rowId,
    required this.databaseController,
    required this.openDetailPage,
    this.isDraggable = false,
  });

  final RowId rowId;
  final DatabaseController databaseController;
  final void Function(BuildContext context) openDetailPage;
  final bool isDraggable;

  @override
  State<MobileGridRow> createState() => _MobileGridRowState();
}

class _MobileGridRowState extends State<MobileGridRow> {
  late final RowController _rowController;
  late final EditableCellBuilder _cellBuilder;

  String get viewId => widget.databaseController.viewId;
  RowCache get rowCache => widget.databaseController.rowCache;

  @override
  void initState() {
    super.initState();
    _rowController = RowController(
      rowMeta: rowCache.getRow(widget.rowId)!.rowMeta,
      viewId: viewId,
      rowCache: rowCache,
    );
    _cellBuilder = EditableCellBuilder(
      databaseController: widget.databaseController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RowBloc(
        fieldController: widget.databaseController.fieldController,
        rowId: widget.rowId,
        rowController: _rowController,
        viewId: viewId,
      ),
      child: BlocBuilder<RowBloc, RowState>(
        builder: (context, state) {
          return Row(
            children: [
              SizedBox(width: GridSize.horizontalHeaderPadding),
              Expanded(
                child: RowContent(
                  fieldController: widget.databaseController.fieldController,
                  builder: _cellBuilder,
                  onExpand: () => widget.openDetailPage(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowController.dispose();
    super.dispose();
  }
}

class RowContent extends StatelessWidget {
  const RowContent({
    super.key,
    required this.fieldController,
    required this.onExpand,
    required this.builder,
  });

  final FieldController fieldController;
  final VoidCallback onExpand;
  final EditableCellBuilder builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      builder: (context, state) {
        return SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._makeCells(context, state.cellContexts),
              _finalCellDecoration(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<CellContext> cellContexts,
  ) {
    return cellContexts.map(
      (cellContext) {
        final fieldInfo = fieldController.getField(cellContext.fieldId)!;
        final EditableCellWidget child = builder.buildStyled(
          cellContext,
          EditableCellStyle.mobileGrid,
        );
        return MobileCellContainer(
          isPrimary: fieldInfo.field.isPrimary,
          onPrimaryFieldCellTap: onExpand,
          child: child,
        );
      },
    ).toList();
  }

  Widget _finalCellDecoration(BuildContext context) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(minHeight: 46),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}
