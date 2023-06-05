import 'package:appflowy/plugins/database_view/application/filter/filter_listener.dart';
import 'package:appflowy/plugins/database_view/application/filter/filter_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/util.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'checkbox_filter_editor_bloc.freezed.dart';

class CheckboxFilterEditorBloc
    extends Bloc<CheckboxFilterEditorEvent, CheckboxFilterEditorState> {
  final FilterInfo filterInfo;
  final FilterBackendService _filterBackendSvc;
  final FilterListener _listener;

  CheckboxFilterEditorBloc({required this.filterInfo})
      : _filterBackendSvc = FilterBackendService(viewId: filterInfo.viewId),
        _listener = FilterListener(
          viewId: filterInfo.viewId,
          filterId: filterInfo.filter.id,
        ),
        super(CheckboxFilterEditorState.initial(filterInfo)) {
    on<CheckboxFilterEditorEvent>(
      (final event, final emit) async {
        event.when(
          initial: () async {
            _startListening();
          },
          updateCondition: (final CheckboxFilterConditionPB condition) {
            _filterBackendSvc.insertCheckboxFilter(
              filterId: filterInfo.filter.id,
              fieldId: filterInfo.fieldInfo.id,
              condition: condition,
            );
          },
          delete: () {
            _filterBackendSvc.deleteFilter(
              fieldId: filterInfo.fieldInfo.id,
              filterId: filterInfo.filter.id,
              fieldType: filterInfo.fieldInfo.fieldType,
            );
          },
          didReceiveFilter: (final FilterPB filter) {
            final filterInfo = state.filterInfo.copyWith(filter: filter);
            final checkboxFilter = filterInfo.checkboxFilter()!;
            emit(
              state.copyWith(
                filterInfo: filterInfo,
                filter: checkboxFilter,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _listener.start(
      onDeleted: () {
        if (!isClosed) add(const CheckboxFilterEditorEvent.delete());
      },
      onUpdated: (final filter) {
        if (!isClosed) add(CheckboxFilterEditorEvent.didReceiveFilter(filter));
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class CheckboxFilterEditorEvent with _$CheckboxFilterEditorEvent {
  const factory CheckboxFilterEditorEvent.initial() = _Initial;
  const factory CheckboxFilterEditorEvent.didReceiveFilter(final FilterPB filter) =
      _DidReceiveFilter;
  const factory CheckboxFilterEditorEvent.updateCondition(
    final CheckboxFilterConditionPB condition,
  ) = _UpdateCondition;
  const factory CheckboxFilterEditorEvent.delete() = _Delete;
}

@freezed
class CheckboxFilterEditorState with _$CheckboxFilterEditorState {
  const factory CheckboxFilterEditorState({
    required final FilterInfo filterInfo,
    required final CheckboxFilterPB filter,
  }) = _GridFilterState;

  factory CheckboxFilterEditorState.initial(final FilterInfo filterInfo) {
    return CheckboxFilterEditorState(
      filterInfo: filterInfo,
      filter: filterInfo.checkboxFilter()!,
    );
  }
}
