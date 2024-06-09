import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_option_cell_bloc.freezed.dart';

class SelectOptionCellBloc
    extends Bloc<SelectOptionCellEvent, SelectOptionCellState> {
  SelectOptionCellBloc({
    required this.cellController,
  }) : super(SelectOptionCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final SelectOptionCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<SelectOptionCellEvent>(
      (event, emit) {
        event.when(
          didReceiveOptions: (List<SelectOptionPB> selectedOptions) {
            emit(
              state.copyWith(
                selectedOptions: selectedOptions,
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (selectOptionCellData) {
        if (!isClosed) {
          add(
            SelectOptionCellEvent.didReceiveOptions(
              selectOptionCellData?.selectOptions ?? [],
            ),
          );
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(SelectOptionCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class SelectOptionCellEvent with _$SelectOptionCellEvent {
  const factory SelectOptionCellEvent.didReceiveOptions(
    List<SelectOptionPB> selectedOptions,
  ) = _DidReceiveOptions;
  const factory SelectOptionCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
}

@freezed
class SelectOptionCellState with _$SelectOptionCellState {
  const factory SelectOptionCellState({
    required List<SelectOptionPB> selectedOptions,
    required bool wrap,
  }) = _SelectOptionCellState;

  factory SelectOptionCellState.initial(
    SelectOptionCellController cellController,
  ) {
    final data = cellController.getCellData();
    final wrap = cellController.fieldInfo.wrapCellContent;
    return SelectOptionCellState(
      selectedOptions: data?.selectOptions ?? [],
      wrap: wrap ?? true,
    );
  }
}
