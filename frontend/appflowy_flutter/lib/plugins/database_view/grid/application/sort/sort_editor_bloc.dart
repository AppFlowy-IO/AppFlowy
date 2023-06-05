import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/sort/sort_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pbenum.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pbserver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'util.dart';

part 'sort_editor_bloc.freezed.dart';

class SortEditorBloc extends Bloc<SortEditorEvent, SortEditorState> {
  final String viewId;
  final SortBackendService _sortBackendSvc;
  final FieldController fieldController;
  void Function(List<FieldInfo>)? _onFieldFn;
  SortEditorBloc({
    required this.viewId,
    required this.fieldController,
    required final List<SortInfo> sortInfos,
  })  : _sortBackendSvc = SortBackendService(viewId: viewId),
        super(SortEditorState.initial(sortInfos, fieldController.fieldInfos)) {
    on<SortEditorEvent>(
      (final event, final emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          didReceiveFields: (final List<FieldInfo> fields) {
            final List<FieldInfo> allFields = List.from(fields);
            final List<FieldInfo> creatableFields = List.from(fields);
            creatableFields.retainWhere((final field) => field.canCreateSort);
            emit(
              state.copyWith(
                allFields: allFields,
                creatableFields: creatableFields,
              ),
            );
          },
          setCondition: (final SortInfo sortInfo, final SortConditionPB condition) async {
            final result = await _sortBackendSvc.updateSort(
              fieldId: sortInfo.fieldInfo.id,
              sortId: sortInfo.sortId,
              fieldType: sortInfo.fieldInfo.fieldType,
              condition: condition,
            );
            result.fold((final l) => {}, (final err) => Log.error(err));
          },
          deleteAllSorts: () async {
            final result = await _sortBackendSvc.deleteAllSorts();
            result.fold((final l) => {}, (final err) => Log.error(err));
          },
          didReceiveSorts: (final List<SortInfo> sortInfos) {
            emit(state.copyWith(sortInfos: sortInfos));
          },
          deleteSort: (final SortInfo sortInfo) async {
            final result = await _sortBackendSvc.deleteSort(
              fieldId: sortInfo.fieldInfo.id,
              sortId: sortInfo.sortId,
              fieldType: sortInfo.fieldInfo.fieldType,
            );
            result.fold((final l) => null, (final err) => Log.error(err));
          },
        );
      },
    );
  }

  void _startListening() {
    _onFieldFn = (final fields) {
      add(SortEditorEvent.didReceiveFields(List.from(fields)));
    };

    fieldController.addListener(
      listenWhen: () => !isClosed,
      onReceiveFields: _onFieldFn,
      onSorts: (final sorts) {
        add(SortEditorEvent.didReceiveSorts(sorts));
      },
    );
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
  const factory SortEditorEvent.didReceiveFields(final List<FieldInfo> fieldInfos) =
      _DidReceiveFields;
  const factory SortEditorEvent.didReceiveSorts(final List<SortInfo> sortInfos) =
      _DidReceiveSorts;
  const factory SortEditorEvent.setCondition(
    final SortInfo sortInfo,
    final SortConditionPB condition,
  ) = _SetCondition;
  const factory SortEditorEvent.deleteSort(final SortInfo sortInfo) = _DeleteSort;
  const factory SortEditorEvent.deleteAllSorts() = _DeleteAllSorts;
}

@freezed
class SortEditorState with _$SortEditorState {
  const factory SortEditorState({
    required final List<SortInfo> sortInfos,
    required final List<FieldInfo> creatableFields,
    required final List<FieldInfo> allFields,
  }) = _SortEditorState;

  factory SortEditorState.initial(
    final List<SortInfo> sortInfos,
    final List<FieldInfo> fields,
  ) {
    return SortEditorState(
      creatableFields: getCreatableSorts(fields),
      allFields: fields,
      sortInfos: sortInfos,
    );
  }
}
