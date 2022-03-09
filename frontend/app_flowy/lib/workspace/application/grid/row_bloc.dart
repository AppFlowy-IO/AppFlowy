import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'data.dart';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService service;

  RowBloc({required GridRowData data, required this.service}) : super(RowState.initial(data)) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {},
          createRow: (_CreateRow value) {},
          activeRow: (_ActiveRow value) {
            emit(state.copyWith(active: true));
          },
          disactiveRow: (_DisactiveRow value) {
            emit(state.copyWith(active: false));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
abstract class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.activeRow() = _ActiveRow;
  const factory RowEvent.disactiveRow() = _DisactiveRow;
}

@freezed
abstract class RowState with _$RowState {
  const factory RowState({
    required GridRowData data,
    required bool active,
  }) = _RowState;

  factory RowState.initial(GridRowData data) => RowState(data: data, active: false);
}
