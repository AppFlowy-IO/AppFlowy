import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cell_builder.dart';
import 'cell_container.dart';

class GridRowWidget extends StatefulWidget {
  final GridRowData data;
  GridRowWidget({required this.data, Key? key}) : super(key: ValueKey(data.rowId));

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;

  @override
  void initState() {
    _rowBloc = getIt<RowBloc>(param1: widget.data)..add(const RowEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (p) => _rowBloc.add(const RowEvent.activeRow()),
        onExit: (p) => _rowBloc.add(const RowEvent.disactiveRow()),
        child: BlocBuilder<RowBloc, RowState>(
          buildWhen: (p, c) => p.rowHeight != c.rowHeight,
          builder: (context, state) {
            return SizedBox(
              height: _rowBloc.state.rowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
    );
  }

  @override
  Future<void> dispose() async {
    _rowBloc.close();
    super.dispose();
  }
}

class _RowLeading extends StatelessWidget {
  const _RowLeading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RowBloc, RowState, bool>(
      selector: (state) => state.active,
      builder: (context, isActive) {
        return SizedBox(width: GridSize.leadingHeaderPadding, child: isActive ? _activeWidget() : null);
      },
    );
  }

  Widget _activeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        AppendRowButton(),
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

class AppendRowButton extends StatelessWidget {
  const AppendRowButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      hoverColor: theme.hover,
      width: 22,
      onPressed: () => context.read<RowBloc>().add(const RowEvent.createRow()),
      iconPadding: const EdgeInsets.all(3),
      icon: svg("home/add"),
    );
  }
}

class _RowCells extends StatelessWidget {
  const _RowCells({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (previous, current) => previous.cellDatas != current.cellDatas,
      builder: (context, state) {
        return FutureBuilder(
          future: state.cellDatas,
          builder: builder,
        );
      },
    );
  }

  Widget builder(context, AsyncSnapshot<dynamic> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.done:
        List<GridCellData> cellDatas = snapshot.data;
        return Row(children: cellDatas.map(_toCell).toList());
      default:
        return const SizedBox();
    }
  }

  Widget _toCell(GridCellData data) {
    return CellContainer(
      width: data.field.width.toDouble(),
      child: buildGridCell(data),
    );
  }
}
