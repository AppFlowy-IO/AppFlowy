import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cell_builder.dart';
import 'cell_container.dart';

class GridRowWidget extends StatelessWidget {
  final GridRowData data;
  const GridRowWidget({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RowBloc>(param1: data)..add(const RowEvent.initial()),
      child: BlocBuilder<RowBloc, RowState>(
        buildWhen: (p, c) => p.rowHeight != c.rowHeight,
        builder: (context, state) {
          return SizedBox(
            height: state.rowHeight,
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
    );
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
      builder: (context, state) {
        return Row(children: [
          ...state.fields.map(
            (field) {
              final cellData = state.cellDataMap.then((fut) => fut[field.id]);
              return CellContainer(
                width: field.width.toDouble(),
                child: buildGridCell(field.fieldType, cellData),
              );
            },
          ),
        ]);
      },
    );
  }
}
