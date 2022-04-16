import 'package:app_flowy/startup/startup.dart';
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

class GridRowWidget extends StatefulWidget {
  final RowBloc Function() blocBuilder;

  const GridRowWidget({
    required this.blocBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;
  late _RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowBloc = widget.blocBuilder();
    _rowBloc.add(const RowEvent.initial());
    _rowStateNotifier = _RegionStateNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: ChangeNotifierProvider.value(
        value: _rowStateNotifier,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) => _rowStateNotifier.onEnter = true,
          onExit: (p) => _rowStateNotifier.onEnter = false,
          child: BlocBuilder<RowBloc, RowState>(
            buildWhen: (p, c) => p.rowData.height != c.rowData.height,
            builder: (context, state) {
              return SizedBox(
                height: 42,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    _RowLeading(),
                    _RowCells(),
                    _RowTrailing(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowBloc.close();
    _rowStateNotifier.dispose();
    super.dispose();
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
  const _RowCells({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) => previous.cellDataMap != current.cellDataMap,
      builder: (context, state) {
        final List<Widget> children = state.cellDataMap.fold(() => [], _toCells);
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        );
      },
    );
  }

  List<Widget> _toCells(CellDataMap dataMap) {
    return dataMap.values.map(
      (cellData) {
        return CellContainer(
          width: cellData.field.width.toDouble(),
          child: buildGridCell(cellData),
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
