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

class GridRowWidget extends StatefulWidget {
  final RowData data;
  const GridRowWidget({required this.data, Key? key}) : super(key: key);

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;
  late _RegionStateNotifier _rowStateNotifier;

  @override
  void initState() {
    _rowBloc = getIt<RowBloc>(param1: widget.data)..add(const RowEvent.initial());
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
      icon: svgWidget("home/add"),
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
        return Row(children: children);
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
