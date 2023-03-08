import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

import '../bloc/url_card_cell_bloc.dart';
import '../define.dart';
import 'card_cell.dart';

class URLCardCell extends CardCell {
  final CellControllerBuilder cellControllerBuilder;

  const URLCardCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<URLCardCell> createState() => _URLCardCellState();
}

class _URLCardCellState extends State<URLCardCell> {
  late URLCardCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as URLCellController;
    _cellBloc = URLCardCellBloc(cellController: cellController);
    _cellBloc.add(const URLCardCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<URLCardCellBloc, URLCardCellState>(
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return const SizedBox();
          } else {
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: CardSizes.cardCellVPadding,
                ),
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    text: state.content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .size(FontSizes.s14)
                        .textColor(Theme.of(context).colorScheme.primary)
                        .underline,
                  ),
                ),
              ),
            );
          }
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
