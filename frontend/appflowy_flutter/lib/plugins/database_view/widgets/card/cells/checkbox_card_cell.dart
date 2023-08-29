import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';

import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/checkbox_card_cell_bloc.dart';
import 'card_cell.dart';

class CheckboxCardCell extends CardCell {
  final CellControllerBuilder cellControllerBuilder;

  const CheckboxCardCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckboxCardCell> createState() => _CheckboxCardCellState();
}

class _CheckboxCardCellState extends State<CheckboxCardCell> {
  late CheckboxCardCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as CheckboxCellController;
    _cellBloc = CheckboxCardCellBloc(cellController: cellController);
    _cellBloc.add(const CheckboxCardCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCardCellBloc, CheckboxCardCellState>(
        buildWhen: (previous, current) =>
            previous.isSelected != current.isSelected,
        builder: (context, state) {
          final icon = state.isSelected
              ? const FlowySvg(
                  FlowySvgs.check_filled_s,
                  blendMode: BlendMode.dst,
                )
              : const FlowySvg(FlowySvgs.uncheck_s);
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: FlowyIconButton(
                iconPadding: EdgeInsets.zero,
                icon: icon,
                width: 20,
                onPressed: () => context
                    .read<CheckboxCardCellBloc>()
                    .add(const CheckboxCardCellEvent.select()),
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
}
