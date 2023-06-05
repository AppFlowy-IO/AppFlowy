import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/field/field_controller.dart';
import '../../../application/sort/sort_service.dart';
import 'util.dart';

part 'sort_create_bloc.freezed.dart';

class CreateSortBloc extends Bloc<CreateSortEvent, CreateSortState> {
  final String viewId;
  final SortBackendService _sortBackendSvc;
  final FieldController fieldController;
  void Function(List<FieldInfo>)? _onFieldFn;
  CreateSortBloc({required this.viewId, required this.fieldController})
      : _sortBackendSvc = SortBackendService(viewId: viewId),
        super(CreateSortState.initial(fieldController.fieldInfos)) {
    on<CreateSortEvent>(
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
          createDefaultSort: (final FieldInfo field) {
            emit(state.copyWith(didCreateSort: true));
            _createDefaultSort(field);
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
    _onFieldFn = (final fields) {
      fields.retainWhere((final field) => field.canCreateSort);
      add(CreateSortEvent.didReceiveFields(fields));
    };
    fieldController.addListener(onReceiveFields: _onFieldFn);
  }

  Future<Either<Unit, FlowyError>> _createDefaultSort(final FieldInfo field) async {
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
  const factory CreateSortEvent.didReceiveFields(final List<FieldInfo> fields) =
      _DidReceiveFields;

  const factory CreateSortEvent.createDefaultSort(final FieldInfo field) =
      _CreateDefaultSort;

  const factory CreateSortEvent.didReceiveFilterText(final String text) =
      _DidReceiveFilterText;
}

@freezed
class CreateSortState with _$CreateSortState {
  const factory CreateSortState({
    required final String filterText,
    required final List<FieldInfo> creatableFields,
    required final List<FieldInfo> allFields,
    required final bool didCreateSort,
  }) = _CreateSortState;

  factory CreateSortState.initial(final List<FieldInfo> fields) {
    return CreateSortState(
      filterText: "",
      creatableFields: getCreatableSorts(fields),
      allFields: fields,
      didCreateSort: false,
    );
  }
}
