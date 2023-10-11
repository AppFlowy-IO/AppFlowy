import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/field/field_controller.dart';
import '../../../application/sort/sort_service.dart';

part 'sort_create_bloc.freezed.dart';

class CreateSortBloc extends Bloc<CreateSortEvent, CreateSortState> {
  final String viewId;
  final SortBackendService _sortBackendSvc;
  final FieldController fieldController;
  void Function(List<FieldPB>)? _onFieldFn;
  CreateSortBloc({required this.viewId, required this.fieldController})
      : _sortBackendSvc = SortBackendService(viewId: viewId),
        super(CreateSortState.initial(fieldController.fields)) {
    on<CreateSortEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (List<FieldPB> fields) {
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
          createDefaultSort: (FieldPB field) {
            emit(state.copyWith(didCreateSort: true));
            _createDefaultSort(field);
          },
        );
      },
    );
  }

  List<FieldPB> _filterFields(
    List<FieldPB> fields,
    String filterText,
  ) {
    final List<FieldPB> allFields = List.from(fields);
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
    fieldController.addListener(onReceiveFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultSort(FieldPB field) async {
    final result = await _sortBackendSvc.insertSort(
      fieldId: field.id,
      fieldType: field.fieldType,
      condition: SortConditionPB.Ascending,
    );

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
  const factory CreateSortEvent.didReceiveFields(List<FieldPB> fields) =
      _DidReceiveFields;

  const factory CreateSortEvent.createDefaultSort(FieldPB field) =
      _CreateDefaultSort;

  const factory CreateSortEvent.didReceiveFilterText(String text) =
      _DidReceiveFilterText;
}

@freezed
class CreateSortState with _$CreateSortState {
  const factory CreateSortState({
    required String filterText,
    required List<FieldPB> creatableFields,
    required List<FieldPB> allFields,
    required bool didCreateSort,
  }) = _CreateSortState;

  factory CreateSortState.initial(List<FieldPB> fields) {
    fields.retainWhere((field) => field.canCreateSort);
    return CreateSortState(
      filterText: "",
      creatableFields: fields,
      allFields: fields,
      didCreateSort: false,
    );
  }
}
