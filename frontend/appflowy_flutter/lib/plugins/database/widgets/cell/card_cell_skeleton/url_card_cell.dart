import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/url_cell/url_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'card_cell.dart';

class URLCardCellStyle extends CardCellStyle {
  final TextStyle textStyle;

  URLCardCellStyle({
    required super.padding,
    required this.textStyle,
  });
}

class URLCardCell extends CardCell<URLCardCellStyle> {
  final URLCellController cellController;

  const URLCardCell({
    required this.cellController,
    required super.style,
    super.key,
  });

  @override
  State<URLCardCell> createState() => _URLCellState();
}

class _URLCellState extends State<URLCardCell> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return URLCellBloc(cellController: widget.cellController)
          ..add(const URLCellEvent.initial());
      },
      child: BlocBuilder<URLCellBloc, URLCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox();
          }
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: widget.style.padding,
            child: Text(
              state.content,
              style: widget.style.textStyle,
            ),
          );
        },
      ),
    );
  }
}
