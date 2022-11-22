import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'filter_service.dart';

part 'filter_create_bloc.freezed.dart';

class GridCreateFilterBloc
    extends Bloc<GridCreateFilterEvent, GridCreateFilterState> {
  final String viewId;
  final FilterFFIService _ffiService;
  final GridFieldController fieldController;
  void Function(List<GridFieldInfo>)? _onFieldFn;
  GridCreateFilterBloc({required this.viewId, required this.fieldController})
      : _ffiService = FilterFFIService(viewId: viewId),
        super(GridCreateFilterState.initial(fieldController.fieldInfos)) {
    on<GridCreateFilterEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (List<GridFieldInfo> fields) {
            emit(
              state.copyWith(
                allFields: fields,
                displaiedFields: _filterFields(fields, state.filterText),
              ),
            );
          },
          didReceiveFilterText: (String text) {
            emit(
              state.copyWith(
                filterText: text,
                displaiedFields: _filterFields(state.allFields, text),
              ),
            );
          },
          createDefaultFilter: (GridFieldInfo field) async {
            await _createDefaultFilter(field);
          },
        );
      },
    );
  }

  List<GridFieldInfo> _filterFields(
    List<GridFieldInfo> fields,
    String filterText,
  ) {
    final List<GridFieldInfo> allFields = List.from(fields);
    final keyword = filterText.toLowerCase();
    allFields.retainWhere((field) {
      if (field.hasFilter) {
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
      fields.retainWhere((field) => field.hasFilter == false);
      add(GridCreateFilterEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultFilter(
      GridFieldInfo field) async {
    final fieldId = field.id;
    switch (field.fieldType) {
      case FieldType.Checkbox:
        return _ffiService.insertCheckboxFilter(
          fieldId: fieldId,
          condition: CheckboxFilterCondition.IsChecked,
        );
      case FieldType.DateTime:
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return _ffiService.insertDateFilter(
          fieldId: fieldId,
          condition: DateFilterCondition.DateIs,
          timestamp: timestamp,
        );
      case FieldType.MultiSelect:
        return _ffiService.insertSingleSelectFilter(
          fieldId: fieldId,
          condition: SelectOptionCondition.OptionIs,
        );
      case FieldType.Number:
        return _ffiService.insertNumberFilter(
          fieldId: fieldId,
          condition: NumberFilterCondition.Equal,
          content: "",
        );
      case FieldType.RichText:
        return _ffiService.insertTextFilter(
          fieldId: fieldId,
          condition: TextFilterCondition.Contains,
        );
      case FieldType.SingleSelect:
        return _ffiService.insertSingleSelectFilter(
          fieldId: fieldId,
          condition: SelectOptionCondition.OptionIs,
        );
      case FieldType.URL:
        return _ffiService.insertURLFilter(
          fieldId: fieldId,
          condition: TextFilterCondition.Contains,
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

  const factory GridCreateFilterEvent.didReceiveFields(
      List<GridFieldInfo> fields) = _DidReceiveFields;

  const factory GridCreateFilterEvent.createDefaultFilter(GridFieldInfo field) =
      _CreateDefaultFilter;

  const factory GridCreateFilterEvent.didReceiveFilterText(String text) =
      _DidReceiveFilterText;
}

@freezed
class GridCreateFilterState with _$GridCreateFilterState {
  const factory GridCreateFilterState({
    required String filterText,
    required List<GridFieldInfo> displaiedFields,
    required List<GridFieldInfo> allFields,
  }) = _GridFilterState;

  factory GridCreateFilterState.initial(List<GridFieldInfo> fields) {
    fields.retainWhere((element) => !element.hasFilter);
    return GridCreateFilterState(
      filterText: "",
      displaiedFields: fields,
      allFields: fields,
    );
  }
}
