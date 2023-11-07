import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checkbox_cell/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCheckboxCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;

  MobileCheckboxCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    super.key,
  });

  @override
  GridCellState<MobileCheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends GridCellState<MobileCheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as CheckboxCellController;
    _cellBloc = CheckboxCellBloc(cellController: cellController)
      ..add(const CheckboxCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.centerLeft,
            // TODO(yijing): improve icon here
            child: FlowySvg(
              state.isSelected ? FlowySvgs.checkbox_s : FlowySvgs.uncheck_s,
              color: Theme.of(context).colorScheme.onBackground,
              size: const Size.square(24),
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
  String? onCopy() {
    if (_cellBloc.state.isSelected) {
      return "Yes";
    } else {
      return "No";
    }
  }
}
