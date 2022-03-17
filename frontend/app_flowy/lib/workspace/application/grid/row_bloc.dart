import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'data.dart';
import 'row_listener.dart';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService service;
  final RowListener listener;

  RowBloc({required this.service, required this.listener}) : super(RowState.initial(service.rowData)) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            _startRowListening();
          },
          createRow: (_CreateRow value) {
            service.createRow();
          },
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
    await listener.close();
    return super.close();
  }

  Future<void> _startRowListening() async {
    listener.updateRowNotifier.addPublishListener((result) {
      result.fold((row) {
        //
      }, (err) => null);
    });

    listener.updateCellNotifier.addPublishListener((result) {
      result.fold((repeatedCvell) {
        //
        Log.info("$repeatedCvell");
      }, (r) => null);
    });

    listener.start();
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
