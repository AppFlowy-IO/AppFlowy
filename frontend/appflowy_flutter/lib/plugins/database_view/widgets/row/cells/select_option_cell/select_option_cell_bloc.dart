import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_cell_bloc.freezed.dart';

class SelectOptionCellBloc
    extends Bloc<SelectOptionCellEvent, SelectOptionCellState> {
  final SelectOptionCellController cellController;
  void Function()? _onCellChangedFn;

  SelectOptionCellBloc({
    required this.cellController,
  }) : super(SelectOptionCellState.initial(cellController)) {
    on<SelectOptionCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          didReceiveOptions: (_DidReceiveOptions value) {
            emit(state.copyWith(
              selectedOptions: value.selectedOptions,
            ));
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
          add(SelectOptionCellEvent.didReceiveOptions(
            selectOptionContext?.selectOptions ?? [],
          ));
        }
      }),
    );
  }
}

@freezed
class SelectOptionCellEvent with _$SelectOptionCellEvent {
  const factory SelectOptionCellEvent.initial() = _InitialCell;
  const factory SelectOptionCellEvent.didReceiveOptions(
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
}

@freezed
class SelectOptionCellState with _$SelectOptionCellState {
  const factory SelectOptionCellState({
    required List<SelectOptionPB> selectedOptions,
  }) = _SelectOptionCellState;

  factory SelectOptionCellState.initial(SelectOptionCellController context) {
    final data = context.getCellData();

    return SelectOptionCellState(
      selectedOptions: data?.selectOptions ?? [],
    );
  }
}
