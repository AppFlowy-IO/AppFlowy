import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'mobile_date_cell_edit_screen.dart';

abstract class GridCellDelegate {
  void onFocus(bool isFocus);
  GridCellDelegate get delegate;
}

class MobileDateCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  final String? placeholder;

  MobileDateCell({
    required this.cellControllerBuilder,
    required this.placeholder,
    super.key,
  });

  @override
  GridCellState<MobileDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<MobileDateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as DateCellController;
    _cellBloc = DateCellBloc(cellController: cellController)
      ..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          // full screen show the date edit screen
          return GestureDetector(
            onTap: () => context.push(
              MobileDateCellEditScreen.routeName,
              extra: {
                MobileDateCellEditScreen.argCellController:
                    widget.cellControllerBuilder.build() as DateCellController,
              },
            ),
            child: SizedBox(
              width: double.infinity,
              child: MobileDateCellText(
                dateStr: state.dateStr,
                placeholder: widget.placeholder ?? "",
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

  @override
  void requestBeginFocus() {
    widget.onCellFocus.value = true;
  }

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}

class MobileDateCellText extends StatelessWidget {
  final String dateStr;
  final String placeholder;

  const MobileDateCellText({
    required this.dateStr,
    required this.placeholder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = dateStr.isEmpty;
    final text = isPlaceholder ? placeholder : dateStr;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isPlaceholder
                  ? Theme.of(context).hintColor
                  : Theme.of(context).colorScheme.onBackground,
            ),
      ),
    );
  }
}
