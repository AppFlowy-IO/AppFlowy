import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/mobile_cell_container.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
      rowController: _rowController,
      viewId: viewId,
    )..add(const RowEvent.initial());
    _cellBuilder = GridCellBuilder(cellCache: rowCache.cellCache);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: BlocBuilder<RowBloc, RowState>(
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
      builder: (context, state) {
        return SizedBox(
          height: 52,
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
          isPrimary: cellId.fieldInfo.field.isPrimary,
          onPrimaryFieldCellTap: onExpand,
          child: child,
        );
      },
    ).toList();
  }

  Widget _finalCellDecoration(BuildContext context) {
    return Container(
      width: 200,
      padding: GridSize.headerContentInsets,
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
