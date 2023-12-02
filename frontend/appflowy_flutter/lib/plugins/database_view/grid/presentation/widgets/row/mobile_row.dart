import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/mobile_cell_container.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';
import "package:appflowy/generated/locale_keys.g.dart";
import 'package:easy_localization/easy_localization.dart';

class MobileGridRow extends StatefulWidget {
  final DatabaseController databaseController;
  final RowId rowId;
  final void Function(BuildContext context) openDetailPage;
  final bool isDraggable;

  const MobileGridRow({
    super.key,
    required this.rowId,
    required this.databaseController,
    required this.openDetailPage,
    this.isDraggable = false,
  });

  @override
  State<MobileGridRow> createState() => _MobileGridRowState();
}

class _MobileGridRowState extends State<MobileGridRow> {
  late final RowBloc _rowBloc;
  late final RowController _rowController;
  late final GridCellBuilder _cellBuilder;

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
    _rowBloc = RowBloc(
      rowId: widget.rowId,
      dataController: _rowController,
      viewId: viewId,
    )..add(const RowEvent.initial());
    _cellBuilder = GridCellBuilder(cellCache: rowCache.cellCache);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: BlocBuilder<RowBloc, RowState>(
        // The row need to rebuild when the cell count changes.
        buildWhen: (p, c) => p.rowSource != c.rowSource,
        builder: (context, state) {
          return Row(
            children: [
              SizedBox(width: GridSize.leadingHeaderPadding),
              Expanded(
                child: RowContent(
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
    _rowBloc.close();
    _rowController.dispose();
    super.dispose();
  }
}

class InsertRowButton extends StatelessWidget {
  const InsertRowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      tooltipText: LocaleKeys.tooltip_addNewRow.tr(),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      width: 20,
      height: 30,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: FlowySvg(
        FlowySvgs.add_s,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class RowContent extends StatelessWidget {
  final VoidCallback onExpand;
  final GridCellBuilder builder;
  const RowContent({
    super.key,
    required this.builder,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) =>
          !listEquals(previous.cells, current.cells),
      builder: (context, state) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._makeCells(context, state.cellByFieldId),
              _finalCellDecoration(context),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    CellContextByFieldId cellByFieldId,
  ) {
    return cellByFieldId.values.map(
      (cellId) {
        final GridCellWidget child = builder.build(cellId);

        return MobileCellContainer(
          width: cellId.fieldInfo.fieldSettings?.width.toDouble() ?? 140,
          isPrimary: cellId.fieldInfo.field.isPrimary,
          accessoryBuilder: (buildContext) {
            final builder = child.accessoryBuilder;
            final List<GridCellAccessoryBuilder> accessories = [];
            if (cellId.fieldInfo.field.isPrimary) {
              accessories.add(
                GridCellAccessoryBuilder(
                  builder: (key) => PrimaryCellAccessory(
                    key: key,
                    onTapCallback: onExpand,
                    isCellEditing: buildContext.isCellEditing,
                  ),
                ),
              );
            }

            if (builder != null) {
              accessories.addAll(builder(buildContext));
            }

            return accessories;
          },
          child: child,
        );
      },
    ).toList();
  }

  Widget _finalCellDecoration(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Container(
        width: GridSize.trailHeaderPadding,
        padding: GridSize.headerContentInsets,
        constraints: const BoxConstraints(minHeight: 46),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
      ),
    );
  }
}
