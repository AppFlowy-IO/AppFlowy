import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/sort_entities.dart';
import 'package:appflowy/plugins/database/domain/sort_service.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sort_editor_bloc.freezed.dart';

class SortEditorBloc extends Bloc<SortEditorEvent, SortEditorState> {
  SortEditorBloc({
    required this.viewId,
    required this.fieldController,
  })  : _sortBackendSvc = SortBackendService(viewId: viewId),
        super(
          SortEditorState.initial(
            fieldController.sorts,
            fieldController.fieldInfos,
          ),
        ) {
    _dispatch();
    _startListening();
  }

  final String viewId;
  final SortBackendService _sortBackendSvc;
  final FieldController fieldController;

  void Function(List<FieldInfo>)? _onFieldFn;
  void Function(List<DatabaseSort>)? _onSortsFn;

  void _dispatch() {
    on<SortEditorEvent>(
      (event, emit) async {
        await event.when(
          didReceiveFields: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                allFields: fields,
                creatableFields: _getCreatableSorts(fields),
              ),
            );
          },
          createSort: (
            String fieldId,
            SortConditionPB? condition,
          ) async {
            final result = await _sortBackendSvc.insertSort(
              fieldId: fieldId,
              condition: condition ?? SortConditionPB.Ascending,
            );
            result.fold((l) => {}, (err) => Log.error(err));
          },
          editSort: (
            String sortId,
            String? fieldId,
            SortConditionPB? condition,
          ) async {
            final sort = state.sorts
                .firstWhereOrNull((element) => element.sortId == sortId);
            if (sort == null) {
              return;
            }

            final result = await _sortBackendSvc.updateSort(
              sortId: sortId,
              fieldId: fieldId ?? sort.fieldId,
              condition: condition ?? sort.condition,
            );
            result.fold((l) => {}, (err) => Log.error(err));
          },
          deleteAllSorts: () async {
            final result = await _sortBackendSvc.deleteAllSorts();
            result.fold((l) => {}, (err) => Log.error(err));
          },
          didReceiveSorts: (sorts) {
            emit(state.copyWith(sorts: sorts));
          },
          deleteSort: (sortId) async {
            final result = await _sortBackendSvc.deleteSort(
              sortId: sortId,
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
          reorderSort: (fromIndex, toIndex) async {
            if (fromIndex < toIndex) {
              toIndex--;
            }

            final fromId = state.sorts[fromIndex].sortId;
            final toId = state.sorts[toIndex].sortId;

            final newSorts = [...state.sorts];
            newSorts.insert(toIndex, newSorts.removeAt(fromIndex));
            emit(state.copyWith(sorts: newSorts));
            final result = await _sortBackendSvc.reorderSort(
              fromSortId: fromId,
              toSortId: toId,
            );
            result.fold((l) => null, (err) => Log.error(err));
          },
        );
      },
    );
  }

  void _startListening() {
    _onFieldFn = (fields) {
      add(SortEditorEvent.didReceiveFields(List.from(fields)));
    };
    _onSortsFn = (sorts) {
      add(SortEditorEvent.didReceiveSorts(sorts));
    };

    fieldController.addListener(
      listenWhen: () => !isClosed,
      onReceiveFields: _onFieldFn,
      onSorts: _onSortsFn,
    );
  }

  @override
  Future<void> close() async {
    fieldController.removeListener(
      onFieldsListener: _onFieldFn,
      onSortsListener: _onSortsFn,
    );
    _onFieldFn = null;
    _onSortsFn = null;
    return super.close();
  }
}

@freezed
class SortEditorEvent with _$SortEditorEvent {
  const factory SortEditorEvent.didReceiveFields(List<FieldInfo> fieldInfos) =
      _DidReceiveFields;
  const factory SortEditorEvent.didReceiveSorts(List<DatabaseSort> sorts) =
      _DidReceiveSorts;
  const factory SortEditorEvent.createSort({
    required String fieldId,
    SortConditionPB? condition,
  }) = _CreateSort;
  const factory SortEditorEvent.editSort({
    required String sortId,
    String? fieldId,
    SortConditionPB? condition,
  }) = _EditSort;
  const factory SortEditorEvent.reorderSort(int oldIndex, int newIndex) =
      _ReorderSort;
  const factory SortEditorEvent.deleteSort(String sortId) = _DeleteSort;
  const factory SortEditorEvent.deleteAllSorts() = _DeleteAllSorts;
}

@freezed
class SortEditorState with _$SortEditorState {
  const factory SortEditorState({
    required List<DatabaseSort> sorts,
    required List<FieldInfo> allFields,
    required List<FieldInfo> creatableFields,
  }) = _SortEditorState;

  factory SortEditorState.initial(
    List<DatabaseSort> sorts,
    List<FieldInfo> fields,
  ) {
    return SortEditorState(
      sorts: sorts,
      allFields: fields,
      creatableFields: _getCreatableSorts(fields),
    );
  }
}

List<FieldInfo> _getCreatableSorts(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere(
    (field) => field.fieldType.canCreateSort && !field.hasSort,
  );
  return creatableFields;
}
