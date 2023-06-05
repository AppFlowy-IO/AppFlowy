import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_filter.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_filter.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_option_filter.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_filter.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'filter_create_bloc.freezed.dart';

class GridCreateFilterBloc
    extends Bloc<GridCreateFilterEvent, GridCreateFilterState> {
  final String viewId;
  final FilterBackendService _filterBackendSvc;
  final FieldController fieldController;
  void Function(List<FieldInfo>)? _onFieldFn;
  GridCreateFilterBloc({required this.viewId, required this.fieldController})
      : _filterBackendSvc = FilterBackendService(viewId: viewId),
        super(GridCreateFilterState.initial(fieldController.fieldInfos)) {
    on<GridCreateFilterEvent>(
      (final event, final emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (final List<FieldInfo> fields) {
            emit(
              state.copyWith(
                allFields: fields,
                creatableFields: _filterFields(fields, state.filterText),
              ),
            );
          },
          didReceiveFilterText: (final String text) {
            emit(
              state.copyWith(
                filterText: text,
                creatableFields: _filterFields(state.allFields, text),
              ),
            );
          },
          createDefaultFilter: (final FieldInfo field) {
            emit(state.copyWith(didCreateFilter: true));
            _createDefaultFilter(field);
          },
        );
      },
    );
  }

  List<FieldInfo> _filterFields(
    final List<FieldInfo> fields,
    final String filterText,
  ) {
    final List<FieldInfo> allFields = List.from(fields);
    final keyword = filterText.toLowerCase();
    allFields.retainWhere((final field) {
      if (!field.canCreateFilter) {
        return false;
      }

      if (filterText.isNotEmpty) {
        return field.name.toLowerCase().contains(keyword);
      }

      return true;
    });

    return allFields;
  }

  void _startListening() {
    _onFieldFn = (final fields) {
      fields.retainWhere((final field) => field.canCreateFilter);
      add(GridCreateFilterEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onReceiveFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultFilter(final FieldInfo field) async {
    final fieldId = field.id;
    switch (field.fieldType) {
      case FieldType.Checkbox:
        return _filterBackendSvc.insertCheckboxFilter(
          fieldId: fieldId,
          condition: CheckboxFilterConditionPB.IsChecked,
        );
      case FieldType.DateTime:
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return _filterBackendSvc.insertDateFilter(
          fieldId: fieldId,
          condition: DateFilterConditionPB.DateIs,
          timestamp: timestamp,
        );
      case FieldType.MultiSelect:
        return _filterBackendSvc.insertSelectOptionFilter(
          fieldId: fieldId,
          condition: SelectOptionConditionPB.OptionIs,
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
          content: "",
        );
      case FieldType.RichText:
        return _filterBackendSvc.insertTextFilter(
          fieldId: fieldId,
          condition: TextFilterConditionPB.Contains,
          content: '',
        );
      case FieldType.SingleSelect:
        return _filterBackendSvc.insertSelectOptionFilter(
          fieldId: fieldId,
          condition: SelectOptionConditionPB.OptionIs,
          fieldType: FieldType.SingleSelect,
        );
      case FieldType.URL:
        return _filterBackendSvc.insertURLFilter(
          fieldId: fieldId,
          condition: TextFilterConditionPB.Contains,
        );
    }

    return left(unit);
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
class GridCreateFilterEvent with _$GridCreateFilterEvent {
  const factory GridCreateFilterEvent.initial() = _Initial;
  const factory GridCreateFilterEvent.didReceiveFields(final List<FieldInfo> fields) =
      _DidReceiveFields;

  const factory GridCreateFilterEvent.createDefaultFilter(final FieldInfo field) =
      _CreateDefaultFilter;

  const factory GridCreateFilterEvent.didReceiveFilterText(final String text) =
      _DidReceiveFilterText;
}

@freezed
class GridCreateFilterState with _$GridCreateFilterState {
  const factory GridCreateFilterState({
    required final String filterText,
    required final List<FieldInfo> creatableFields,
    required final List<FieldInfo> allFields,
    required final bool didCreateFilter,
  }) = _GridFilterState;

  factory GridCreateFilterState.initial(final List<FieldInfo> fields) {
    return GridCreateFilterState(
      filterText: "",
      creatableFields: getCreatableFilter(fields),
      allFields: fields,
      didCreateFilter: false,
    );
  }
}

List<FieldInfo> getCreatableFilter(final List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((final element) => element.canCreateFilter);
  return creatableFields;
}
