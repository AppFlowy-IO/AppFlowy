import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../field/field_controller.dart';
import 'setting_service.dart';

part 'group_bloc.freezed.dart';

class GridGroupBloc extends Bloc<GridGroupEvent, GridGroupState> {
  final GridFieldController _fieldController;
  final SettingFFIService _settingFFIService;
  Function(List<GridFieldInfo>)? _onFieldsFn;

  GridGroupBloc({
    required String viewId,
    required GridFieldController fieldController,
  })  : _fieldController = fieldController,
        _settingFFIService = SettingFFIService(viewId: viewId),
        super(GridGroupState.initial(viewId, fieldController.fieldInfos)) {
    on<GridGroupEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (fieldContexts) {
            emit(state.copyWith(fieldContexts: fieldContexts));
          },
          setGroupByField: (String fieldId, FieldType fieldType) async {
            final result = await _settingFFIService.groupByField(
              fieldId: fieldId,
              fieldType: fieldType,
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onFieldsFn != null) {
      _fieldController.removeListener(onFieldsListener: _onFieldsFn!);
      _onFieldsFn = null;
    }
    return super.close();
  }

  void _startListening() {
    _onFieldsFn = (fieldContexts) =>
        add(GridGroupEvent.didReceiveFieldUpdate(fieldContexts));
    _fieldController.addListener(
      onFields: _onFieldsFn,
      listenWhen: () => !isClosed,
    );
  }
}

@freezed
class GridGroupEvent with _$GridGroupEvent {
  const factory GridGroupEvent.initial() = _Initial;
  const factory GridGroupEvent.setGroupByField(
    String fieldId,
    FieldType fieldType,
  ) = _GroupByField;
  const factory GridGroupEvent.didReceiveFieldUpdate(
      List<GridFieldInfo> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridGroupState with _$GridGroupState {
  const factory GridGroupState({
    required String gridId,
    required List<GridFieldInfo> fieldContexts,
  }) = _GridGroupState;

  factory GridGroupState.initial(
          String gridId, List<GridFieldInfo> fieldContexts) =>
      GridGroupState(
        gridId: gridId,
        fieldContexts: fieldContexts,
      );
}
