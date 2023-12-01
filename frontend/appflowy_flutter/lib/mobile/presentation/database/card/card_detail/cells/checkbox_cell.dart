import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checkbox_cell/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDetailCheckboxCell extends GridCellWidget {
  RowDetailCheckboxCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  GridCellState<RowDetailCheckboxCell> createState() =>
      _RowDetailCheckboxCellState();
}

class _RowDetailCheckboxCellState extends GridCellState<RowDetailCheckboxCell> {
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
          return InkWell(
            onTap: () => context
                .read<CheckboxCellBloc>()
                .add(const CheckboxCellEvent.select()),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                minWidth: double.infinity,
              ),
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FlowySvg(
                    state.isSelected
                        ? FlowySvgs.check_filled_s
                        : FlowySvgs.uncheck_s,
                    color: Theme.of(context).colorScheme.onBackground,
                    blendMode: BlendMode.dst,
                    size: const Size.square(24),
                  ),
                ),
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
