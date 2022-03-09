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
import 'grid_cell.dart';
import 'package:dartz/dartz.dart';

class GridRowWidget extends StatelessWidget {
  final GridRowData data;
  final Function(bool)? onHoverChange;
  const GridRowWidget(this.data, {Key? key, this.onHoverChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RowBloc>(param1: data),
      child: BlocBuilder<RowBloc, RowState>(
        builder: (context, state) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (p) => context.read<RowBloc>().add(RowEvent.highlightRow(some(data.row.id))),
              onExit: (p) => context.read<RowBloc>().add(RowEvent.highlightRow(none())),
              child: SizedBox(
                height: data.row.height.toDouble(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildCells(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCells() {
    return [
      SizedBox(
        width: GridSize.leadingHeaderPadding,
        child: LeadingRow(rowId: data.row.id),
      ),
      ...data.fields.map(
        (field) {
          final cellData = data.cellMap[field.id];
          return CellContainer(
            width: field.width.toDouble(),
            child: GridCellBuilder.buildCell(field, cellData),
          );
        },
      ),
      SizedBox(
        width: GridSize.trailHeaderPadding,
        child: TrailingRow(rowId: data.row.id),
      )
    ].toList();
  }
}

class LeadingRow extends StatelessWidget {
  final String rowId;
  const LeadingRow({required this.rowId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RowBloc, RowState>(
      builder: (context, state) {
        if (state.isHighlight) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CreateRowButton(),
            ],
          );
        }
        return const SizedBox.expand();
      },
    );
  }
}

class TrailingRow extends StatelessWidget {
  final String rowId;
  const TrailingRow({required this.rowId, Key? key}) : super(key: key);

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
