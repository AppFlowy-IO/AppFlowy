import 'dart:async';

import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/domain/filter_service.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_editor_bloc.freezed.dart';

class FilterEditorBloc extends Bloc<FilterEditorEvent, FilterEditorState> {
  FilterEditorBloc({required this.viewId, required this.fieldController})
      : _filterBackendSvc = FilterBackendService(viewId: viewId),
        super(
          FilterEditorState.initial(
            viewId,
            fieldController.filters,
            _getCreatableFilter(fieldController.fieldInfos),
          ),
        ) {
    _dispatch();
    _startListening();
  }

  final String viewId;
  final FieldController fieldController;
  final FilterBackendService _filterBackendSvc;

  void Function(List<DatabaseFilter>)? _onFilterFn;
  void Function(List<FieldInfo>)? _onFieldFn;

  void _dispatch() {
    on<FilterEditorEvent>(
      (event, emit) async {
        await event.when(
          didReceiveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          didReceiveFields: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                fields: _getCreatableFilter(fields),
              ),
            );
          },
          createFilter: (field) {
            return _createDefaultFilter(field);
          },
          updateFilter: (filter) {
            return _filterBackendSvc.updateFilter(
              filterId: filter.filterId,
              fieldId: filter.fieldId,
              fieldType: filter.fieldType,
              data: filter.writeToBuffer(),
            );
          },
          deleteFilter: (filterId) async {
            return _filterBackendSvc.deleteFilter(filterId: filterId);
          },
        );
      },
    );
  }

  void _startListening() {
    _onFilterFn = (filters) {
      add(FilterEditorEvent.didReceiveFilters(filters));
    };

    _onFieldFn = (fields) {
      add(FilterEditorEvent.didReceiveFields(fields));
    };

    fieldController.addListener(
      onFilters: (filters) {
        _onFilterFn?.call(filters);
      },
      onReceiveFields: (fields) {
        _onFieldFn?.call(fields);
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onFilterFn != null) {
      fieldController.removeListener(onFiltersListener: _onFilterFn!);
      _onFilterFn = null;
    }
    if (_onFieldFn != null) {
      fieldController.removeListener(onFieldsListener: _onFieldFn!);
      _onFieldFn = null;
    }
    return super.close();
  }

  Future<FlowyResult<void, FlowyError>> _createDefaultFilter(
    FieldInfo field,
  ) async {
    final fieldId = field.id;
    switch (field.fieldType) {
      case FieldType.Checkbox:
        return _filterBackendSvc.insertCheckboxFilter(
          fieldId: fieldId,
          condition: CheckboxFilterConditionPB.IsChecked,
        );
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return _filterBackendSvc.insertDateFilter(
          fieldId: fieldId,
          condition: DateFilterConditionPB.DateIs,
          timestamp: timestamp,
        );
      case FieldType.MultiSelect:
        return _filterBackendSvc.insertSelectOptionFilter(
          fieldId: fieldId,
          condition: SelectOptionFilterConditionPB.OptionContains,
          fieldType: FieldType.MultiSelect,
        );
      case FieldType.Checklist:
        return _filterBackendSvc.insertChecklistFilter(
          fieldId: fieldId,
          condition: ChecklistFilterConditionPB.IsIncomplete,
        );
      case FieldType.Number:
        return _filterBackendSvc.insertNumberFilter(
          fieldId: fieldId,
          condition: NumberFilterConditionPB.Equal,
        );
      case FieldType.Time:
        return _filterBackendSvc.insertTimeFilter(
          fieldId: fieldId,
          condition: NumberFilterConditionPB.Equal,
        );
      case FieldType.RichText:
        return _filterBackendSvc.insertTextFilter(
          fieldId: fieldId,
          condition: TextFilterConditionPB.TextContains,
          content: '',
        );
      case FieldType.SingleSelect:
        return _filterBackendSvc.insertSelectOptionFilter(
          fieldId: fieldId,
          condition: SelectOptionFilterConditionPB.OptionIs,
          fieldType: FieldType.SingleSelect,
        );
      case FieldType.URL:
        return _filterBackendSvc.insertURLFilter(
          fieldId: fieldId,
          condition: TextFilterConditionPB.TextContains,
        );
      case FieldType.Media:
        return _filterBackendSvc.insertMediaFilter(
          fieldId: fieldId,
          condition: MediaFilterConditionPB.MediaIsNotEmpty,
        );
      default:
        throw UnimplementedError();
    }
  }
}

@freezed
class FilterEditorEvent with _$FilterEditorEvent {
  const factory FilterEditorEvent.didReceiveFilters(
    List<DatabaseFilter> filters,
  ) = _DidReceiveFilters;
  const factory FilterEditorEvent.didReceiveFields(List<FieldInfo> fields) =
      _DidReceiveFields;
  const factory FilterEditorEvent.createFilter(FieldInfo field) = _CreateFilter;
  const factory FilterEditorEvent.updateFilter(DatabaseFilter filter) =
      _UpdateFilter;
  const factory FilterEditorEvent.deleteFilter(String filterId) = _DeleteFilter;
}

@freezed
class FilterEditorState with _$FilterEditorState {
  const factory FilterEditorState({
    required String viewId,
    required List<DatabaseFilter> filters,
    required List<FieldInfo> fields,
  }) = _FilterEditorState;

  factory FilterEditorState.initial(
    String viewId,
    List<DatabaseFilter> filterInfos,
    List<FieldInfo> fields,
  ) =>
      FilterEditorState(
        viewId: viewId,
        filters: filterInfos,
        fields: fields,
      );
}

List<FieldInfo> _getCreatableFilter(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere(
    (field) => field.fieldType.canCreateFilter,
  );
  return creatableFields;
}
