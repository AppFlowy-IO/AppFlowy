import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../layout/sizes.dart';
import '../cell/cell_accessory.dart';
import '../cell/cell_cotainer.dart';
import '../cell/prelude.dart';
import 'row_action_sheet.dart';
import 'row_detail.dart';

class GridRowWidget extends StatefulWidget {
  final GridRowInfo rowData;
  final GridRowCache rowCache;
  final GridCellBuilder cellBuilder;

  GridRowWidget({
    required this.rowData,
    required this.rowCache,
    required GridFieldCache fieldCache,
    Key? key,
  })  : cellBuilder = GridCellBuilder(
          cellCache: rowCache.cellCache,
          fieldCache: fieldCache,
        ),
        super(key: key);

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;

  @override
  void initState() {
    _rowBloc = RowBloc(
      rowInfo: widget.rowData,
      rowCache: widget.rowCache,
    );
    _rowBloc.add(const RowEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: _RowEnterRegion(
        child: BlocBuilder<RowBloc, RowState>(
          buildWhen: (p, c) => p.rowInfo.height != c.rowInfo.height,
          builder: (context, state) {
            return Row(
              children: [
                const _RowLeading(),
                Expanded(
                    child: _RowCells(
                  builder: widget.cellBuilder,
                  onExpand: () => _expandRow(context),
                )),
                const _RowTrailing(),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowBloc.close();
    super.dispose();
  }

  void _expandRow(BuildContext context) {
    final page = RowDetailPage(
      rowInfo: widget.rowData,
      rowCache: widget.rowCache,
      cellBuilder: widget.cellBuilder,
    );
    page.show(context);
  }
}

class _RowLeading extends StatelessWidget {
  const _RowLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RegionStateNotifier>(
      builder: (context, state, _) {
        return SizedBox(
            width: GridSize.leadingHeaderPadding,
            child: state.onEnter ? _activeWidget() : null);
      },
    );
  }

  Widget _activeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _InsertRowButton(),
        _DeleteRowButton(),
      ],
    );
  }
}

class _RowTrailing extends StatelessWidget {
  const _RowTrailing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class _InsertRowButton extends StatelessWidget {
  const _InsertRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 20,
      height: 30,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget("home/add"),
    );
  }
}

class _DeleteRowButton extends StatelessWidget {
  const _DeleteRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 20,
      height: 30,
      onPressed: () => GridRowActionSheet(
        rowData: context.read<RowBloc>().state.rowInfo,
      ).show(context),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget("editor/details"),
    );
  }
}

class _RowCells extends StatelessWidget {
  final VoidCallback onExpand;
  final GridCellBuilder builder;
  const _RowCells({
    required this.builder,
    required this.onExpand,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) =>
          !listEquals(previous.snapshots, current.snapshots),
      builder: (context, state) {
        return IntrinsicHeight(
            child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _makeCells(context, state.gridCellMap),
        ));
      },
    );
  }

  List<Widget> _makeCells(BuildContext context, GridCellMap gridCellMap) {
    return gridCellMap.values.map(
      (cellId) {
        final GridCellWidget child = builder.build(cellId);
        accessoryBuilder(GridCellAccessoryBuildContext buildContext) {
          final builder = child.accessoryBuilder;
          List<GridCellAccessory> accessories = [];
          if (cellId.field.isPrimary) {
            accessories.add(PrimaryCellAccessory(
              onTapCallback: onExpand,
              isCellEditing: buildContext.isCellEditing,
            ));
          }

          if (builder != null) {
            accessories.addAll(builder(buildContext));
          }
          return accessories;
        }

        return CellContainer(
          width: cellId.field.width.toDouble(),
          child: child,
          rowStateNotifier:
              Provider.of<RegionStateNotifier>(context, listen: false),
          accessoryBuilder: accessoryBuilder,
        );
      },
    ).toList();
  }
}

class RegionStateNotifier extends ChangeNotifier {
  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}

class _RowEnterRegion extends StatefulWidget {
  final Widget child;
  const _RowEnterRegion({required this.child, Key? key}) : super(key: key);

  @override
  State<_RowEnterRegion> createState() => _RowEnterRegionState();
}

class _RowEnterRegionState extends State<_RowEnterRegion> {
  late RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowStateNotifier = RegionStateNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _rowStateNotifier,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (p) => _rowStateNotifier.onEnter = true,
        onExit: (p) => _rowStateNotifier.onEnter = false,
        child: widget.child,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowStateNotifier.dispose();
    super.dispose();
  }
}
