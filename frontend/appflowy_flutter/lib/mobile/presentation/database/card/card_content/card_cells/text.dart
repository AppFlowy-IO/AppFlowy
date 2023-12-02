import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileTextCardCell<CustomCardData> extends CardCell {
  const MobileTextCardCell({
    super.key,
    required this.cellControllerBuilder,
    CustomCardData? cardData,
    this.renderHook,
  });

  final CellRenderHook<String, CustomCardData>? renderHook;
  final CellControllerBuilder cellControllerBuilder;

  @override
  State<MobileTextCardCell> createState() => _MobileTextCardCellState();
}

class _MobileTextCardCellState extends State<MobileTextCardCell> {
  late final TextCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;

    _cellBloc = TextCellBloc(cellController: cellController)
      ..add(const TextCellEvent.initial());
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellStyle = MobileCardCellStyle(context);
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<TextCellBloc, TextCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          // return custom widget if render hook is provided(for example, the title of the card on board view)
          // if widget.cardData.isEmpty means there is no data for this cell
          final Widget? custom = widget.renderHook?.call(
            state.content,
            widget.cardData,
            context,
          );
          if (custom != null) {
            return custom;
          }

          // if there is no render hook
          // the empty text cell will be hidden
          if (state.content.isEmpty) {
            return const SizedBox();
          }

          return Container(
            alignment: Alignment.centerLeft,
            padding: cellStyle.padding,
            child: Text(
              state.content,
              style: cellStyle.primaryTextStyle(),
            ),
          );
        },
      ),
    );
  }
}
