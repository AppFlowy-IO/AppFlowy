import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'row_action_sheet.dart';

import 'row_detail.dart';

class GridRowWidget extends StatefulWidget {
  final GridRow rowData;
  final GridRowCache rowCache;
  final GridCellCache cellCache;

  const GridRowWidget({
    required this.rowData,
    required this.rowCache,
    required this.cellCache,
    Key? key,
  }) : super(key: key);

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;

  @override
  void initState() {
    _rowBloc = RowBloc(
      rowData: widget.rowData,
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
          buildWhen: (p, c) => p.rowData.height != c.rowData.height,
          builder: (context, state) {
            final children = [
              const _RowLeading(),
              _RowCells(cellCache: widget.cellCache, onExpand: () => onExpandCell(context)),
              const _RowTrailing(),
            ];

            final child = Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            );

            return SizedBox(height: 42, child: child);
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

  void onExpandCell(BuildContext context) {
    final page = RowDetailPage(
      rowData: widget.rowData,
      rowCache: widget.rowCache,
      cellCache: widget.cellCache,
    );
    page.show(context);
  }
}

class _RowLeading extends StatelessWidget {
  const _RowLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<_RegionStateNotifier>(
      builder: (context, state, _) {
        return SizedBox(width: GridSize.leadingHeaderPadding, child: state.onEnter ? _activeWidget() : null);
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
        rowData: context.read<RowBloc>().state.rowData,
      ).show(context),
      iconPadding: const EdgeInsets.all(3),
      icon: svgWidget("editor/details"),
    );
  }
}

class _RowCells extends StatelessWidget {
  final GridCellCache cellCache;
  final VoidCallback onExpand;
  const _RowCells({required this.cellCache, required this.onExpand, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) => previous.cellDataMap != current.cellDataMap,
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _makeCells(state.cellDataMap),
        );
      },
    );
  }

  List<Widget> _makeCells(CellDataMap cellDataMap) {
    return cellDataMap.values.map(
      (cellData) {
        Widget? expander;
        if (cellData.field.isPrimary) {
          expander = _CellExpander(onExpand: onExpand);
        }

        final cellDataContext = GridCellDataContext(
          cellData: cellData,
          cellCache: cellCache,
        );

        return CellContainer(
          width: cellData.field.width.toDouble(),
          child: buildGridCell(cellDataContext),
          expander: expander,
        );
      },
    ).toList();
  }
}

class _RegionStateNotifier extends ChangeNotifier {
  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}

class _CellExpander extends StatelessWidget {
  final VoidCallback onExpand;
  const _CellExpander({required this.onExpand, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      width: 20,
      onPressed: onExpand,
      iconPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      icon: svgWidget("grid/expander", color: theme.main1),
    );
  }
}

class _RowEnterRegion extends StatefulWidget {
  final Widget child;
  const _RowEnterRegion({required this.child, Key? key}) : super(key: key);

  @override
  State<_RowEnterRegion> createState() => _RowEnterRegionState();
}

class _RowEnterRegionState extends State<_RowEnterRegion> {
  late _RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowStateNotifier = _RegionStateNotifier();
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
