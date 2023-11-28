import 'package:appflowy/mobile/presentation/database/card/card_content/card_cells/style.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/url_cell/url_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileURLCardCell<CustomCardData> extends CardCell {
  const MobileURLCardCell({
    super.key,
    required this.cellControllerBuilder,
  });

  final CellControllerBuilder cellControllerBuilder;

  @override
  State<MobileURLCardCell> createState() => _URLCellState();
}

class _URLCellState extends State<MobileURLCardCell> {
  late final URLCellBloc _cellBloc;

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as URLCellController;

    _cellBloc = URLCellBloc(cellController: cellController)
      ..add(const URLCellEvent.initial());
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
      child: BlocBuilder<URLCellBloc, URLCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox();
          } else {
            return Container(
              alignment: Alignment.centerLeft,
              padding: cellStyle.padding,
              child: Text(
                state.content,
                style: cellStyle.urlTextStyle(),
              ),
            );
          }
        },
      ),
    );
  }
}
