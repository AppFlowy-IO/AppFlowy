import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'sort_service.dart';
import 'util.dart';

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
          createDefaultSort: (FieldInfo field) {
            emit(state.copyWith(didCreateSort: true));
            _createDefaultSort(field);
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
      if (!field.canCreateSort) {
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
      fields.retainWhere((field) => field.canCreateSort);
      add(CreateSortEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultSort(FieldInfo field) async {
    final result = await _ffiService.insertSort(
        fieldId: field.id,
        fieldType: field.fieldType,
        condition: GridSortConditionPB.Ascending);

    return result;
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

  const factory CreateSortEvent.createDefaultSort(FieldInfo field) =
      _CreateDefaultSort;

  const factory CreateSortEvent.didReceiveFilterText(String text) =
      _DidReceiveFilterText;
}

@freezed
class CreateSortState with _$CreateSortState {
  const factory CreateSortState({
    required String filterText,
    required List<FieldInfo> creatableFields,
    required List<FieldInfo> allFields,
    required bool didCreateSort,
  }) = _CreateSortState;

  factory CreateSortState.initial(List<FieldInfo> fields) {
    return CreateSortState(
      filterText: "",
      creatableFields: getCreatableSorts(fields),
      allFields: fields,
      didCreateSort: false,
    );
  }
}
