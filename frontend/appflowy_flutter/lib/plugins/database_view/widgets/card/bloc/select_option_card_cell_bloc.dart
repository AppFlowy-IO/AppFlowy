import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_card_cell_bloc.freezed.dart';

class SelectOptionCardCellBloc
    extends Bloc<SelectOptionCardCellEvent, SelectOptionCardCellState> {
  final SelectOptionCellController cellController;
  void Function()? _onCellChangedFn;

  SelectOptionCardCellBloc({
    required this.cellController,
  }) : super(SelectOptionCardCellState.initial(cellController)) {
    on<SelectOptionCardCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveOptions: (List<SelectOptionPB> selectedOptions) {
            emit(state.copyWith(selectedOptions: selectedOptions));
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
      onCellChanged: ((selectOptionContext) {
        if (!isClosed) {
          add(SelectOptionCardCellEvent.didReceiveOptions(
            selectOptionContext?.selectOptions ?? [],
          ));
        }
      }),
    );
  }
}

@freezed
class SelectOptionCardCellEvent with _$SelectOptionCardCellEvent {
  const factory SelectOptionCardCellEvent.initial() = _InitialCell;
  const factory SelectOptionCardCellEvent.didReceiveOptions(
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
}

@freezed
class SelectOptionCardCellState with _$SelectOptionCardCellState {
  const factory SelectOptionCardCellState({
    required List<SelectOptionPB> selectedOptions,
  }) = _SelectOptionCardCellState;

  factory SelectOptionCardCellState.initial(
      SelectOptionCellController context) {
    final data = context.getCellData();
    return SelectOptionCardCellState(
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
