import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/sort/sort_info.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'sort_service.dart';
import 'util.dart';

part 'sort_editor_bloc.freezed.dart';

class SortEditorBloc extends Bloc<SortEditorEvent, SortEditorState> {
  final String viewId;
  final SortFFIService _ffiService;
  final GridFieldController fieldController;
  void Function(List<FieldInfo>)? _onFieldFn;
  SortEditorBloc({
    required this.viewId,
    required this.fieldController,
    required List<SortInfo> sortInfos,
  })  : _ffiService = SortFFIService(viewId: viewId),
        super(SortEditorState.initial(sortInfos, fieldController.fieldInfos)) {
    on<SortEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (List<FieldInfo> fields) {
            final List<FieldInfo> allFields = List.from(fields);
            fields.retainWhere((field) => field.canCreateSort);
            emit(
              state.copyWith(
                allFields: allFields,
                creatableFields: fields,
              ),
            );
          },
          setCondition: (String sordId, GridSortConditionPB condition) {},
          deleteAllSorts: () async {
            final result = await _ffiService.deleteAllSorts();
            result.fold((l) => {}, (err) => Log.error(err));
          },
        );
      },
    );
  }

  void _startListening() {
    _onFieldFn = (fields) {
      add(SortEditorEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onFields: _onFieldFn);
  }

  @override
  Future<void> close() async {
    if (_onFieldFn != null) {
      fieldController.removeListener(onFieldsListener: _onFieldFn);
      _onFieldFn = null;
    }
    return super.close();
  }
}

@freezed
class SortEditorEvent with _$SortEditorEvent {
  const factory SortEditorEvent.initial() = _Initial;
  const factory SortEditorEvent.didReceiveFields(List<FieldInfo> fieldInfos) =
      _DidReceiveFields;
  const factory SortEditorEvent.setCondition(
      String sordId, GridSortConditionPB condition) = _SetCondition;
  const factory SortEditorEvent.deleteAllSorts() = _DeleteAllSorts;
}

@freezed
class SortEditorState with _$SortEditorState {
  const factory SortEditorState({
    required List<SortInfo> sortInfos,
    required List<FieldInfo> creatableFields,
    required List<FieldInfo> allFields,
  }) = _SortEditorState;

  factory SortEditorState.initial(
    List<SortInfo> sortInfos,
    List<FieldInfo> fields,
  ) {
    return SortEditorState(
      creatableFields: getCreatableSorts(fields),
      allFields: fields,
      sortInfos: sortInfos,
    );
  }
}
