import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checkbox_cell/checkbox_cell_bloc.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class CheckboxCardCellStyle extends CardCellStyle {
  final Size iconSize;

  CheckboxCardCellStyle({required super.padding, required this.iconSize});
}

class CheckboxCardCell extends CardCell<CheckboxCardCellStyle> {
  final CheckboxCellController cellController;

  const CheckboxCardCell({
    super.key,
    required super.style,
    required this.cellController,
  });

  @override
  State<CheckboxCardCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<CheckboxCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return CheckboxCellBloc(cellController: widget.cellController)
          ..add(const CheckboxCellEvent.initial());
      },
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        buildWhen: (previous, current) =>
            previous.isSelected != current.isSelected,
        builder: (context, state) {
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: FlowyIconButton(
              iconPadding: EdgeInsets.zero,
              icon: FlowySvg(
                state.isSelected
                    ? FlowySvgs.check_filled_s
                    : FlowySvgs.uncheck_s,
                blendMode: BlendMode.dst,
                size: widget.style.iconSize,
              ),
              width: 20,
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
