import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checkbox_cell/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCheckboxCardCell extends CardCell {
  const MobileCheckboxCardCell({
    super.key,
    required this.cellControllerBuilder,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  State<MobileCheckboxCardCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<MobileCheckboxCardCell> {
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
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        buildWhen: (previous, current) =>
            previous.isSelected != current.isSelected,
        builder: (context, state) {
          return Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              visualDensity: VisualDensity.compact,
              icon: FlowySvg(
                state.isSelected
                    ? FlowySvgs.check_filled_s
                    : FlowySvgs.uncheck_s,
                blendMode: BlendMode.dst,
                size: const Size.square(24),
              ),
              onPressed: () => context
                  .read<CheckboxCellBloc>()
                  .add(const CheckboxCellEvent.select()),
            ),
          );
        },
      ),
    );
  }
}
