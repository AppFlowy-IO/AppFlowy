import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'column_service.dart';
import 'data.dart';

part 'column_bloc.freezed.dart';

class ColumnBloc extends Bloc<ColumnEvent, ColumnState> {
  final ColumnService service;
  final GridColumnData data;

  ColumnBloc({required this.data, required this.service}) : super(ColumnState.initial(data.fields)) {
    on<ColumnEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialColumn value) async {},
          createColumn: (_CreateColumn value) {},
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
abstract class ColumnEvent with _$ColumnEvent {
  const factory ColumnEvent.initial() = _InitialColumn;
  const factory ColumnEvent.createColumn() = _CreateColumn;
}

@freezed
abstract class ColumnState with _$ColumnState {
  const factory ColumnState({required List<Field> fields}) = _ColumnState;

  factory ColumnState.initial(List<Field> fields) => ColumnState(fields: fields);
}
