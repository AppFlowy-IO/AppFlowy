import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/url_cell/url_cell_bloc.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../define.dart';
import 'card_cell.dart';

class URLCardCellStyle extends CardCellStyle {
  final double fontSize;

  URLCardCellStyle(this.fontSize);
}

class URLCardCell<CustomCardData>
    extends CardCell<CustomCardData, URLCardCellStyle> {
  final CellControllerBuilder cellControllerBuilder;

  const URLCardCell({
    required this.cellControllerBuilder,
    URLCardCellStyle? style,
    Key? key,
  }) : super(key: key, style: style);

  @override
  State<URLCardCell> createState() => _URLCellState();
}

class _URLCellState extends State<URLCardCell> {
  late URLCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as URLCellController;
    _cellBloc = URLCellBloc(cellController: cellController);
    _cellBloc.add(const URLCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<URLCellBloc, URLCellState>(
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
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: widget.style?.fontSize ?? FontSizes.s14,
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
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
