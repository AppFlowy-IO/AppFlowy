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
  GridRowWidget({required this.data, Key? key}) : super(key: ObjectKey(data.row.id));

  @override
  State<GridRowWidget> createState() => _GridRowWidgetState();
}

class _GridRowWidgetState extends State<GridRowWidget> {
  late RowBloc _rowBloc;

  @override
  void initState() {
    _rowBloc = getIt<RowBloc>(param1: widget.data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rowBloc,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (p) => _rowBloc.add(const RowEvent.activeRow()),
          onExit: (p) => _rowBloc.add(const RowEvent.disactiveRow()),
          child: SizedBox(
            height: _rowBloc.state.data.row.height.toDouble(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LeadingRow(),
                _buildCells(),
                const TrailingRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _rowBloc.close();
    super.dispose();
  }

  Widget _buildCells() {
    return BlocBuilder<RowBloc, RowState>(
      buildWhen: (p, c) => p.data != c.data,
      builder: (context, state) {
        return Row(
          key: ValueKey(state.data.row.id),
          children: state.data.fields.map(
            (field) {
              final cellData = state.data.cellMap[field.id];
              return CellContainer(
                width: field.width.toDouble(),
                child: GridCellBuilder.buildCell(field, cellData),
              );
            },
          ).toList(),
        );
      },
    );
  }
}

class LeadingRow extends StatelessWidget {
  const LeadingRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RowBloc, RowState, bool>(
      selector: (state) => state.active,
      builder: (context, isActive) {
        return SizedBox(
          width: GridSize.leadingHeaderPadding,
          child: isActive
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CreateRowButton(),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class TrailingRow extends StatelessWidget {
  const TrailingRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader4, width: 0.4);

    return BlocBuilder<RowBloc, RowState>(
      builder: (context, state) {
        return Container(
          width: GridSize.trailHeaderPadding,
          decoration: BoxDecoration(
            border: Border(bottom: borderSide),
          ),
          padding: GridSize.cellContentInsets,
        );
      },
    );
  }
}

class CreateRowButton extends StatelessWidget {
  const CreateRowButton({Key? key}) : super(key: key);

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
