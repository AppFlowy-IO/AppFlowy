import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../define.dart';
import 'card_cell.dart';

class SelectOptionCardCellStyle extends CardCellStyle {}

class SelectOptionCardCell<CustomCardData>
    extends CardCell<CustomCardData, SelectOptionCardCellStyle>
    with EditableCell {
  final CellControllerBuilder cellControllerBuilder;
  final CellRenderHook<List<SelectOptionPB>, CustomCardData>? renderHook;

  @override
  final EditableCardNotifier? editableNotifier;

  SelectOptionCardCell({
    required this.cellControllerBuilder,
    required CustomCardData? cardData,
    this.renderHook,
    this.editableNotifier,
    Key? key,
  }) : super(key: key, cardData: cardData);

  @override
  State<SelectOptionCardCell> createState() => _SelectOptionCellState();
}

class _SelectOptionCellState extends State<SelectOptionCardCell> {
  late SelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as SelectOptionCellController;
    _cellBloc = SelectOptionCellBloc(cellController: cellController)
      ..add(const SelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        buildWhen: (previous, current) {
          return previous.selectedOptions != current.selectedOptions;
        },
        builder: (context, state) {
          final Widget? custom = widget.renderHook?.call(
            state.selectedOptions,
            widget.cardData,
            context,
          );
          if (custom != null) {
            return custom;
          }

          final children = state.selectedOptions
              .map(
                (option) => SelectOptionTag(
                  option: option,
                  fontSize: 11,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
              )
              .toList();

          return Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: CardSizes.cardCellPadding,
              child: Wrap(spacing: 4, runSpacing: 2, children: children),
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
