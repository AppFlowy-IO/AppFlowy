import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/cell/cell_controller_builder.dart';

part 'number_card_cell_bloc.freezed.dart';

class NumberCardCellBloc
    extends Bloc<NumberCardCellEvent, NumberCardCellState> {
  final NumberCellController cellController;
  void Function()? _onCellChangedFn;
  NumberCardCellBloc({
    required this.cellController,
  }) : super(NumberCardCellState.initial(cellController)) {
    on<NumberCardCellEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (final content) {
            emit(state.copyWith(content: content));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((final cellContent) {
        if (!isClosed) {
          add(NumberCardCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
    );
  }
}

@freezed
class NumberCardCellEvent with _$NumberCardCellEvent {
  const factory NumberCardCellEvent.initial() = _InitialCell;
  const factory NumberCardCellEvent.didReceiveCellUpdate(final String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class NumberCardCellState with _$NumberCardCellState {
  const factory NumberCardCellState({
    required final String content,
  }) = _NumberCardCellState;

  factory NumberCardCellState.initial(final TextCellController context) =>
      NumberCardCellState(
        content: context.getCellData() ?? "",
      );
}
