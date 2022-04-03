import 'package:app_flowy/workspace/application/grid/data.dart';
import 'package:app_flowy/workspace/application/grid/field/grid_listenr.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final FieldService service;
  final GridFieldsListener fieldListener;

  GridHeaderBloc({
    required GridHeaderData data,
    required this.service,
  })  : fieldListener = GridFieldsListener(gridId: data.gridId),
        super(GridHeaderState.initial(data.fields)) {
    on<GridHeaderEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialHeader value) async {
            _startListening();
          },
          createField: (_CreateField value) {},
          insertField: (_InsertField value) {},
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            value.fields.retainWhere((field) => field.visibility);
            emit(state.copyWith(fields: value.fields));
          },
        );
      },
    );
  }

  Future<void> _startListening() async {
    fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (fields) => add(GridHeaderEvent.didReceiveFieldUpdate(fields)),
        (err) => Log.error(err),
      );
    });

    fieldListener.start();
  }

  @override
  Future<void> close() async {
    await fieldListener.stop();
    return super.close();
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
  const factory GridHeaderEvent.createField() = _CreateField;
  const factory GridHeaderEvent.insertField({required bool onLeft}) = _InsertField;
  const factory GridHeaderEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridHeaderState with _$GridHeaderState {
  const factory GridHeaderState({required List<Field> fields}) = _GridHeaderState;

  factory GridHeaderState.initial(List<Field> fields) {
    fields.retainWhere((field) => field.visibility);
    return GridHeaderState(fields: fields);
  }
}
