import 'package:app_flowy/workspace/application/grid/data.dart';
import 'package:app_flowy/workspace/application/grid/field/grid_listenr.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field/field_service.dart';
import 'grid_service.dart';

part 'grid_header_bloc.freezed.dart';

class GridHeaderBloc extends Bloc<GridHeaderEvent, GridHeaderState> {
  final FieldService _fieldService;
  final GridFieldCache _fieldCache;
  final GridFieldsListener _fieldListener;

  GridHeaderBloc({
    required GridHeaderData data,
  })  : _fieldListener = GridFieldsListener(gridId: data.gridId),
        _fieldService = FieldService(gridId: data.gridId),
        _fieldCache = GridFieldCache(),
        super(GridHeaderState.initial(data.fields)) {
    _fieldCache.fields = data.fields;

    on<GridHeaderEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialHeader value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            value.fields.retainWhere((field) => field.visibility);
            emit(state.copyWith(fields: value.fields));
          },
        );
      },
    );
  }

  Future<void> _startListening() async {
    _fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (changeset) {
          _fieldCache.applyChangeset(changeset);
          add(GridHeaderEvent.didReceiveFieldUpdate(List.from(_fieldCache.fields)));
        },
        (err) => Log.error(err),
      );
    });

    _fieldListener.start();
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    return super.close();
  }
}

@freezed
class GridHeaderEvent with _$GridHeaderEvent {
  const factory GridHeaderEvent.initial() = _InitialHeader;
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
