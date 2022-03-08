import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
import 'data.dart';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowService service;
  final GridRowData data;

  RowBloc({required this.data, required this.service}) : super(RowState.initial()) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {},
          createRow: (_CreateRow value) {},
          highlightRow: (_HighlightRow value) {
            emit(state.copyWith(
              isHighlight: value.rowId.fold(() => false, (rowId) => rowId == data.row.id),
            ));
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
  const factory RowEvent.highlightRow(Option<String> rowId) = _HighlightRow;
}

@freezed
abstract class RowState with _$RowState {
  const factory RowState({
    required bool isHighlight,
  }) = _RowState;

  factory RowState.initial() => const RowState(isHighlight: false);
}
