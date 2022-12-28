import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checklist_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'sort_service.dart';

part 'sort_create_bloc.freezed.dart';

class CreateSortBloc extends Bloc<CreateSortEvent, CreateSortState> {
  final String viewId;
  final SortFFIService _ffiService;
  final GridFieldController fieldController;
  void Function(List<FieldInfo>)? _onFieldFn;
  CreateSortBloc({required this.viewId, required this.fieldController})
      : _ffiService = SortFFIService(viewId: viewId),
        super(CreateSortState.initial(fieldController.fieldInfos)) {
    on<CreateSortEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (List<FieldInfo> fields) {
            emit(
              state.copyWith(
                allFields: fields,
                creatableFields: _filterFields(fields, state.filterText),
              ),
            );
          },
          didReceiveFilterText: (String text) {
            emit(
              state.copyWith(
                filterText: text,
                creatableFields: _filterFields(state.allFields, text),
              ),
            );
          },
          createDefaultFilter: (FieldInfo field) {
            emit(state.copyWith(didCreateFilter: true));
            _createDefaultFilter(field);
          },
        );
      },
    );
  }

  List<FieldInfo> _filterFields(
    List<FieldInfo> fields,
    String filterText,
  ) {
    final List<FieldInfo> allFields = List.from(fields);
    final keyword = filterText.toLowerCase();
    allFields.retainWhere((field) {
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
    _onFieldFn = (fields) {
      fields.retainWhere((field) => field.canCreateFilter);
      add(CreateSortEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultFilter(FieldInfo field) async {
    final fieldId = field.id;
    switch (field.fieldType) {
      // case FieldType.Checkbox:
      //   return _ffiService.insertCheckboxFilter(
      //     fieldId: fieldId,
      //     condition: CheckboxFilterConditionPB.IsChecked,
      //   );
      // case FieldType.DateTime:
      //   final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      //   return _ffiService.insertDateFilter(
      //     fieldId: fieldId,
      //     condition: DateFilterConditionPB.DateIs,
      //     timestamp: timestamp,
      //   );
      // case FieldType.MultiSelect:
      //   return _ffiService.insertSelectOptionFilter(
      //     fieldId: fieldId,
      //     condition: SelectOptionConditionPB.OptionIs,
      //     fieldType: FieldType.MultiSelect,
      //   );
      // case FieldType.Checklist:
      //   return _ffiService.insertChecklistFilter(
      //     fieldId: fieldId,
      //     condition: ChecklistFilterConditionPB.IsIncomplete,
      //   );
      // case FieldType.Number:
      //   return _ffiService.insertNumberFilter(
      //     fieldId: fieldId,
      //     condition: NumberFilterConditionPB.Equal,
      //     content: "",
      //   );
      // case FieldType.RichText:
      //   return _ffiService.insertTextFilter(
      //     fieldId: fieldId,
      //     condition: TextFilterConditionPB.Contains,
      //     content: '',
      //   );
      // case FieldType.SingleSelect:
      //   return _ffiService.insertSelectOptionFilter(
      //     fieldId: fieldId,
      //     condition: SelectOptionConditionPB.OptionIs,
      //     fieldType: FieldType.SingleSelect,
      //   );
      // case FieldType.URL:
      //   return _ffiService.insertURLFilter(
      //     fieldId: fieldId,
      //     condition: TextFilterConditionPB.Contains,
      //   );
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
class CreateSortEvent with _$CreateSortEvent {
  const factory CreateSortEvent.initial() = _Initial;
  const factory CreateSortEvent.didReceiveFields(List<FieldInfo> fields) =
      _DidReceiveFields;

  const factory CreateSortEvent.createDefaultFilter(FieldInfo field) =
      _CreateDefaultFilter;

  const factory CreateSortEvent.didReceiveFilterText(String text) =
      _DidReceiveFilterText;
}

@freezed
class CreateSortState with _$CreateSortState {
  const factory CreateSortState({
    required String filterText,
    required List<FieldInfo> creatableFields,
    required List<FieldInfo> allFields,
    required bool didCreateFilter,
  }) = _CreateSortState;

  factory CreateSortState.initial(List<FieldInfo> fields) {
    return CreateSortState(
      filterText: "",
      creatableFields: getCreatableFilter(fields),
      allFields: fields,
      didCreateFilter: false,
    );
  }
}

List<FieldInfo> getCreatableFilter(List<FieldInfo> fieldInfos) {
  final List<FieldInfo> creatableFields = List.from(fieldInfos);
  creatableFields.retainWhere((element) => element.canCreateFilter);
  return creatableFields;
}
