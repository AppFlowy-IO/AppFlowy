import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checkbox_cell/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCheckboxCell extends GridCellWidget {
  MobileCheckboxCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  GridCellState<MobileCheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends GridCellState<MobileCheckboxCell> {
  late final CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as CheckboxCellController;
    _cellBloc = CheckboxCellBloc(cellController: cellController)
      ..add(const CheckboxCellEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: FlowySvg(
                state.isSelected
                    ? FlowySvgs.check_filled_s
                    : FlowySvgs.uncheck_s,
                blendMode: BlendMode.dst,
                size: const Size.square(24),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  void requestBeginFocus() {
    _cellBloc.add(const CheckboxCellEvent.select());
  }

  @override
  String? onCopy() => _cellBloc.state.isSelected ? "Yes" : "No";
}
