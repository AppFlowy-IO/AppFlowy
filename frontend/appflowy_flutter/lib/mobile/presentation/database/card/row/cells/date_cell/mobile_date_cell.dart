import 'package:appflowy/mobile/presentation/database/date_picker/mobile_date_picker_screen.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileDateCell extends GridCellWidget {
  MobileDateCell({
    super.key,
    required this.cellControllerBuilder,
    required this.hintText,
  });

  final CellControllerBuilder cellControllerBuilder;
  final String? hintText;

  @override
  GridCellState<MobileDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<MobileDateCell> {
  late final DateCellBloc _cellBloc;

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
            behavior: HitTestBehavior.translucent,
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
                placeholder: widget.hintText ?? "",
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
  void requestBeginFocus() {}

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}

class MobileDateCellText extends StatelessWidget {
  const MobileDateCellText({
    super.key,
    required this.dateStr,
    required this.placeholder,
  });

  final String dateStr;
  final String placeholder;

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
