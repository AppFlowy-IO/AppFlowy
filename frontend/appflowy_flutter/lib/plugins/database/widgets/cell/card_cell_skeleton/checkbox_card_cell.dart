import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checkbox_cell_bloc.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class CheckboxCardCellStyle extends CardCellStyle {
  CheckboxCardCellStyle({
    required super.padding,
    required this.iconSize,
    required this.showFieldName,
    this.textStyle,
  }) : assert(!showFieldName || showFieldName && textStyle != null);

  final Size iconSize;
  final bool showFieldName;
  final TextStyle? textStyle;
}

class CheckboxCardCell extends CardCell<CheckboxCardCellStyle> {
  const CheckboxCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;

  @override
  State<CheckboxCardCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<CheckboxCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return CheckboxCellBloc(
          cellController: makeCellController(
            widget.databaseController,
            widget.cellContext,
          ).as(),
        )..add(const CheckboxCellEvent.initial());
      },
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        builder: (context, state) {
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Row(
              children: [
                FlowyIconButton(
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
                if (widget.style.showFieldName) ...[
                  const HSpace(6.0),
                  Text(
                    state.fieldName,
                    style: widget.style.textStyle,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
