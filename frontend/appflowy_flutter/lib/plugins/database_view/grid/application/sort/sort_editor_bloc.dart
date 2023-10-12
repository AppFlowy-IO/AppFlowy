import 'dart:async';

import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_controller.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_service.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sort_editor_bloc.freezed.dart';

class SortEditorBloc extends Bloc<SortEditorEvent, SortEditorState> {
  final String viewId;
  final SortBackendService _sortBackendSvc;
  final SortController sortController;
  final FieldController fieldController;
  void Function(List<SortInfo>)? _onSortFn;
  void Function(List<FieldPB>)? _onFieldFn;
  SortEditorBloc({
    required this.viewId,
    required this.sortController,
    required this.fieldController,
  })  : _sortBackendSvc = SortBackendService(viewId: viewId),
        super(SortEditorState.initial(
            sortController.sorts, fieldController.fields)) {
    on<SortEditorEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (List<FieldPB> fields) {
            final List<FieldPB> allFields = List.from(fields);
            final List<FieldPB> creatableFields = List.from(fields);
            creatableFields.retainWhere((field) => field.canCreateSort);
            emit(
              state.copyWith(
                allFields: allFields,
                creatableFields: creatableFields,
              ),
            );
          },
          setCondition: (SortInfo sortInfo, SortConditionPB condition) async {
            final result = await _sortBackendSvc.updateSort(
              fieldId: sortInfo.fieldId,
              sortId: sortInfo.sortId,
              fieldType: sortInfo.field.fieldType,
              condition: condition,
            );
            result.fold((l) => {}, (err) => Log.error(err));
          },
          deleteAllSorts: () async {
            final result = await _sortBackendSvc.deleteAllSorts();
            result.fold((l) => {}, (err) => Log.error(err));
          },
          didReceiveSorts: (List<SortInfo> sortInfos) {
            emit(state.copyWith(sortInfos: sortInfos));
          },
          deleteSort: (SortInfo sortInfo) async {
            final result = await _sortBackendSvc.deleteSort(
              fieldId: sortInfo.fieldId,
              sortId: sortInfo.sortId,
              fieldType: sortInfo.field.fieldType,
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
        );
      },
    );
  }

  void _startListening() {
    _onSortFn = (sorts) {
      add(SortEditorEvent.didReceiveSorts(sorts));
    };

    _onFieldFn = (fields) {
      add(SortEditorEvent.didReceiveFields(List.from(fields)));
    };

    sortController.addListener(
      listenWhen: () => !isClosed,
      onReceiveSorts: _onSortFn,
    );

    fieldController.addListener(
      listenWhen: () => !isClosed,
      onReceiveFields: _onFieldFn,
    );
  }

  @override
  Future<void> close() async {
    if (_onSortFn != null) {
      sortController.removeListener(onSortsListener: _onSortFn!);
      _onSortFn = null;
    }
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
  const factory SortEditorEvent.didReceiveFields(List<FieldPB> fieldInfos) =
      _DidReceiveFields;
  const factory SortEditorEvent.didReceiveSorts(List<SortInfo> sortInfos) =
      _DidReceiveSorts;
  const factory SortEditorEvent.setCondition(
    SortInfo sortInfo,
    SortConditionPB condition,
  ) = _SetCondition;
  const factory SortEditorEvent.deleteSort(SortInfo sortInfo) = _DeleteSort;
  const factory SortEditorEvent.deleteAllSorts() = _DeleteAllSorts;
}

@freezed
class SortEditorState with _$SortEditorState {
  const factory SortEditorState({
    required List<SortInfo> sortInfos,
    required List<FieldPB> creatableFields,
    required List<FieldPB> allFields,
  }) = _SortEditorState;

  factory SortEditorState.initial(
    List<SortInfo> sortInfos,
    List<FieldPB> fields,
  ) {
    fields.retainWhere((field) => field.canCreateSort);
    return SortEditorState(
      creatableFields: fields,
      allFields: fields,
      sortInfos: sortInfos,
    );
  }
}
